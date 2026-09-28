package shared

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestFetchJSONErrors(t *testing.T) {
	for _, tc := range []struct {
		name    string
		handler http.HandlerFunc
		want    string
	}{
		{"malformed JSON", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("{")) }, "failed to parse response:"},
		{"truncated body", func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Length", "100")
			_, _ = w.Write([]byte("{}"))
		}, "failed to read response:"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			server := httptest.NewServer(tc.handler)
			defer server.Close()
			req, err := http.NewRequest(http.MethodGet, server.URL, nil)
			if err != nil {
				t.Fatal(err)
			}
			if err := FetchJSON(req, &struct{}{}); err == nil || !strings.HasPrefix(err.Error(), tc.want) {
				t.Fatalf("error = %v, want prefix %q", err, tc.want)
			}
		})
	}
}

func TestFetchJSONTimeout(t *testing.T) {
	if apiHTTPClient.Timeout != 15*time.Second {
		t.Fatalf("API client timeout = %s, want 15s", apiHTTPClient.Timeout)
	}
	original := apiHTTPClient
	apiHTTPClient = &http.Client{Timeout: 20 * time.Millisecond}
	t.Cleanup(func() { apiHTTPClient = original })
	server := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, req *http.Request) {
		<-req.Context().Done()
	}))
	defer server.Close()
	req, err := http.NewRequest(http.MethodGet, server.URL, nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := FetchJSON(req, &struct{}{}); err == nil || !strings.Contains(err.Error(), "context deadline exceeded") {
		t.Fatalf("error = %v, want deadline exceeded", err)
	}
}

func TestFetchJSONCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://127.0.0.1:0", nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := FetchJSON(req, &struct{}{}); err == nil || !strings.Contains(err.Error(), "context canceled") {
		t.Fatalf("error = %v, want canceled request", err)
	}
}
