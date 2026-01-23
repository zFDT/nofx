package mcp

import (
	"net/http"
	"os"
	"strconv"
	"time"

	"nofx/logger"
)

// Config client configuration (centralized management of all configurations)
type Config struct {
	// Provider configuration
	Provider string
	APIKey   string
	BaseURL  string
	Model    string

	// Failover API keys for auto-switching when quota exceeded
	AlternativeAPIKeys []string
	// Alternative model names for same API key (e.g., qwen-max -> qwen-plus -> qwen-turbo)
	AlternativeModels []string

	// Model availability tracking (internal use only)
	unavailableModels map[string]bool // key: model name, value: true if unavailable

	// Behavior configuration
	MaxTokens   int
	Temperature float64
	UseFullURL  bool

	// Retry configuration
	MaxRetries      int
	RetryWaitBase   time.Duration
	RetryableErrors []string

	// Timeout configuration
	Timeout time.Duration

	// Dependency injection
	Logger     Logger
	HTTPClient *http.Client
}

// DefaultConfig returns default configuration
func DefaultConfig() *Config {
	return &Config{
		// Default values
		// Set conservative default to 2000 for compatibility with legacy models
		// Will be automatically adjusted by clampMaxTokens() based on specific model capabilities
		// (e.g., qwen-plus-latest supports 32K, qwen-long supports 8K, legacy models limited to 2K)
		MaxTokens:       getEnvInt("AI_MAX_TOKENS", 2000),
		Temperature:     MCPClientTemperature,
		MaxRetries:      MaxRetryTimes,
		RetryWaitBase:   2 * time.Second,
		Timeout:         DefaultTimeout,
		RetryableErrors: retryableErrors,

		// Initialize model availability tracking
		unavailableModels: make(map[string]bool),

		// Default dependencies (use global logger)
		Logger:     logger.NewMCPLogger(),
		HTTPClient: &http.Client{Timeout: DefaultTimeout},
	}
}

// getEnvInt reads integer from environment variable, returns default value if failed
func getEnvInt(key string, defaultValue int) int {
	if val := os.Getenv(key); val != "" {
		if parsed, err := strconv.Atoi(val); err == nil && parsed > 0 {
			return parsed
		}
	}
	return defaultValue
}

// getEnvString reads string from environment variable, returns default value if empty
func getEnvString(key string, defaultValue string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultValue
}
