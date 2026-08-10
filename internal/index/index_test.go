package index

import (
	"encoding/json"
	"testing"
)

func TestSchemaV2PreservesUnavailableWindowsAndMeasuredZero(t *testing.T) {
	catalog := Catalog{
		SchemaVersion: SchemaVersion,
		StarWindows: map[string]StarWindow{
			"7d":  {RequestedDays: 7},
			"30d": {RequestedDays: 30},
		},
		Apps: []App{{
			Name:       "flat",
			Repo:       "a/flat",
			StarGrowth: map[string]int{"7d": 0},
		}},
	}
	body, err := json.Marshal(catalog)
	if err != nil {
		t.Fatal(err)
	}
	var wire struct {
		SchemaVersion int `json:"schema_version"`
		StarWindows   map[string]struct {
			From *string `json:"from"`
		} `json:"star_windows"`
		Apps []struct {
			StarGrowth map[string]int `json:"star_growth"`
		} `json:"apps"`
	}
	if err := json.Unmarshal(body, &wire); err != nil {
		t.Fatal(err)
	}
	if wire.SchemaVersion != 2 {
		t.Fatalf("schema_version = %d, want 2", wire.SchemaVersion)
	}
	if _, ok := wire.StarWindows["7d"]; !ok || wire.StarWindows["7d"].From != nil {
		t.Fatalf("unavailable 7d window was not represented correctly: %+v", wire.StarWindows)
	}
	if delta, ok := wire.Apps[0].StarGrowth["7d"]; !ok || delta != 0 {
		t.Fatalf("measured zero delta = %d, present=%v", delta, ok)
	}
}
