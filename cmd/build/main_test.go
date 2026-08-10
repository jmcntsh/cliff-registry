package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jmcntsh/cliff-registry/internal/index"
	"github.com/jmcntsh/cliff-registry/internal/stars"
)

func TestBuildGeneratesGrowthIndexFromFixtureHistory(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/repos/acme/tool" && r.URL.Path != "/repos/acme/tool-alias" {
			t.Errorf("GitHub fixture path = %q", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"id": 101,
			"full_name": "acme/tool",
			"stargazers_count": 15,
			"pushed_at": "2026-08-09T12:00:00Z"
		}`))
	}))
	defer server.Close()

	root := t.TempDir()
	appsDir := filepath.Join(root, "apps")
	historyDir := filepath.Join(root, "history")
	if err := os.MkdirAll(appsDir, 0o755); err != nil {
		t.Fatal(err)
	}
	manifest := `name = "tool"
description = "fixture terminal tool"
author = "acme"
homepage = "https://github.com/acme/tool"
readme = "https://raw.githubusercontent.com/acme/tool/main/README.md"
tags = ["cli"]
license = "MIT"
category = "Other"
language = "Go"

[install]
type = "go"
package = "github.com/acme/tool@latest"
`
	if err := os.WriteFile(filepath.Join(appsDir, "tool.toml"), []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	aliasManifest := strings.Replace(manifest, `name = "tool"`, `name = "tool-alias"`, 1)
	aliasManifest = strings.ReplaceAll(aliasManifest, "acme/tool", "acme/tool-alias")
	if err := os.WriteFile(filepath.Join(appsDir, "tool-alias.toml"), []byte(aliasManifest), 0o644); err != nil {
		t.Fatal(err)
	}
	baseline := stars.NewSnapshot(time.Now().UTC().Add(-48*time.Hour), "baseline", []stars.Observation{{
		ID: 101, Repo: "acme/tool", Stars: 10,
	}})
	if err := stars.Write(filepath.Join(historyDir, "baseline.json"), baseline); err != nil {
		t.Fatal(err)
	}

	outPath := filepath.Join(root, "index.json")
	snapshotPath := filepath.Join(root, "current.json")
	cmd := exec.Command("go", "run", ".",
		"-history", historyDir,
		"-snapshot", snapshotPath,
		appsDir, outPath,
	)
	cmd.Env = append(os.Environ(),
		"GITHUB_API_URL="+server.URL,
		"GITHUB_TOKEN=fixture",
		"GITHUB_SHA=fixture-source",
	)
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("build failed: %v\n%s", err, output)
	}

	body, err := os.ReadFile(outPath)
	if err != nil {
		t.Fatal(err)
	}
	var catalog index.Catalog
	if err := json.Unmarshal(body, &catalog); err != nil {
		t.Fatal(err)
	}
	if catalog.SchemaVersion != 2 || catalog.SourceCommit != "fixture-source" {
		t.Fatalf("catalog metadata = schema %d source %q", catalog.SchemaVersion, catalog.SourceCommit)
	}
	window := catalog.StarWindows["7d"]
	if window.From == nil || window.To == nil || window.Complete {
		t.Fatalf("fixture should produce an available partial 7d window: %+v", window)
	}
	if len(catalog.Apps) != 2 {
		t.Fatalf("fixture growth not published: %+v", catalog.Apps)
	}
	for _, app := range catalog.Apps {
		if app.StarGrowth["7d"] != 5 {
			t.Fatalf("fixture growth not published for %s: %+v", app.Name, app.StarGrowth)
		}
	}
	snapshot, err := stars.Load(snapshotPath)
	if err != nil {
		t.Fatalf("generated snapshot invalid: %v", err)
	}
	if len(snapshot.Repositories) != 1 {
		t.Fatalf("duplicate GitHub repository id was not collapsed: %+v", snapshot.Repositories)
	}
}
