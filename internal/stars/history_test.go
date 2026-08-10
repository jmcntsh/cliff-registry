package stars

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func at(day int) time.Time {
	return time.Date(2026, 8, day, 4, 0, 0, 0, time.UTC)
}

func observation(id int64, repo string, count int) Observation {
	return Observation{ID: id, Repo: repo, Stars: count}
}

func TestWriteIsDeterministicAndSorted(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "2026-08-10.json")
	pushed := at(9)
	snapshot := NewSnapshot(at(10), "abc123", []Observation{
		{ID: 20, Repo: "z/repo", Stars: 2},
		{ID: 10, Repo: "a/repo", Stars: 1, PushedAt: &pushed},
	})
	if err := Write(path, snapshot); err != nil {
		t.Fatalf("first write: %v", err)
	}
	first, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := Write(path, snapshot); err != nil {
		t.Fatalf("second write: %v", err)
	}
	second, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(first) != string(second) {
		t.Fatal("same snapshot produced different bytes")
	}
	if strings.Index(string(first), `"id": 10`) > strings.Index(string(first), `"id": 20`) {
		t.Fatal("snapshot repositories are not sorted by stable id")
	}
}

func TestLoadRejectsUnknownSchema(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bad.json")
	body := `{"schema_version":2,"captured_at":"2026-08-10T04:00:00Z","repositories":[]}`
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := Load(path); err == nil || !strings.Contains(err.Error(), "schema_version") {
		t.Fatalf("Load error = %v, want schema error", err)
	}
}

func TestLoadDirSortsSnapshotsByCaptureTime(t *testing.T) {
	dir := t.TempDir()
	for name, snapshot := range map[string]Snapshot{
		"later.json": NewSnapshot(at(10), "later", nil),
		"early.json": NewSnapshot(at(8), "early", nil),
	} {
		if err := Write(filepath.Join(dir, name), snapshot); err != nil {
			t.Fatal(err)
		}
	}
	history, err := LoadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(history) != 2 || history[0].SourceCommit != "early" || history[1].SourceCommit != "later" {
		t.Fatalf("history not chronologically sorted: %+v", history)
	}
}

func TestCalculateWindowsCompletePartialAndStableIDRename(t *testing.T) {
	history := []Snapshot{
		NewSnapshot(time.Date(2026, 7, 20, 4, 0, 0, 0, time.UTC), "oldest", []Observation{
			observation(1, "old-owner/tool", 70),
			observation(2, "b/flat", 45),
			observation(3, "c/down", 30),
		}),
		NewSnapshot(at(3), "weekly", []Observation{
			observation(1, "old-owner/tool", 100),
			observation(2, "b/flat", 50),
			observation(3, "c/down", 25),
			observation(4, "d/missing-current", 5),
		}),
	}
	current := NewSnapshot(at(10), "current", []Observation{
		observation(1, "new-owner/tool", 130),
		observation(2, "b/flat", 50),
		observation(3, "c/down", 20),
		observation(5, "e/new", 100),
	})

	got := CalculateWindows(current, history, []WindowSpec{
		{Key: "7d", Days: 7},
		{Key: "30d", Days: 30},
	})
	week := got["7d"]
	if week.From == nil || week.To == nil || !week.Complete {
		t.Fatalf("weekly window should be complete: %+v", week)
	}
	if week.Deltas[1] != 30 {
		t.Errorf("renamed repository delta = %d, want 30", week.Deltas[1])
	}
	if delta, ok := week.Deltas[2]; !ok || delta != 0 {
		t.Errorf("measured zero delta = %d, present=%v; want present zero", delta, ok)
	}
	if week.Deltas[3] != -5 {
		t.Errorf("negative delta = %d, want -5", week.Deltas[3])
	}
	if _, ok := week.Deltas[4]; ok {
		t.Error("missing current observation must not produce a delta")
	}
	if _, ok := week.Deltas[5]; ok {
		t.Error("missing baseline observation must not produce a delta")
	}

	month := got["30d"]
	if month.From == nil || month.To == nil || month.Complete {
		t.Fatalf("30d warm-up window should be available but partial: %+v", month)
	}
	if !month.From.Equal(time.Date(2026, 7, 20, 4, 0, 0, 0, time.UTC)) {
		t.Fatalf("30d baseline = %v, want Jul 20", month.From)
	}
	if month.Deltas[1] != 60 {
		t.Errorf("partial monthly delta = %d, want 60", month.Deltas[1])
	}
}

func TestCalculateWindowsUnavailableWithoutUsableSecondSnapshot(t *testing.T) {
	current := NewSnapshot(at(10), "current", []Observation{observation(1, "a/one", 10)})
	specs := []WindowSpec{{Key: "7d", Days: 7}}

	if got := CalculateWindows(current, nil, specs)["7d"]; got.From != nil || got.To != nil {
		t.Fatalf("first snapshot should be unavailable: %+v", got)
	}
	tooOld := NewSnapshot(at(1), "too-old", []Observation{observation(1, "a/one", 1)})
	if got := CalculateWindows(current, []Snapshot{tooOld}, specs)["7d"]; got.From != nil {
		t.Fatalf("baseline outside requested period must not be used: %+v", got)
	}
	noOverlap := NewSnapshot(at(8), "different", []Observation{observation(2, "b/two", 2)})
	if got := CalculateWindows(current, []Snapshot{noOverlap}, specs)["7d"]; got.From != nil {
		t.Fatalf("window without overlapping observations must be unavailable: %+v", got)
	}
	laterUsable := NewSnapshot(at(9), "usable", []Observation{observation(1, "a/one", 8)})
	got := CalculateWindows(current, []Snapshot{noOverlap, laterUsable}, specs)["7d"]
	if got.From == nil || !got.From.Equal(at(9)) || got.Deltas[1] != 2 {
		t.Fatalf("unusable early snapshot should be skipped: %+v", got)
	}
}

func TestLatestByRepoReturnsLastSuccessfulMetadata(t *testing.T) {
	older := NewSnapshot(at(8), "older", []Observation{observation(1, "a/tool", 4)})
	newer := NewSnapshot(at(9), "newer", []Observation{observation(1, "A/Tool", 7)})
	got, ok := LatestByRepo([]Snapshot{older, newer}, "a/tool")
	if !ok || got.Stars != 7 {
		t.Fatalf("LatestByRepo = %+v, %v; want 7 stars", got, ok)
	}
}
