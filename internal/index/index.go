// Package index defines the wire shape of registry.cliff.sh/index.json.
//
// This is a deliberate copy of the subset of github.com/jmcntsh/cliff's
// internal/catalog types that the client deserializes. Keeping a copy
// here means the registry repo has no dependency on the binary repo;
// the schema is enforced by SchemaVersion and the client's tests.
package index

import "time"

const SchemaVersion = 1

type Catalog struct {
	SchemaVersion int        `json:"schema_version"`
	GeneratedAt   time.Time  `json:"generated_at"`
	SourceCommit  string     `json:"source_commit"`
	Apps          []App      `json:"apps"`
	Categories    []Category `json:"categories"`
}

type App struct {
	Name        string `json:"name"`
	Repo        string `json:"repo"`
	Description string `json:"description"`
	Category    string `json:"category"`
	Language    string `json:"language"`
	License     string `json:"license"`
	Stars       int    `json:"stars"`
	Homepage    string `json:"homepage"`

	Author        string       `json:"author,omitempty"`
	Readme        string       `json:"readme,omitempty"`
	Demo          string       `json:"demo,omitempty"`
	Screenshots   []string     `json:"screenshots,omitempty"`
	Tags          []string     `json:"tags,omitempty"`
	Binary        string       `json:"binary,omitempty"`
	InstallSpec   *InstallSpec `json:"install_spec,omitempty"`
	UninstallSpec *CommandSpec `json:"uninstall_spec,omitempty"`
	UpgradeSpec   *CommandSpec `json:"upgrade_spec,omitempty"`
	LastCommitISO string       `json:"last_commit,omitempty"`
}

type InstallSpec struct {
	Type    string `json:"type"`
	Package string `json:"package,omitempty"`
	Command string `json:"command,omitempty"`
	Global  bool   `json:"global,omitempty"`
}

// CommandSpec is the wire shape for the [uninstall] and [upgrade]
// manifest blocks: just a shell command. Kept separate from InstallSpec
// because these blocks are structurally simpler — no type switch and no
// package/global fields. Must stay in sync with the mirrored type in
// github.com/jmcntsh/cliff's internal/catalog package.
type CommandSpec struct {
	Command string `json:"command"`
}

func (s *InstallSpec) Shell() string {
	if s == nil {
		return ""
	}
	switch s.Type {
	case "brew":
		return "brew install " + s.Package
	case "cargo":
		return "cargo install " + s.Package
	case "npm":
		if s.Global {
			return "npm install -g " + s.Package
		}
		return "npm install " + s.Package
	case "pipx":
		return "pipx install " + s.Package
	case "go":
		return "go install " + s.Package
	case "script":
		return s.Command
	}
	return ""
}

type Category struct {
	Name  string `json:"name"`
	Count int    `json:"count"`
}
