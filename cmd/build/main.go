// build compiles every manifest in <apps-dir> into a single index.json
// suitable for the cliff client to fetch. The output schema matches the
// catalog the client deserializes; see internal/index for the wire types.
//
// Stars and last-commit timestamps are snapshotted from the GitHub REST
// API at build time using the GITHUB_TOKEN environment variable. If the
// token is missing or a request fails, the affected fields are left
// zero/empty and the build continues — registry availability is more
// important than perfect metadata.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/jmcntsh/cliff-registry/internal/index"
	"github.com/jmcntsh/cliff-registry/internal/manifest"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: build <apps-dir> <out.json>")
		os.Exit(2)
	}
	appsDir, outPath := os.Args[1], os.Args[2]

	loaded, err := manifest.LoadDir(appsDir)
	if err != nil {
		die("load: %v", err)
	}

	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		fmt.Fprintln(os.Stderr, "warn: GITHUB_TOKEN not set; stars and last_commit will be empty")
	}
	gh := &ghClient{token: token, http: &http.Client{Timeout: 10 * time.Second}}

	var (
		apps    []index.App
		fails   int
		catSeen = map[string]int{}
	)
	for _, l := range loaded {
		if err := l.Manifest.Validate(); err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", l.Path, err)
			fails++
			continue
		}
		app := l.Manifest.ToApp()

		if app.Repo != "" && strings.Count(app.Repo, "/") == 1 {
			if stars, last, err := gh.snapshot(app.Repo); err != nil {
				fmt.Fprintf(os.Stderr, "warn: snapshot %s: %v\n", app.Repo, err)
			} else {
				app.Stars = stars
				if !last.IsZero() {
					app.LastCommitISO = last.UTC().Format(time.RFC3339)
				}
			}
		}

		apps = append(apps, app)
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

	cat := index.Catalog{
		SchemaVersion: index.SchemaVersion,
		GeneratedAt:   time.Now().UTC(),
		SourceCommit:  os.Getenv("GITHUB_SHA"),
		Apps:          apps,
		Categories:    cats,
	}
	if cat.SourceCommit == "" {
		cat.SourceCommit = "registry@local"
	}

	buf, err := json.MarshalIndent(cat, "", "  ")
	if err != nil {
		die("marshal: %v", err)
	}
	buf = append(buf, '\n')
	if err := os.WriteFile(outPath, buf, 0o644); err != nil {
		die("write %s: %v", outPath, err)
	}

	fmt.Printf("wrote %s (%d apps, %d categories)\n", outPath, len(apps), len(cats))
}

func die(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

type ghClient struct {
	token string
	http  *http.Client
}

func (c *ghClient) snapshot(repo string) (stars int, lastCommit time.Time, err error) {
	type repoResp struct {
		StargazersCount int    `json:"stargazers_count"`
		PushedAt        string `json:"pushed_at"`
	}
	var r repoResp
	if err := c.get("/repos/"+repo, &r); err != nil {
		return 0, time.Time{}, err
	}
	var t time.Time
	if r.PushedAt != "" {
		if parsed, perr := time.Parse(time.RFC3339, r.PushedAt); perr == nil {
			t = parsed
		}
	}
	return r.StargazersCount, t, nil
}

func (c *ghClient) get(path string, out any) error {
	req, err := http.NewRequest("GET", "https://api.github.com"+path, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		snip := string(body)
		if len(snip) > 200 {
			snip = snip[:200]
		}
		return fmt.Errorf("github %s: %d %s", path, resp.StatusCode, snip)
	}
	return json.Unmarshal(body, out)
}
