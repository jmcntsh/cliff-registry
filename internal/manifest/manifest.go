// Package manifest defines the on-disk TOML schema for cliff registry
// entries and the validation rules. Both cmd/lint and cmd/build consume
// this package; the client never does (it reads the compiled index.json
// instead).
package manifest

import (
	"fmt"
	"net/url"
	"regexp"
	"strings"

	"github.com/jmcntsh/cliff-registry/internal/index"
)

type Manifest struct {
	Name        string   `toml:"name"`
	Description string   `toml:"description"`
	Author      string   `toml:"author"`
	Homepage    string   `toml:"homepage"`
	Readme      string   `toml:"readme,omitempty"`
	Demo        string   `toml:"demo,omitempty"`
	Screenshots []string `toml:"screenshots,omitempty"`
	Tags        []string `toml:"tags,omitempty"`
	License     string   `toml:"license,omitempty"`
	Category    string   `toml:"category,omitempty"`
	Language    string   `toml:"language,omitempty"`
	// Binary overrides the installed executable name when it doesn't
	// match the repo basename (e.g. cli/cli → gh). Optional; the client
	// falls back to repo basename when empty.
	Binary string `toml:"binary,omitempty"`

	// A manifest declares exactly one of [install] or [[installs]].
	// [install] is the single-method form, kept for the common case
	// where an app ships through one package manager. [[installs]] is
	// the multi-method array-of-tables form, used when the same app is
	// available through more than one manager (e.g. brew and cargo);
	// the client picks the first entry whose tool is on the user's
	// machine, or accepts an explicit `--via <type>` override. BurntSushi/
	// toml can't unify [install] and [[install]] on the same key
	// (they're syntactically distinct in TOML), so we use two names.
	Install   *Install   `toml:"install,omitempty"`
	Installs  []Install  `toml:"installs,omitempty"`
	Uninstall *BareBlock `toml:"uninstall,omitempty"`
	Upgrade   *BareBlock `toml:"upgrade,omitempty"`
}

type Install struct {
	Type    string `toml:"type"`
	Package string `toml:"package,omitempty"`
	Command string `toml:"command,omitempty"`
	Global  bool   `toml:"global,omitempty"`
}

// Methods returns the normalized list of install methods — always a
// slice, drawn from whichever of [install] or [[installs]] the
// manifest author used. Callers should use this rather than touching
// Install / Installs directly.
func (m *Manifest) Methods() []Install {
	if len(m.Installs) > 0 {
		return m.Installs
	}
	if m.Install != nil {
		return []Install{*m.Install}
	}
	return nil
}

// BareBlock is the shape of the optional [uninstall] and [upgrade]
// tables: a single command. Required for [uninstall] when
// install.type=="script" (no general reverse exists); optional
// otherwise, where presence overrides the derived command.
type BareBlock struct {
	Command string `toml:"command"`
}

var (
	nameRE     = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*$`)
	validTypes = map[string]bool{
		"brew": true, "cargo": true, "npm": true,
		"pipx": true, "go": true, "script": true,
	}
)

const MaxDescriptionLen = 120

func (m *Manifest) Validate() error {
	var errs []string

	if m.Name == "" {
		errs = append(errs, "name is required")
	} else if !nameRE.MatchString(m.Name) {
		errs = append(errs, fmt.Sprintf("name %q must match [a-z0-9][a-z0-9-]*", m.Name))
	}

	if m.Description == "" {
		errs = append(errs, "description is required")
	} else if len(m.Description) > MaxDescriptionLen {
		errs = append(errs, fmt.Sprintf("description is %d chars (max %d)", len(m.Description), MaxDescriptionLen))
	}

	if m.Author == "" {
		errs = append(errs, "author is required")
	}

	if err := requireURL("homepage", m.Homepage, true); err != nil {
		errs = append(errs, err.Error())
	}
	if err := requireURL("readme", m.Readme, false); err != nil {
		errs = append(errs, err.Error())
	}
	if err := requireURL("demo", m.Demo, false); err != nil {
		errs = append(errs, err.Error())
	}
	for i, s := range m.Screenshots {
		if err := requireURL(fmt.Sprintf("screenshots[%d]", i), s, true); err != nil {
			errs = append(errs, err.Error())
		}
	}

	switch {
	case m.Install != nil && len(m.Installs) > 0:
		errs = append(errs, "manifest must use exactly one of [install] (single-method) or [[installs]] (multi-method), not both")
	case m.Install == nil && len(m.Installs) == 0:
		errs = append(errs, "install method is required — use [install] for a single method or [[installs]] for multiple")
	}

	methods := m.Methods()
	sawScript := false
	seenTypes := make(map[string]bool, len(methods))
	for i, in := range methods {
		prefix := "install"
		if len(m.Installs) > 0 {
			prefix = fmt.Sprintf("installs[%d]", i)
		}
		if in.Type == "" {
			errs = append(errs, fmt.Sprintf("%s.type is required", prefix))
			continue
		}
		if !validTypes[in.Type] {
			errs = append(errs, fmt.Sprintf("%s.type %q is not one of brew|cargo|npm|pipx|go|script", prefix, in.Type))
			continue
		}
		if seenTypes[in.Type] {
			errs = append(errs, fmt.Sprintf("%s.type %q appears more than once in [[installs]] — each method type must be unique", prefix, in.Type))
		}
		seenTypes[in.Type] = true
		if in.Type == "script" {
			sawScript = true
			if in.Command == "" {
				errs = append(errs, fmt.Sprintf("%s.command is required when type=\"script\"", prefix))
			}
			if in.Package != "" {
				errs = append(errs, fmt.Sprintf("%s.package must be empty when type=\"script\"", prefix))
			}
		} else {
			if in.Package == "" {
				errs = append(errs, fmt.Sprintf("%s.package is required when type=%q", prefix, in.Type))
			}
			if in.Command != "" {
				errs = append(errs, fmt.Sprintf("%s.command is only valid when type=\"script\"", prefix))
			}
			if in.Global && in.Type != "npm" {
				errs = append(errs, fmt.Sprintf("%s.global only applies to type=\"npm\"", prefix))
			}
		}
	}
	if sawScript && m.Uninstall == nil {
		errs = append(errs, "[uninstall] is required when any install method has type=\"script\" — no general reverse exists for script installs")
	}

	if m.Uninstall != nil && m.Uninstall.Command == "" {
		errs = append(errs, "uninstall.command must be non-empty when [uninstall] is present")
	}
	if m.Upgrade != nil && m.Upgrade.Command == "" {
		errs = append(errs, "upgrade.command must be non-empty when [upgrade] is present")
	}

	for i, t := range m.Tags {
		if t != strings.ToLower(t) {
			errs = append(errs, fmt.Sprintf("tags[%d] %q must be lowercase", i, t))
		}
	}

	if len(errs) == 0 {
		return nil
	}
	return fmt.Errorf("%s", strings.Join(errs, "; "))
}

func requireURL(field, raw string, required bool) error {
	if raw == "" {
		if required {
			return fmt.Errorf("%s is required", field)
		}
		return nil
	}
	u, err := url.Parse(raw)
	if err != nil {
		return fmt.Errorf("%s: %v", field, err)
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("%s: scheme must be http or https (got %q)", field, u.Scheme)
	}
	if u.Host == "" {
		return fmt.Errorf("%s: missing host", field)
	}
	return nil
}

// ToApp converts a validated manifest into the index.App shape that the
// client consumes. Stars and last-commit are filled in by cmd/build from
// a snapshot taken at index-build time.
func (m *Manifest) ToApp() index.App {
	repo := m.Author + "/" + m.Name
	if u, err := url.Parse(m.Homepage); err == nil && u.Host == "github.com" {
		trimmed := strings.Trim(u.Path, "/")
		if trimmed != "" {
			repo = trimmed
		}
	}

	methods := m.Methods()
	specs := make([]index.InstallSpec, len(methods))
	for i, in := range methods {
		specs[i] = index.InstallSpec{
			Type:    in.Type,
			Package: in.Package,
			Command: in.Command,
			Global:  in.Global,
		}
	}

	app := index.App{
		Name:         m.Name,
		Repo:         repo,
		Description:  m.Description,
		Category:     fallback(m.Category, "Other"),
		Language:     m.Language,
		License:      m.License,
		Homepage:     m.Homepage,
		Author:       m.Author,
		Readme:       m.Readme,
		Demo:         m.Demo,
		Screenshots:  m.Screenshots,
		Tags:         m.Tags,
		Binary:       m.Binary,
		InstallSpecs: specs,
	}
	if m.Uninstall != nil {
		app.UninstallSpec = &index.CommandSpec{Command: m.Uninstall.Command}
	}
	if m.Upgrade != nil {
		app.UpgradeSpec = &index.CommandSpec{Command: m.Upgrade.Command}
	}
	return app
}

func fallback(s, def string) string {
	if s == "" {
		return def
	}
	return s
}
