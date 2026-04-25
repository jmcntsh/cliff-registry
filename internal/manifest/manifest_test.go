package manifest

import (
	"strings"
	"testing"
)

func validBase() Manifest {
	return Manifest{
		Name:        "lazygit",
		Description: "Simple terminal UI for git commands",
		Author:      "jesseduffield",
		Homepage:    "https://github.com/jesseduffield/lazygit",
		Install:     &Install{Type: "brew", Package: "lazygit"},
	}
}

func TestValidate_OK(t *testing.T) {
	m := validBase()
	if err := m.Validate(); err != nil {
		t.Fatalf("expected ok, got: %v", err)
	}
}

func TestValidate_RequiredFields(t *testing.T) {
	cases := map[string]func(*Manifest){
		"name":              func(m *Manifest) { m.Name = "" },
		"description":       func(m *Manifest) { m.Description = "" },
		"author":            func(m *Manifest) { m.Author = "" },
		"homepage":          func(m *Manifest) { m.Homepage = "" },
		"install.type":      func(m *Manifest) { m.Install.Type = "" },
		"install.package":   func(m *Manifest) { m.Install.Package = "" },
		"bad name":          func(m *Manifest) { m.Name = "Lazy_Git" },
		"bad install type":  func(m *Manifest) { m.Install.Type = "snap" },
		"bad homepage":      func(m *Manifest) { m.Homepage = "not-a-url" },
		"description too long": func(m *Manifest) {
			m.Description = ""
			for i := 0; i < MaxDescriptionLen+1; i++ {
				m.Description += "x"
			}
		},
		"uppercase tag": func(m *Manifest) { m.Tags = []string{"Git"} },
		"global on non-npm": func(m *Manifest) {
			m.Install = &Install{Type: "brew", Package: "x", Global: true}
		},
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			m := validBase()
			mutate(&m)
			if err := m.Validate(); err == nil {
				t.Fatal("expected error, got nil")
			}
		})
	}
}

func TestValidate_Script(t *testing.T) {
	m := validBase()
	m.Install = &Install{Type: "script", Command: "curl -fsSL https://x.io/i.sh | sh"}
	m.Uninstall = &BareBlock{Command: "rm -f /usr/local/bin/x"}
	if err := m.Validate(); err != nil {
		t.Fatalf("script ok case: %v", err)
	}
	m.Install.Package = "x"
	if err := m.Validate(); err == nil {
		t.Fatal("expected error when both command and package set on script")
	}
}

func TestValidate_ScriptRequiresUninstall(t *testing.T) {
	m := validBase()
	m.Install = &Install{Type: "script", Command: "curl -fsSL https://x.io/i.sh | sh"}
	// Deliberately no Uninstall block.
	err := m.Validate()
	if err == nil {
		t.Fatal("expected error: script without [uninstall]")
	}
	if !strings.Contains(err.Error(), "[uninstall] is required") {
		t.Errorf("error should mention [uninstall] requirement, got: %v", err)
	}
}

func TestValidate_EmptyBareBlockCommandRejected(t *testing.T) {
	cases := map[string]func(*Manifest){
		"empty uninstall.command": func(m *Manifest) {
			m.Uninstall = &BareBlock{Command: ""}
		},
		"empty upgrade.command": func(m *Manifest) {
			m.Upgrade = &BareBlock{Command: ""}
		},
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			m := validBase()
			mutate(&m)
			if err := m.Validate(); err == nil {
				t.Fatal("expected error, got nil")
			}
		})
	}
}

func TestValidate_UpgradeOptionalForScript(t *testing.T) {
	m := validBase()
	m.Install = &Install{Type: "script", Command: "curl -fsSL https://x.io/i.sh | sh"}
	m.Uninstall = &BareBlock{Command: "rm -f /usr/local/bin/x"}
	// No Upgrade block — should still validate.
	if err := m.Validate(); err != nil {
		t.Fatalf("script with uninstall but no upgrade should be ok: %v", err)
	}
}

func TestToApp_PassesThroughNewBlocks(t *testing.T) {
	m := validBase()
	m.Binary = "gh"
	m.Uninstall = &BareBlock{Command: "brew uninstall --force gh"}
	m.Upgrade = &BareBlock{Command: "brew upgrade gh"}
	app := m.ToApp()
	if app.Binary != "gh" {
		t.Errorf("binary pass-through: got %q", app.Binary)
	}
	if app.UninstallSpec == nil || app.UninstallSpec.Command != "brew uninstall --force gh" {
		t.Errorf("uninstall pass-through: got %+v", app.UninstallSpec)
	}
	if app.UpgradeSpec == nil || app.UpgradeSpec.Command != "brew upgrade gh" {
		t.Errorf("upgrade pass-through: got %+v", app.UpgradeSpec)
	}
}

func TestToApp(t *testing.T) {
	m := validBase()
	app := m.ToApp()
	if app.Repo != "jesseduffield/lazygit" {
		t.Errorf("repo = %q, want jesseduffield/lazygit", app.Repo)
	}
	if len(app.InstallSpecs) != 1 || app.InstallSpecs[0].Shell() != "brew install lazygit" {
		t.Errorf("install specs wrong: %+v", app.InstallSpecs)
	}
}

// Multi-method ([[installs]]) test suite below.

func TestValidate_MultiMethod_OK(t *testing.T) {
	m := validBase()
	m.Install = nil
	m.Installs = []Install{
		{Type: "brew", Package: "chess-tui"},
		{Type: "cargo", Package: "chess-tui"},
	}
	if err := m.Validate(); err != nil {
		t.Fatalf("expected ok, got: %v", err)
	}
}

func TestValidate_BothInstallAndInstallsRejected(t *testing.T) {
	m := validBase()
	// m.Install already set from validBase; add an [[installs]] too.
	m.Installs = []Install{{Type: "cargo", Package: "lazygit"}}
	err := m.Validate()
	if err == nil {
		t.Fatal("expected error: cannot set both [install] and [[installs]]")
	}
	if !strings.Contains(err.Error(), "exactly one") {
		t.Errorf("error should mention exactly-one rule, got: %v", err)
	}
}

func TestValidate_NeitherInstallNorInstallsRejected(t *testing.T) {
	m := validBase()
	m.Install = nil
	// No Installs either.
	err := m.Validate()
	if err == nil {
		t.Fatal("expected error: manifest must declare an install method")
	}
	if !strings.Contains(err.Error(), "install method is required") {
		t.Errorf("error should mention required install method, got: %v", err)
	}
}

func TestValidate_DuplicateMethodTypeRejected(t *testing.T) {
	m := validBase()
	m.Install = nil
	m.Installs = []Install{
		{Type: "brew", Package: "x"},
		{Type: "brew", Package: "x-community"},
	}
	err := m.Validate()
	if err == nil {
		t.Fatal("expected error: duplicate type in [[installs]]")
	}
	if !strings.Contains(err.Error(), "appears more than once") {
		t.Errorf("error should flag duplicate, got: %v", err)
	}
}

func TestValidate_ScriptMethodInArrayRequiresUninstall(t *testing.T) {
	m := validBase()
	m.Install = nil
	m.Installs = []Install{
		{Type: "brew", Package: "x"},
		{Type: "script", Command: "curl -fsSL https://x.io/i.sh | sh"},
	}
	// No Uninstall — error because one of the methods is script.
	err := m.Validate()
	if err == nil {
		t.Fatal("expected [uninstall] requirement when any method is script")
	}
	if !strings.Contains(err.Error(), "[uninstall] is required") {
		t.Errorf("error should mention [uninstall] requirement, got: %v", err)
	}
}

func TestToApp_MultiMethodEmitsSlice(t *testing.T) {
	m := validBase()
	m.Install = nil
	m.Installs = []Install{
		{Type: "brew", Package: "chess-tui"},
		{Type: "cargo", Package: "chess-tui"},
	}
	app := m.ToApp()
	if len(app.InstallSpecs) != 2 {
		t.Fatalf("expected 2 specs, got %d", len(app.InstallSpecs))
	}
	if app.InstallSpecs[0].Type != "brew" || app.InstallSpecs[1].Type != "cargo" {
		t.Errorf("specs out of order: %+v", app.InstallSpecs)
	}
}
