package shared

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const (
	apiRequestTimeout   = 15 * time.Second
	maxAPIResponseBytes = 1 << 20
)

var apiHTTPClient = &http.Client{Timeout: apiRequestTimeout}

// FetchJSON applies the common timeout, status, and response-size policy used
// by prayer-time providers before decoding a response.
func FetchJSON(req *http.Request, out any) error {
	resp, err := apiHTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("request returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, maxAPIResponseBytes+1))
	if err != nil {
		return fmt.Errorf("failed to read response: %w", err)
	}
	if len(body) > maxAPIResponseBytes {
		return fmt.Errorf("response exceeds %d bytes", maxAPIResponseBytes)
	}

	if err := json.Unmarshal(body, out); err != nil {
		return fmt.Errorf("failed to parse response: %w", err)
	}

	return nil
}
