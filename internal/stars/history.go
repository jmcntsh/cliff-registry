// Package stars records GitHub repository star-count observations and
// calculates fixed-window net growth without collecting user telemetry.
package stars

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const SnapshotSchemaVersion = 1

type Observation struct {
	ID       int64      `json:"id"`
	Repo     string     `json:"repo"`
	Stars    int        `json:"stars"`
	PushedAt *time.Time `json:"pushed_at,omitempty"`
	ETag     string     `json:"etag,omitempty"`
}

type Snapshot struct {
	SchemaVersion int           `json:"schema_version"`
	CapturedAt    time.Time     `json:"captured_at"`
	SourceCommit  string        `json:"source_commit,omitempty"`
	Repositories  []Observation `json:"repositories"`
}

type WindowSpec struct {
	Key  string
	Days int
}

type WindowResult struct {
	RequestedDays int
	From          *time.Time
	To            *time.Time
	Complete      bool
	Deltas        map[int64]int
}

func NewSnapshot(capturedAt time.Time, sourceCommit string, observations []Observation) Snapshot {
	return normalizeSnapshot(Snapshot{
		SchemaVersion: SnapshotSchemaVersion,
		CapturedAt:    capturedAt.UTC(),
		SourceCommit:  sourceCommit,
		Repositories:  append([]Observation(nil), observations...),
	})
}

func (s Snapshot) Validate() error {
	if s.SchemaVersion != SnapshotSchemaVersion {
		return fmt.Errorf("snapshot schema_version %d, want %d", s.SchemaVersion, SnapshotSchemaVersion)
	}
	if s.CapturedAt.IsZero() {
		return errors.New("snapshot captured_at is required")
	}
	seen := make(map[int64]struct{}, len(s.Repositories))
	for _, observation := range s.Repositories {
		switch {
		case observation.ID <= 0:
			return fmt.Errorf("repository %q has invalid id %d", observation.Repo, observation.ID)
		case strings.TrimSpace(observation.Repo) == "":
			return fmt.Errorf("repository id %d has an empty repo", observation.ID)
		case observation.Stars < 0:
			return fmt.Errorf("repository %q has negative stars", observation.Repo)
		}
		if _, ok := seen[observation.ID]; ok {
			return fmt.Errorf("duplicate repository id %d", observation.ID)
		}
		seen[observation.ID] = struct{}{}
	}
	return nil
}

func Write(path string, snapshot Snapshot) error {
	snapshot = normalizeSnapshot(snapshot)
	if err := snapshot.Validate(); err != nil {
		return err
	}
	body, err := json.MarshalIndent(snapshot, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal snapshot: %w", err)
	}
	body = append(body, '\n')
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("create snapshot directory: %w", err)
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".stars-*.json")
	if err != nil {
		return fmt.Errorf("create temporary snapshot: %w", err)
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName)
	if _, err := tmp.Write(body); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("write temporary snapshot: %w", err)
	}
	if err := tmp.Chmod(0o644); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("chmod temporary snapshot: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("close temporary snapshot: %w", err)
	}
	if err := os.Rename(tmpName, path); err != nil {
		return fmt.Errorf("replace snapshot: %w", err)
	}
	return nil
}

func Load(path string) (Snapshot, error) {
	body, err := os.ReadFile(path)
	if err != nil {
		return Snapshot{}, err
	}
	var snapshot Snapshot
	if err := json.Unmarshal(body, &snapshot); err != nil {
		return Snapshot{}, fmt.Errorf("parse %s: %w", path, err)
	}
	snapshot = normalizeSnapshot(snapshot)
	if err := snapshot.Validate(); err != nil {
		return Snapshot{}, fmt.Errorf("%s: %w", path, err)
	}
	return snapshot, nil
}

func LoadDir(dir string) ([]Snapshot, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, nil
	}
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var snapshots []Snapshot
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		snapshot, err := Load(filepath.Join(dir, entry.Name()))
		if err != nil {
			return nil, err
		}
		snapshots = append(snapshots, snapshot)
	}
	sort.Slice(snapshots, func(i, j int) bool {
		if snapshots[i].CapturedAt.Equal(snapshots[j].CapturedAt) {
			return snapshots[i].SourceCommit < snapshots[j].SourceCommit
		}
		return snapshots[i].CapturedAt.Before(snapshots[j].CapturedAt)
	})
	return snapshots, nil
}

// LatestByRepo returns the newest successful observation for an exact
// owner/name pair. It is used only as lifetime-metadata fallback when the
// current GitHub request fails; growth still requires a current observation.
func LatestByRepo(history []Snapshot, repo string) (Observation, bool) {
	for i := len(history) - 1; i >= 0; i-- {
		for _, observation := range history[i].Repositories {
			if strings.EqualFold(observation.Repo, repo) {
				return observation, true
			}
		}
	}
	return Observation{}, false
}

// CalculateWindows chooses the oldest baseline at or after each requested
// cutoff. This maximizes coverage without silently measuring a longer period.
// During initial collection that baseline naturally yields a shorter,
// explicitly partial window.
func CalculateWindows(current Snapshot, history []Snapshot, specs []WindowSpec) map[string]WindowResult {
	results := make(map[string]WindowResult, len(specs))
	currentByID := observationsByID(current.Repositories)
	for _, spec := range specs {
		result := WindowResult{
			RequestedDays: spec.Days,
			Deltas:        map[int64]int{},
		}
		if spec.Key == "" || spec.Days <= 0 {
			results[spec.Key] = result
			continue
		}
		cutoff := current.CapturedAt.Add(-time.Duration(spec.Days) * 24 * time.Hour)
		baseline, deltas, ok := selectBaseline(history, cutoff, current.CapturedAt, currentByID)
		if !ok {
			results[spec.Key] = result
			continue
		}
		result.Deltas = deltas
		from, to := baseline.CapturedAt.UTC(), current.CapturedAt.UTC()
		result.From = &from
		result.To = &to
		result.Complete = sameUTCDate(from, cutoff)
		results[spec.Key] = result
	}
	return results
}

func selectBaseline(history []Snapshot, cutoff, current time.Time, currentByID map[int64]Observation) (Snapshot, map[int64]int, bool) {
	var selected Snapshot
	var selectedDeltas map[int64]int
	found := false
	for _, snapshot := range history {
		if !snapshot.CapturedAt.Before(current) || snapshot.CapturedAt.Before(cutoff) {
			continue
		}
		deltas := make(map[int64]int)
		for id, before := range observationsByID(snapshot.Repositories) {
			after, ok := currentByID[id]
			if ok {
				deltas[id] = after.Stars - before.Stars
			}
		}
		if len(deltas) == 0 {
			continue
		}
		if found && !snapshot.CapturedAt.Before(selected.CapturedAt) {
			continue
		}
		selected = snapshot
		selectedDeltas = deltas
		found = true
	}
	return selected, selectedDeltas, found
}

func observationsByID(observations []Observation) map[int64]Observation {
	out := make(map[int64]Observation, len(observations))
	for _, observation := range observations {
		out[observation.ID] = observation
	}
	return out
}

func sameUTCDate(a, b time.Time) bool {
	ay, am, ad := a.UTC().Date()
	by, bm, bd := b.UTC().Date()
	return ay == by && am == bm && ad == bd
}

func normalizeSnapshot(snapshot Snapshot) Snapshot {
	snapshot.CapturedAt = snapshot.CapturedAt.UTC()
	snapshot.Repositories = append([]Observation(nil), snapshot.Repositories...)
	for i := range snapshot.Repositories {
		snapshot.Repositories[i].Repo = strings.TrimSpace(snapshot.Repositories[i].Repo)
		if snapshot.Repositories[i].PushedAt != nil {
			pushed := snapshot.Repositories[i].PushedAt.UTC()
			snapshot.Repositories[i].PushedAt = &pushed
		}
	}
	sort.Slice(snapshot.Repositories, func(i, j int) bool {
		if snapshot.Repositories[i].ID != snapshot.Repositories[j].ID {
			return snapshot.Repositories[i].ID < snapshot.Repositories[j].ID
		}
		return snapshot.Repositories[i].Repo < snapshot.Repositories[j].Repo
	})
	return snapshot
}
