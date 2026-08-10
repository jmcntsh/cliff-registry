package stars

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestClientFetchParsesStableRepositoryMetadata(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/repos/old-owner/tool" {
			t.Errorf("path = %q", r.URL.Path)
		}
		if got := r.Header.Get("Authorization"); got != "Bearer token" {
			t.Errorf("authorization = %q", got)
		}
		if got := r.Header.Get("Accept"); got != "application/vnd.github+json" {
			t.Errorf("accept = %q", got)
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("ETag", `"fixture-etag"`)
		_, _ = w.Write([]byte(`{
			"id": 12345,
			"full_name": "new-owner/tool",
			"stargazers_count": 42,
			"pushed_at": "2026-08-09T12:34:56Z"
		}`))
	}))
	defer server.Close()

	client := Client{Token: "token", BaseURL: server.URL, HTTP: server.Client()}
	got, err := client.Fetch(context.Background(), "old-owner/tool", nil)
	if err != nil {
		t.Fatal(err)
	}
	if got.ID != 12345 || got.Repo != "new-owner/tool" || got.Stars != 42 {
		t.Fatalf("observation = %+v", got)
	}
	if got.ETag != `"fixture-etag"` {
		t.Fatalf("etag = %q", got.ETag)
	}
	wantPushed := time.Date(2026, 8, 9, 12, 34, 56, 0, time.UTC)
	if got.PushedAt == nil || !got.PushedAt.Equal(wantPushed) {
		t.Fatalf("pushed_at = %v, want %v", got.PushedAt, wantPushed)
	}
}

func TestClientFetchReturnsStatusErrorWithoutObservation(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "rate limited", http.StatusForbidden)
	}))
	defer server.Close()

	client := Client{BaseURL: server.URL, HTTP: server.Client()}
	_, err := client.Fetch(context.Background(), "a/tool", nil)
	if err == nil || !strings.Contains(err.Error(), "403") {
		t.Fatalf("error = %v, want status", err)
	}
}

func TestClientFetchRejectsInvalidInputAndPayload(t *testing.T) {
	client := Client{}
	if _, err := client.Fetch(context.Background(), "not-a-repo", nil); err == nil {
		t.Fatal("invalid repository should fail before a request")
	}

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"id":1,"full_name":"a/tool","stargazers_count":3,"pushed_at":"bad"}`))
	}))
	defer server.Close()
	client = Client{BaseURL: server.URL, HTTP: server.Client()}
	if _, err := client.Fetch(context.Background(), "a/tool", nil); err == nil || !strings.Contains(err.Error(), "pushed_at") {
		t.Fatalf("invalid timestamp error = %v", err)
	}
}

func TestClientFetchUsesConditionalRequest(t *testing.T) {
	previous := Observation{
		ID: 7, Repo: "a/tool", Stars: 9, ETag: `"previous"`,
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("If-None-Match"); got != previous.ETag {
			t.Errorf("If-None-Match = %q, want %q", got, previous.ETag)
		}
		w.WriteHeader(http.StatusNotModified)
	}))
	defer server.Close()

	client := Client{BaseURL: server.URL, HTTP: server.Client()}
	got, err := client.Fetch(context.Background(), "a/tool", &previous)
	if err != nil {
		t.Fatal(err)
	}
	if got.ID != previous.ID || got.Stars != previous.Stars || got.ETag != previous.ETag {
		t.Fatalf("304 observation = %+v, want %+v", got, previous)
	}
}
