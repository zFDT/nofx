package mcp

import (
	"errors"
	"testing"
)

// TestQuotaExceededDetection tests if various quota error formats are correctly detected
func TestQuotaExceededDetection(t *testing.T) {
	client := NewClient().(*Client)

	testCases := []struct {
		name     string
		err      error
		expected bool
	}{
		{
			name:     "Qwen AllocationQuota.FreeTierOnly",
			err:      errors.New("API returned error (status 403): {\"error\": \"AllocationQuota.FreeTierOnly\"}"),
			expected: true,
		},
		{
			name:     "Qwen quota exceeded",
			err:      errors.New("API returned error (status 403): quota exceeded"),
			expected: true,
		},
		{
			name:     "Rate limit 429",
			err:      errors.New("API returned error (status 429): too many requests"),
			expected: true,
		},
		{
			name:     "Insufficient quota",
			err:      errors.New("insufficient quota remaining"),
			expected: true,
		},
		{
			name:     "Not a quota error",
			err:      errors.New("connection timeout"),
			expected: false,
		},
		{
			name:     "Network error",
			err:      errors.New("network unreachable"),
			expected: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := client.isQuotaExceededError(tc.err)
			if result != tc.expected {
				t.Errorf("isQuotaExceededError(%q) = %v, want %v", tc.err.Error(), result, tc.expected)
			}
		})
	}
}

// TestModelNotAvailableDetection tests if model not found errors are correctly detected
func TestModelNotAvailableDetection(t *testing.T) {
	client := NewClient().(*Client)

	testCases := []struct {
		name     string
		err      error
		expected bool
	}{
		{
			name:     "Model not found 404",
			err:      errors.New("API returned error (status 404): model not found"),
			expected: true,
		},
		{
			name:     "Invalid model",
			err:      errors.New("invalid model: qwen-xxx"),
			expected: true,
		},
		{
			name:     "Model does not exist",
			err:      errors.New("model does not exist"),
			expected: true,
		},
		{
			name:     "Unsupported model",
			err:      errors.New("unsupported model"),
			expected: true,
		},
		{
			name:     "Model not available",
			err:      errors.New("model is not available"),
			expected: true,
		},
		{
			name:     "Qwen InvalidParameter.Model.NotFound",
			err:      errors.New("API returned error (status 400): InvalidParameter.Model.NotFound"),
			expected: true,
		},
		{
			name:     "Not a model error",
			err:      errors.New("connection timeout"),
			expected: false,
		},
		{
			name:     "Quota error (not model error)",
			err:      errors.New("quota exceeded"),
			expected: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := client.isModelNotAvailableError(tc.err)
			if result != tc.expected {
				t.Errorf("isModelNotAvailableError(%q) = %v, want %v", tc.err.Error(), result, tc.expected)
			}
		})
	}
}

// TestUnavailableModelsTracking tests if unavailable models are correctly tracked
func TestUnavailableModelsTracking(t *testing.T) {
	client := NewClient().(*Client)

	// Initially empty
	if len(client.config.unavailableModels) != 0 {
		t.Errorf("Initial unavailableModels should be empty, got %d", len(client.config.unavailableModels))
	}

	// Mark a model as unavailable
	client.config.unavailableModels["qwen-turbo"] = true

	// Check if marked
	if !client.config.unavailableModels["qwen-turbo"] {
		t.Error("qwen-turbo should be marked as unavailable")
	}

	// Check if another model is not marked
	if client.config.unavailableModels["qwen-plus"] {
		t.Error("qwen-plus should not be marked as unavailable")
	}

	// Create a new client (simulating config update)
	newClient := NewClient().(*Client)

	// Verify new client has clean state
	if len(newClient.config.unavailableModels) != 0 {
		t.Errorf("New client unavailableModels should be empty, got %d", len(newClient.config.unavailableModels))
	}

	if newClient.config.unavailableModels["qwen-turbo"] {
		t.Error("New client should not have old unavailable markers")
	}
}
