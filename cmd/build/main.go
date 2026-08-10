// build compiles every manifest in <apps-dir> into a single index.json
// suitable for the cliff client to fetch. The output schema matches the
// catalog the client deserializes; see internal/index for the wire types.
//
// Stars and last-commit timestamps are snapshotted from the GitHub REST
// API at build time using the GITHUB_TOKEN environment variable. Optional
// history/snapshot paths produce static net-growth metadata. Failed requests
// reuse prior lifetime metadata when available but never produce a period
// delta; registry availability remains more important than perfect metadata.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/jmcntsh/cliff-registry/internal/index"
	"github.com/jmcntsh/cliff-registry/internal/manifest"
	"github.com/jmcntsh/cliff-registry/internal/stars"
)

func main() {
	var historyDir, snapshotPath string
	flag.StringVar(&historyDir, "history", "", "directory of prior star snapshots")
	flag.StringVar(&snapshotPath, "snapshot", "", "path for the current star snapshot")
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "usage: build [-history dir] [-snapshot file] <apps-dir> <out.json>")
		flag.PrintDefaults()
	}
	flag.Parse()
	if flag.NArg() != 2 {
		flag.Usage()
		os.Exit(2)
	}
	appsDir, outPath := flag.Arg(0), flag.Arg(1)

	loaded, err := manifest.LoadDir(appsDir)
	if err != nil {
		die("load: %v", err)
	}
	history, err := stars.LoadDir(historyDir)
	if err != nil {
		die("load star history: %v", err)
	}

	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		fmt.Fprintln(os.Stderr, "warn: GITHUB_TOKEN not set; GitHub requests may be rate limited")
	}
	gh := stars.Client{Token: token, BaseURL: os.Getenv("GITHUB_API_URL")}
	capturedAt := time.Now().UTC()
	sourceCommit := os.Getenv("GITHUB_SHA")
	if sourceCommit == "" {
		sourceCommit = "registry@local"
	}

	var (
		apps             []index.App
		appObservation   []int64
		observationsByID = map[int64]stars.Observation{}
		fails            int
		metadataMissing  int
		catSeen          = map[string]int{}
	)
	for _, l := range loaded {
		if err := l.Manifest.Validate(); err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", l.Path, err)
			fails++
			continue
		}
		app := l.Manifest.ToApp()

		if added, err := gitAddedAt(l.Path); err != nil {
			fmt.Fprintf(os.Stderr, "warn: added_at %s: %v\n", l.Path, err)
		} else if !added.IsZero() {
			app.AddedAtISO = added.UTC().Format(time.RFC3339)
		}

		var observationID int64
		if app.Repo != "" && strings.Count(app.Repo, "/") == 1 {
			previous, hasPrevious := stars.LatestByRepo(history, app.Repo)
			var previousPtr *stars.Observation
			if hasPrevious {
				previousPtr = &previous
			}
			observation, err := gh.Fetch(context.Background(), app.Repo, previousPtr)
			if err != nil {
				fmt.Fprintf(os.Stderr, "warn: snapshot %s: %v\n", app.Repo, err)
				metadataMissing++
				if hasPrevious {
					app.Stars = previous.Stars
					if previous.PushedAt != nil {
						app.LastCommitISO = previous.PushedAt.UTC().Format(time.RFC3339)
					}
				}
			} else {
				app.Stars = observation.Stars
				if observation.PushedAt != nil {
					app.LastCommitISO = observation.PushedAt.UTC().Format(time.RFC3339)
				}
				observationID = observation.ID
				observationsByID[observation.ID] = observation
			}
		}

		apps = append(apps, app)
		appObservation = append(appObservation, observationID)
		catSeen[app.Category]++
	}
	if fails > 0 {
		die("%d manifest(s) failed validation; refusing to build index", fails)
	}

	cats := make([]index.Category, 0, len(catSeen))
	for name, n := range catSeen {
		cats = append(cats, index.Category{Name: name, Count: n})
	}
	sort.Slice(cats, func(i, j int) bool { return cats[i].Name < cats[j].Name })

	observations := make([]stars.Observation, 0, len(observationsByID))
	for _, observation := range observationsByID {
		observations = append(observations, observation)
	}
	current := stars.NewSnapshot(capturedAt, sourceCommit, observations)
	if snapshotPath != "" {
		if err := stars.Write(snapshotPath, current); err != nil {
			die("write star snapshot: %v", err)
		}
	}
	windowResults := stars.CalculateWindows(current, history, []stars.WindowSpec{
		{Key: "7d", Days: 7},
		{Key: "30d", Days: 30},
	})
	starWindows := make(map[string]index.StarWindow, len(windowResults))
	for key, result := range windowResults {
		starWindows[key] = index.StarWindow{
			RequestedDays: result.RequestedDays,
			From:          result.From,
			To:            result.To,
			Complete:      result.Complete,
		}
	}
	for i := range apps {
		id := appObservation[i]
		if id == 0 {
			continue
		}
		for key, result := range windowResults {
			delta, ok := result.Deltas[id]
			if !ok {
				continue
			}
			if apps[i].StarGrowth == nil {
				apps[i].StarGrowth = map[string]int{}
			}
			apps[i].StarGrowth[key] = delta
		}
	}

	cat := index.Catalog{
		SchemaVersion: index.SchemaVersion,
		GeneratedAt:   capturedAt,
		SourceCommit:  sourceCommit,
		Apps:          apps,
		Categories:    cats,
		StarWindows:   starWindows,
	}

	buf, err := json.MarshalIndent(cat, "", "  ")
	if err != nil {
		die("marshal: %v", err)
	}
	buf = append(buf, '\n')
	if err := os.WriteFile(outPath, buf, 0o644); err != nil {
		die("write %s: %v", outPath, err)
	}

	fmt.Printf("wrote %s (%d apps, %d categories, %d observed, %d missing)\n",
		outPath, len(apps), len(cats), len(observations), metadataMissing)
}

func die(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

// gitAddedAt returns the author-date of the commit that first added
// the manifest at path, following file renames. Runs `git log` inside
// the manifest's directory so the command works from any cwd. A zero
// time (no error) means the file is present but not tracked, which can
// happen for pending local edits; the build continues with empty
// added_at in that case. Requires a non-shallow checkout to return
// correct values for manifests added before the clone's depth — CI
// must set fetch-depth: 0 on actions/checkout.
func gitAddedAt(path string) (time.Time, error) {
	abs, err := filepath.Abs(path)
	if err != nil {
		return time.Time{}, err
	}
	cmd := exec.Command(
		"git", "log",
		"--diff-filter=A", "--follow",
		"--format=%aI", "--max-count=1",
		"--", filepath.Base(abs),
	)
	cmd.Dir = filepath.Dir(abs)
	out, err := cmd.Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return time.Time{}, fmt.Errorf("git log: %s", strings.TrimSpace(string(ee.Stderr)))
		}
		return time.Time{}, err
	}
	raw := strings.TrimSpace(string(out))
	if raw == "" {
		return time.Time{}, nil
	}
	t, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return time.Time{}, fmt.Errorf("parse %q: %w", raw, err)
	}
	return t, nil
}
