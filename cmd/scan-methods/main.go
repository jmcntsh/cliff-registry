// Command scan-methods surveys the registry for manifests whose apps
// probably support install methods beyond what's currently declared,
// and prints a report of candidates for the author to review.
//
// It does NOT modify manifests. The output is intentionally paste-ready
// markdown so a human can evaluate each suggestion (false positives
// happen — especially from README snippets that mention unrelated
// tools). Apply the changes by hand, then re-run lint to verify.
//
// Signals consulted, per app:
//
//   - Homebrew formula presence via https://formulae.brew.sh/api — a
//     200 means the package exists and is installable via `brew install
//     <name>` on any Homebrew-equipped machine.
//   - README scan for install-instruction patterns. Regexes use word
//     boundaries so `cargo install` doesn't spuriously match `go
//     install` (the bug that poisoned an earlier ad-hoc pass). Each
//     candidate's detected type is sanity-checked against the app's
//     declared language — we don't report `go install` on a Rust
//     project even if the regex matches, because the toolchain
//     wouldn't actually produce a binary from that source.
//
// Usage:
//
//	scan-methods apps            # scan every manifest in apps/
//	scan-methods apps/foo.toml   # or a single file
//
// Runs fetches concurrently (bounded). Intended for periodic
// housekeeping — run quarterly or before a curation sweep, not on
// every commit.
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/jmcntsh/cliff-registry/internal/manifest"
)

// compatibleMethods lists which install types make sense for each
// language. Prevents the regex false-positive of suggesting `go
// install` on a Rust project because its README has a "see our Go
// companion tool" note, or `cargo install` on a Python project that
// mentions Rust as an optional dep. When a language isn't in the map,
// all types are allowed.
var compatibleMethods = map[string]map[string]bool{
	"Rust":       {"cargo": true, "brew": true, "script": true},
	"Go":         {"go": true, "brew": true, "script": true},
	"Python":     {"pipx": true, "brew": true, "script": true},
	"TypeScript": {"npm": true, "brew": true, "script": true},
	"JavaScript": {"npm": true, "brew": true, "script": true},
	"C":          {"brew": true, "script": true},
	"C++":        {"brew": true, "script": true},
	"Zig":        {"brew": true, "script": true},
}

var (
	// \b on the tool name is load-bearing: without it, `cargo install`
	// matches as `go install` and `pipx install` matches as `pip
	// install` inside `pipx install foo`. The package name regex
	// captures a single whitespace-delimited token; callers that need
	// the full line (to spot multi-package `cargo install A B` cases)
	// can use the source line we record alongside.
	reBrew   = regexp.MustCompile(`\bbrew install\s+([a-zA-Z0-9_./:-]+)`)
	reCargo  = regexp.MustCompile(`\bcargo install\s+(?:--[a-z-]+\s+)*([a-zA-Z0-9_-]+)`)
	reGo     = regexp.MustCompile(`\bgo install\s+([a-zA-Z0-9_./:@-]+)`)
	rePipx   = regexp.MustCompile(`\bpipx install\s+([a-zA-Z0-9_-]+)`)
	reNpm    = regexp.MustCompile(`\bnpm install\s+(-g\s+)?([a-zA-Z0-9_@/-]+)`)
	reScript = regexp.MustCompile(`curl\s+[^\n|]*\|\s*(?:sh|bash)\b`)
)

type hit struct {
	Type    string // brew | cargo | go | pipx | npm | script
	Package string // or full curl-pipe command for script
	Source  string // "formulae.brew.sh" or "README"
}

type result struct {
	Name     string
	Author   string
	Language string
	Current  []string
	Adds     []hit
	Notes    []string
}

func main() {
	args := os.Args[1:]
	if len(args) != 1 {
		fmt.Fprintln(os.Stderr, "usage: scan-methods <apps-dir-or-file>")
		os.Exit(2)
	}
	target := args[0]

	loaded, err := loadTargets(target)
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}

	client := &http.Client{Timeout: 15 * time.Second}
	sem := make(chan struct{}, 8) // bound parallel fetches
	results := make([]result, len(loaded))
	var wg sync.WaitGroup
	for i, l := range loaded {
		wg.Add(1)
		go func(i int, m manifest.Manifest) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			results[i] = scan(client, m)
		}(i, l.Manifest)
	}
	wg.Wait()

	printReport(results)
}

func loadTargets(target string) ([]manifest.Loaded, error) {
	info, err := os.Stat(target)
	if err != nil {
		return nil, err
	}
	if info.IsDir() {
		return manifest.LoadDir(target)
	}
	// Single file — wrap in LoadDir-compatible shape by pointing at its parent
	// and filtering. Easier: load the parent dir, keep only the matching file.
	all, err := manifest.LoadDir(parentOf(target))
	if err != nil {
		return nil, err
	}
	var out []manifest.Loaded
	for _, l := range all {
		if sameFile(l.Path, target) {
			out = append(out, l)
		}
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("no manifest found at %s", target)
	}
	return out, nil
}

func parentOf(path string) string {
	if i := strings.LastIndex(path, "/"); i >= 0 {
		return path[:i]
	}
	return "."
}

func sameFile(a, b string) bool {
	ai, err := os.Stat(a)
	if err != nil {
		return false
	}
	bi, err := os.Stat(b)
	if err != nil {
		return false
	}
	return os.SameFile(ai, bi)
}

func scan(client *http.Client, m manifest.Manifest) result {
	r := result{
		Name:     m.Name,
		Author:   m.Author,
		Language: m.Language,
	}
	current := map[string]bool{}
	for _, method := range m.Methods() {
		current[method.Type] = true
		r.Current = append(r.Current, method.Type)
	}
	sort.Strings(r.Current)

	// Signal A: brew formula presence.
	if !current["brew"] && isLangCompatible(m.Language, "brew") {
		if checkBrew(client, m.Name) {
			r.Adds = append(r.Adds, hit{Type: "brew", Package: m.Name, Source: "formulae.brew.sh"})
		}
	}

	// Signal B: README scan.
	if m.Readme != "" {
		body, err := fetch(client, m.Readme)
		if err != nil {
			r.Notes = append(r.Notes, fmt.Sprintf("README fetch failed: %v", err))
		} else {
			r.Adds = append(r.Adds, scanReadme(body, current, m.Language)...)
		}
	}

	r.Adds = dedup(r.Adds)
	return r
}

// isLangCompatible reports whether a candidate install type makes sense
// given the project's language. Unknown languages permit all types.
func isLangCompatible(lang, typ string) bool {
	allowed, ok := compatibleMethods[lang]
	if !ok {
		return true
	}
	return allowed[typ]
}

func checkBrew(client *http.Client, name string) bool {
	resp, err := client.Get("https://formulae.brew.sh/api/formula/" + name + ".json")
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)
	return resp.StatusCode == 200
}

func fetch(client *http.Client, url string) (string, error) {
	resp, err := client.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return "", fmt.Errorf("http %d", resp.StatusCode)
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 2<<20)) // 2 MiB cap
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func scanReadme(body string, current map[string]bool, lang string) []hit {
	var hits []hit

	consider := func(typ, pkg string) {
		if current[typ] || pkg == "" {
			return
		}
		if !isLangCompatible(lang, typ) {
			return
		}
		hits = append(hits, hit{Type: typ, Package: pkg, Source: "README"})
	}

	for _, m := range reBrew.FindAllStringSubmatch(body, -1) {
		consider("brew", m[1])
	}
	for _, m := range reCargo.FindAllStringSubmatch(body, -1) {
		consider("cargo", m[1])
	}
	for _, m := range reGo.FindAllStringSubmatch(body, -1) {
		consider("go", m[1])
	}
	for _, m := range rePipx.FindAllStringSubmatch(body, -1) {
		consider("pipx", m[1])
	}
	for _, m := range reNpm.FindAllStringSubmatch(body, -1) {
		consider("npm", m[2])
	}
	if !current["script"] && isLangCompatible(lang, "script") {
		if m := reScript.FindString(body); m != "" {
			// Script installer detected but not emitted as an "add"
			// candidate by default: script installs require an
			// [uninstall] block per lint, and auto-suggesting them
			// tends to sweep in unrelated `curl ... | sh` mentions
			// (rustup, uv, etc.). Record as a note so the human
			// can follow up if the installer belongs to this app.
			// Keeping this as a note rather than a hit is the lazy-
			// planning move (see CLAUDE.md): defer the complexity
			// until someone confirms it's worth it.
			hits = append(hits, hit{Type: "script-hint", Package: strings.TrimSpace(m), Source: "README"})
		}
	}
	return hits
}

func dedup(hits []hit) []hit {
	seen := map[string]bool{}
	var out []hit
	for _, h := range hits {
		key := h.Type + "\x00" + h.Package
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, h)
	}
	return out
}

func printReport(results []result) {
	sort.Slice(results, func(i, j int) bool { return results[i].Name < results[j].Name })

	var withAdds []result
	for _, r := range results {
		if len(r.Adds) > 0 {
			withAdds = append(withAdds, r)
		}
	}
	if len(withAdds) == 0 {
		fmt.Println("No multi-method candidates found. (Every manifest already covers what its README documents.)")
		printNotes(results)
		return
	}

	fmt.Printf("# scan-methods report — %d candidate app(s)\n\n", len(withAdds))
	for _, r := range withAdds {
		fmt.Printf("## %s (%s/%s, currently: %s, language: %s)\n\n",
			r.Name, r.Author, r.Name, strings.Join(r.Current, "+"), orDash(r.Language))
		for _, h := range r.Adds {
			if h.Type == "script-hint" {
				fmt.Printf("- (hint) %s — script installer detected in README; if it belongs to this app, adding it requires an explicit `[uninstall]` block (see notes/manifest.md).\n", h.Package)
				continue
			}
			fmt.Printf("- **%s**: `%s`   [%s]\n", h.Type, h.Package, h.Source)
		}
		for _, n := range r.Notes {
			fmt.Printf("- note: %s\n", n)
		}
		fmt.Println()
	}

	fmt.Println("## Summary")
	fmt.Println()
	counts := map[string]int{}
	for _, r := range withAdds {
		for _, h := range r.Adds {
			counts[h.Type]++
		}
	}
	var types []string
	for t := range counts {
		types = append(types, t)
	}
	sort.Strings(types)
	fmt.Printf("- %d apps with candidates\n", len(withAdds))
	for _, t := range types {
		fmt.Printf("- %d × %s\n", counts[t], t)
	}
	printNotes(results)
}

func printNotes(results []result) {
	var noisy []result
	for _, r := range results {
		if len(r.Notes) > 0 {
			noisy = append(noisy, r)
		}
	}
	if len(noisy) == 0 {
		return
	}
	fmt.Println()
	fmt.Println("## Fetch notes")
	fmt.Println()
	for _, r := range noisy {
		fmt.Printf("- %s: %s\n", r.Name, strings.Join(r.Notes, "; "))
	}
}

func orDash(s string) string {
	if s == "" {
		return "—"
	}
	return s
}
