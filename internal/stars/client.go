package stars

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const DefaultGitHubAPI = "https://api.github.com"

type Client struct {
	Token   string
	BaseURL string
	HTTP    *http.Client
}

func (c Client) Fetch(ctx context.Context, repo string, previous *Observation) (Observation, error) {
	parts := strings.Split(repo, "/")
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return Observation{}, fmt.Errorf("invalid GitHub repository %q", repo)
	}
	base := strings.TrimRight(c.BaseURL, "/")
	if base == "" {
		base = DefaultGitHubAPI
	}
	client := c.HTTP
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	endpoint := base + "/repos/" + url.PathEscape(parts[0]) + "/" + url.PathEscape(parts[1])
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return Observation{}, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	req.Header.Set("User-Agent", "cliff-registry")
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}
	if previous != nil && previous.ETag != "" {
		req.Header.Set("If-None-Match", previous.ETag)
	}

	resp, err := client.Do(req)
	if err != nil {
		return Observation{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotModified {
		if previous == nil {
			return Observation{}, fmt.Errorf("github %s returned 304 without a prior observation", repo)
		}
		return *previous, nil
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return Observation{}, err
	}
	if resp.StatusCode != http.StatusOK {
		snippet := strings.TrimSpace(string(body))
		if len(snippet) > 200 {
			snippet = snippet[:200]
		}
		return Observation{}, fmt.Errorf("github %s: %d %s", repo, resp.StatusCode, snippet)
	}

	var payload struct {
		ID              int64  `json:"id"`
		FullName        string `json:"full_name"`
		StargazersCount int    `json:"stargazers_count"`
		PushedAt        string `json:"pushed_at"`
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		return Observation{}, fmt.Errorf("decode GitHub repository %s: %w", repo, err)
	}
	if payload.ID <= 0 {
		return Observation{}, fmt.Errorf("github %s returned invalid id %d", repo, payload.ID)
	}
	if payload.StargazersCount < 0 {
		return Observation{}, fmt.Errorf("github %s returned negative stars", repo)
	}
	name := payload.FullName
	if name == "" {
		name = repo
	}
	observation := Observation{
		ID:    payload.ID,
		Repo:  name,
		Stars: payload.StargazersCount,
		ETag:  resp.Header.Get("ETag"),
	}
	if payload.PushedAt != "" {
		pushedAt, err := time.Parse(time.RFC3339, payload.PushedAt)
		if err != nil {
			return Observation{}, fmt.Errorf("github %s returned invalid pushed_at: %w", repo, err)
		}
		pushedAt = pushedAt.UTC()
		observation.PushedAt = &pushedAt
	}
	return observation, nil
}
