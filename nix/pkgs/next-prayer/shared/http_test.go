package shared

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFetchJSON(t *testing.T) {
	t.Run("decodes a successful response", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"value":"ok"}`))
		}))
		defer server.Close()

		req, err := http.NewRequest(http.MethodGet, server.URL, nil)
		if err != nil {
			t.Fatal(err)
		}
		var result struct {
			Value string `json:"value"`
		}
		if err := FetchJSON(req, &result); err != nil {
			t.Fatalf("FetchJSON failed: %v", err)
		}
		if result.Value != "ok" {
			t.Fatalf("value = %q, want ok", result.Value)
		}
	})

	t.Run("rejects a non-success status", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusBadGateway)
		}))
		defer server.Close()

		req, err := http.NewRequest(http.MethodGet, server.URL, nil)
		if err != nil {
			t.Fatal(err)
		}
		if err := FetchJSON(req, &struct{}{}); err == nil || !strings.Contains(err.Error(), "status 502") {
			t.Fatalf("error = %v, want status 502", err)
		}
	})

	t.Run("rejects an oversized response", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			_, _ = w.Write([]byte(strings.Repeat("x", maxAPIResponseBytes+1)))
		}))
		defer server.Close()

		req, err := http.NewRequest(http.MethodGet, server.URL, nil)
		if err != nil {
			t.Fatal(err)
		}
		if err := FetchJSON(req, &struct{}{}); err == nil || !strings.Contains(err.Error(), "response exceeds") {
			t.Fatalf("error = %v, want response-size error", err)
		}
	})
}
