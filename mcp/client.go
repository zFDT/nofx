package mcp

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const (
	ProviderCustom = "custom"

	MCPClientTemperature = 0.5
)

var (
	DefaultTimeout = 120 * time.Second

	MaxRetryTimes = 3

	retryableErrors = []string{
		"EOF",
		"timeout",
		"connection reset",
		"connection refused",
		"temporary failure",
		"no such host",
		"stream error",   // HTTP/2 stream error
		"INTERNAL_ERROR", // Server internal error
	}

	// TokenUsageCallback is called after each AI request with token usage info
	TokenUsageCallback func(usage TokenUsage)
)

// TokenUsage represents token usage from AI API response
type TokenUsage struct {
	Provider         string
	Model            string
	PromptTokens     int
	CompletionTokens int
	TotalTokens      int
}

// Client AI API configuration
type Client struct {
	Provider   string
	APIKey     string
	BaseURL    string
	Model      string
	UseFullURL bool // Whether to use full URL (without appending /chat/completions)
	MaxTokens  int  // Maximum tokens for AI response

	httpClient *http.Client
	logger     Logger  // Logger (replaceable)
	config     *Config // Config object (stores all configurations)

	// hooks are used to implement dynamic dispatch (polymorphism)
	// When DeepSeekClient embeds Client, hooks point to DeepSeekClient
	// This way methods called in call() are automatically dispatched to the overridden version in subclass
	hooks clientHooks
}

// New creates default client (backward compatible)
//
// Deprecated: Recommend using NewClient(...opts) for better flexibility
func New() AIClient {
	return NewClient()
}

// NewClient creates client (supports options pattern)
func NewClient(opts ...ClientOption) AIClient {
	// 1. Create default config
	cfg := DefaultConfig()

	// 2. Apply user options
	for _, opt := range opts {
		opt(cfg)
	}

	// 3. Create client instance
	client := &Client{
		Provider:   cfg.Provider,
		APIKey:     cfg.APIKey,
		BaseURL:    cfg.BaseURL,
		Model:      cfg.Model,
		MaxTokens:  cfg.MaxTokens,
		UseFullURL: cfg.UseFullURL,
		httpClient: cfg.HTTPClient,
		logger:     cfg.Logger,
		config:     cfg,
	}

	// 4. Set default Provider (if not set)
	if client.Provider == "" {
		client.Provider = ProviderDeepSeek
		client.BaseURL = DefaultDeepSeekBaseURL
		client.Model = DefaultDeepSeekModel
	}

	// 5. Set hooks to point to self
	client.hooks = client

	return client
}

// SetCustomAPI sets custom OpenAI-compatible API
func (client *Client) SetAPIKey(apiKey, apiURL, customModel string) {
	client.Provider = ProviderCustom
	client.APIKey = apiKey

	// Check if URL ends with #, if so use full URL (without appending /chat/completions)
	if strings.HasSuffix(apiURL, "#") {
		client.BaseURL = strings.TrimSuffix(apiURL, "#")
		client.UseFullURL = true
	} else {
		client.BaseURL = apiURL
		client.UseFullURL = false
	}

	client.Model = customModel
}

func (client *Client) SetTimeout(timeout time.Duration) {
	client.httpClient.Timeout = timeout
}

// SetAlternativeAPIKeys sets alternative API keys for auto-failover when quota exceeded
func (client *Client) SetAlternativeAPIKeys(keys []string) {
	client.config.AlternativeAPIKeys = keys
	if len(keys) > 0 {
		client.logger.Infof("🔧 [MCP] Set %d alternative API keys for failover", len(keys))
	}
}

// SetAlternativeModels sets alternative model names for same API key
func (client *Client) SetAlternativeModels(models []string) {
	client.config.AlternativeModels = models
	if len(models) > 0 {
		client.logger.Infof("🔧 [MCP] Set %d alternative models for failover: %v", len(models), models)
	}
}

// CallWithMessages template method - fixed retry flow (cannot be overridden)
func (client *Client) CallWithMessages(systemPrompt, userPrompt string) (string, error) {
	if client.APIKey == "" {
		return "", fmt.Errorf("AI API key not set, please call SetAPIKey first")
	}

	// Build all combinations: (API keys) x (models)
	allKeys := []string{client.APIKey}
	allKeys = append(allKeys, client.config.AlternativeAPIKeys...)

	allModels := []string{client.Model}
	allModels = append(allModels, client.config.AlternativeModels...)

	var lastErr error
	originalModel := client.Model

	// Track statistics
	totalTried := 0
	totalSkipped := 0

	// Try each API key
	for keyIdx, apiKey := range allKeys {
		if keyIdx > 0 {
			// Switch to alternative key
			client.logger.Infof("🔄 Switching to alternative API key %d/%d", keyIdx+1, len(allKeys))
			client.APIKey = apiKey
		}

		// Try each model for current key
		for modelIdx, model := range allModels {
			// Skip models marked as unavailable
			if client.config.unavailableModels[model] {
				client.logger.Debugf("⏭️  Skipping unavailable model: %s", model)
				totalSkipped++
				continue
			}

			if modelIdx > 0 || keyIdx > 0 {
				client.logger.Infof("🔄 Switching to model: %s (tried: %d, skipped: %d)", model, totalTried, totalSkipped)
				client.Model = model
			}

			totalTried++

			// Fixed retry flow for current key+model combination
			maxRetries := client.config.MaxRetries
			modelFailed := false
			// Track max_tokens fallback attempts (initial + two halvings => 3 tries total)
			originalTokens := client.MaxTokens
			localMaxTokens := originalTokens
			halvingCount := 0 // number of halvings applied (max 2)

			for attempt := 1; attempt <= maxRetries; attempt++ {
				if attempt > 1 {
					client.logger.Warnf("⚠️  AI API call failed, retrying (%d/%d)...", attempt, maxRetries)
				}

				// Apply local max tokens for this attempt
				client.MaxTokens = localMaxTokens

				// Call the fixed single-call flow
				result, err := client.hooks.call(systemPrompt, userPrompt)
				if err == nil {
					if attempt > 1 || keyIdx > 0 || modelIdx > 0 {
						client.logger.Infof("✅ AI API call succeeded with key %d model %s", keyIdx+1, model)
					}
					// restore client.MaxTokens before return
					client.MaxTokens = originalTokens
					return result, nil
				}

				lastErr = err

				// Special handling: max_tokens exceeds provider range -> try halving up to 2 times
				if client.hooks.isMaxTokensRangeError(err) {
					if halvingCount < 2 {
						// halve tokens and retry
						newTokens := localMaxTokens / 2
						if newTokens < 1 {
							newTokens = 1
						}
						client.logger.Warnf("⚠️  max_tokens %d exceeds provider limit, halving to %d (attempt %d)", localMaxTokens, newTokens, halvingCount+1)
						localMaxTokens = newTokens
						halvingCount++
						// Wait before retry
						if attempt < maxRetries {
							waitTime := client.config.RetryWaitBase * time.Duration(attempt)
							client.logger.Infof("⏳ Waiting %v before retry after halving...", waitTime)
							time.Sleep(waitTime)
						}
						continue
					}
					// exceeded halving attempts for this model, mark as failed and rotate
					client.logger.Warnf("⚠️  max_tokens still invalid after %d halvings for model %s, rotating model...", halvingCount, model)
					modelFailed = true
					break
				}

				// Check if quota exceeded or model not available
				if client.hooks.isQuotaExceededError(err) {
					client.logger.Warnf("⚠️  Quota exceeded for model %s, marking as unavailable", model)
					client.config.unavailableModels[model] = true
					modelFailed = true
					break // Try next model
				}

				// Check for model not found or invalid errors
				if client.hooks.isModelNotAvailableError(err) {
					client.logger.Warnf("⚠️  Model %s not available, marking as unavailable", model)
					client.config.unavailableModels[model] = true
					modelFailed = true
					break // Try next model
				}

				// Check if error is retryable via hooks (supports custom retry strategy in subclass)
				if !client.hooks.isRetryableError(err) {
					client.logger.Warnf("❌ Non-retryable error for model %s: %v", model, err)
					client.MaxTokens = originalTokens // Restore original
					client.Model = originalModel      // Restore original
					return "", err
				}

				// Wait before retry
				if attempt < maxRetries {
					waitTime := client.config.RetryWaitBase * time.Duration(attempt)
					client.logger.Infof("⏳ Waiting %v before retry...", waitTime)
					time.Sleep(waitTime)
				}
			}

			// If all retries failed for this model, mark as unavailable
			if !modelFailed && lastErr != nil {
				client.logger.Warnf("⚠️  Model %s failed after %d retries, marking as unavailable", model, maxRetries)
				client.config.unavailableModels[model] = true
			}
			// Restore original tokens before next model
			client.MaxTokens = originalTokens
		}
	}

	client.Model = originalModel // Restore original
	// Restore original tokens
	// Note: originalTokens captured per-model, but restore to config default here
	// (in case of early return above, restore happened in place)
	// No-op if unchanged.

	// Calculate statistics
	totalModels := len(allKeys) * len(allModels)

	client.logger.Errorf("❌ All available models exhausted. Total: %d, Tried: %d, Skipped: %d, Unavailable: %d",
		totalModels, totalTried, totalSkipped, len(client.config.unavailableModels))

	if totalTried == 0 {
		return "", fmt.Errorf("no available models to try (all %d models marked as unavailable)", totalModels)
	}

	return "", fmt.Errorf("all %d tried combinations failed, %d models marked unavailable, last error: %w",
		totalTried, len(client.config.unavailableModels), lastErr)
}

func (client *Client) setAuthHeader(reqHeader http.Header) {
	reqHeader.Set("Authorization", fmt.Sprintf("Bearer %s", client.APIKey))
}

func (client *Client) getProviderMaxTokensLimit() int {
	switch client.Provider {
	case ProviderQwen:
		return QwenMaxTokensLimit
	default:
		return 0
	}
}

func (client *Client) clampMaxTokens(tokens int) int {
	limit := client.getProviderMaxTokensLimit()
	if limit > 0 && tokens > limit {
		client.logger.Warnf("⚠️ [%s] max_tokens %d exceeds provider limit %d, capping to limit", client.String(), tokens, limit)
		return limit
	}
	return tokens
}

func (client *Client) buildMCPRequestBody(systemPrompt, userPrompt string) map[string]any {
	// Build messages array
	messages := []map[string]string{}

	// If system prompt exists, add system message
	if systemPrompt != "" {
		messages = append(messages, map[string]string{
			"role":    "system",
			"content": systemPrompt,
		})
	}
	// Add user message
	messages = append(messages, map[string]string{
		"role":    "user",
		"content": userPrompt,
	})

	// Build request body
	requestBody := map[string]interface{}{
		"model":       client.Model,
		"messages":    messages,
		"temperature": client.config.Temperature, // Use configured temperature
	}

	maxTokens := client.clampMaxTokens(client.MaxTokens)
	// OpenAI newer models use max_completion_tokens instead of max_tokens
	if client.Provider == ProviderOpenAI {
		requestBody["max_completion_tokens"] = maxTokens
	} else {
		requestBody["max_tokens"] = maxTokens
	}
	return requestBody
}

// can be used to marshal the request body and can be overridden
func (client *Client) marshalRequestBody(requestBody map[string]any) ([]byte, error) {
	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize request: %w", err)
	}
	return jsonData, nil
}

func (client *Client) parseMCPResponse(body []byte) (string, error) {
	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
		Usage struct {
			PromptTokens     int `json:"prompt_tokens"`
			CompletionTokens int `json:"completion_tokens"`
			TotalTokens      int `json:"total_tokens"`
		} `json:"usage"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("API returned empty response")
	}

	// Report token usage if callback is set
	if TokenUsageCallback != nil && result.Usage.TotalTokens > 0 {
		TokenUsageCallback(TokenUsage{
			Provider:         client.Provider,
			Model:            client.Model,
			PromptTokens:     result.Usage.PromptTokens,
			CompletionTokens: result.Usage.CompletionTokens,
			TotalTokens:      result.Usage.TotalTokens,
		})
	}

	return result.Choices[0].Message.Content, nil
}

func (client *Client) buildUrl() string {
	if client.UseFullURL {
		return client.BaseURL
	}
	return fmt.Sprintf("%s/chat/completions", client.BaseURL)
}

func (client *Client) buildRequest(url string, jsonData []byte) (*http.Request, error) {
	// Create HTTP request
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("fail to build request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// Set auth header via hooks (supports overriding in subclass)
	client.hooks.setAuthHeader(req.Header)

	return req, nil
}

// call single AI API call (fixed flow, cannot be overridden)
func (client *Client) call(systemPrompt, userPrompt string) (string, error) {
	// Print current AI configuration
	client.logger.Infof("📡 [%s] Request AI Server: BaseURL: %s", client.String(), client.BaseURL)
	client.logger.Debugf("[%s] UseFullURL: %v", client.String(), client.UseFullURL)
	if len(client.APIKey) > 8 {
		client.logger.Debugf("[%s]   API Key: %s...%s", client.String(), client.APIKey[:4], client.APIKey[len(client.APIKey)-4:])
	}

	// Step 1: Build request body (via hooks for dynamic dispatch)
	requestBody := client.hooks.buildMCPRequestBody(systemPrompt, userPrompt)

	// Step 2: Serialize request body (via hooks for dynamic dispatch)
	jsonData, err := client.hooks.marshalRequestBody(requestBody)
	if err != nil {
		return "", err
	}

	// Step 3: Build URL (via hooks for dynamic dispatch)
	url := client.hooks.buildUrl()
	client.logger.Infof("📡 [MCP %s] Request URL: %s", client.String(), url)

	// Step 4: Create HTTP request (fixed logic)
	req, err := client.hooks.buildRequest(url, jsonData)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	// Step 5: Send HTTP request (fixed logic)
	resp, err := client.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Step 6: Read response body (fixed logic)
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	// Step 7: Check HTTP status code (fixed logic)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API returned error (status %d): %s", resp.StatusCode, string(body))
	}

	// Step 8: Parse response (via hooks for dynamic dispatch)
	result, err := client.hooks.parseMCPResponse(body)
	if err != nil {
		return "", fmt.Errorf("fail to parse AI server response: %w", err)
	}

	return result, nil
}

func (client *Client) String() string {
	return fmt.Sprintf("[Provider: %s, Model: %s]",
		client.Provider, client.Model)
}

// isRetryableError determines if error is retryable (network errors, timeouts, etc.)
func (client *Client) isRetryableError(err error) bool {
	errStr := err.Error()
	// Network errors, timeouts, EOF, etc. can be retried
	for _, retryable := range client.config.RetryableErrors {
		if strings.Contains(errStr, retryable) {
			return true
		}
	}
	return false
}

// isQuotaExceededError determines if error is due to quota/rate limit exceeded
func (client *Client) isQuotaExceededError(err error) bool {
	errStr := strings.ToLower(err.Error())
	quotaKeywords := []string{
		"quota",
		"exceeded",
		"insufficient",
		"rate limit",
		"too many requests",
		"429",
		"allocationquota",
		"freetieronly",
	}
	for _, keyword := range quotaKeywords {
		if strings.Contains(errStr, keyword) {
			return true
		}
	}
	return false
}

// isModelNotAvailableError determines if error is due to model not found or not available
func (client *Client) isModelNotAvailableError(err error) bool {
	errStr := strings.ToLower(err.Error())
	modelErrorKeywords := []string{
		"model not found",
		"model does not exist",
		"invalid model",
		"model is not available",
		"model not available",
		"unsupported model",
		"404",
		"model_not_found",
		"invalidparameter.model", // Qwen: InvalidParameter.Model.NotFound
	}
	for _, keyword := range modelErrorKeywords {
		if strings.Contains(errStr, keyword) {
			return true
		}
	}
	return false
}

// isMaxTokensRangeError determines if error is due to max_tokens exceeding provider limits
func (client *Client) isMaxTokensRangeError(err error) bool {
	errStr := strings.ToLower(err.Error())
	// Check for max_tokens related errors
	if strings.Contains(errStr, "max_tokens") || strings.Contains(errStr, "max_completion_tokens") {
		if strings.Contains(errStr, "range") || strings.Contains(errStr, "invalid_parameter") || strings.Contains(errStr, "invalidparameter") || strings.Contains(errStr, "should be [") {
			return true
		}
	}
	return false
}

// isInputLengthError determines if error is due to input length exceeding provider limits (e.g., Qwen 6000 char limit)
func (client *Client) isInputLengthError(err error) bool {
	errStr := strings.ToLower(err.Error())
	// Check for input length related errors
	if strings.Contains(errStr, "input length") || strings.Contains(errStr, "input_length") {
		if strings.Contains(errStr, "range") || strings.Contains(errStr, "should be") || strings.Contains(errStr, "exceed") {
			return true
		}
	}
	return false
}

// ============================================================
// Builder Pattern API (Advanced Features)
// ============================================================

// CallWithRequest calls AI API using Request object (supports advanced features)
//
// This method supports:
// - Multi-turn conversation history
// - Fine-grained parameter control (temperature, top_p, penalties, etc.)
// - Function Calling / Tools
// - Streaming response (future support)
//
// Usage example:
//
//	request := NewRequestBuilder().
//	    WithSystemPrompt("You are helpful").
//	    WithUserPrompt("Hello").
//	    WithTemperature(0.8).
//	    Build()
//	result, err := client.CallWithRequest(request)
func (client *Client) CallWithRequest(req *Request) (string, error) {
	if client.APIKey == "" {
		return "", fmt.Errorf("AI API key not set, please call SetAPIKey first")
	}

	// If Model is not set in Request, use Client's Model
	if req.Model == "" {
		req.Model = client.Model
	}

	// Fixed retry flow
	var lastErr error
	maxRetries := client.config.MaxRetries
	// Track max_tokens fallback attempts (initial + two halvings => 3 tries total)
	originalTokens := 0
	if req.MaxTokens != nil {
		originalTokens = *req.MaxTokens
	} else {
		originalTokens = client.MaxTokens
	}
	localMaxTokens := originalTokens
	halvingCount := 0 // number of halvings applied (max 2)

	for attempt := 1; attempt <= maxRetries; attempt++ {
		if attempt > 1 {
			client.logger.Warnf("⚠️  AI API call failed, retrying (%d/%d)...", attempt, maxRetries)
		}

		// Call single request
		// Apply local max tokens for this attempt into request
		if localMaxTokens > 0 {
			req.MaxTokens = &localMaxTokens
		}
		result, err := client.callWithRequest(req)
		if err == nil {
			if attempt > 1 {
				client.logger.Infof("✓ AI API retry succeeded")
			}
			return result, nil
		}

		lastErr = err
		// Special handling: max_tokens exceeds provider range -> try halving up to 2 times
		if client.hooks.isMaxTokensRangeError(err) {
			if halvingCount < 2 {
				newTokens := localMaxTokens / 2
				if newTokens < 1 {
					newTokens = 1
				}
				client.logger.Warnf("⚠️  max_tokens %d exceeds provider limit (builder), halving to %d (attempt %d)", localMaxTokens, newTokens, halvingCount+1)
				localMaxTokens = newTokens
				halvingCount++
				// Wait before retry
				if attempt < maxRetries {
					waitTime := client.config.RetryWaitBase * time.Duration(attempt)
					client.logger.Infof("⏳ Waiting %v before retry after halving (builder)...", waitTime)
					time.Sleep(waitTime)
				}
				continue
			}
			// exceeded halving attempts, return error to allow upper layers to rotate
			client.logger.Warnf("⚠️  max_tokens still invalid after %d halvings in builder", halvingCount)
			return "", err
		}

		// Check if error is retryable
		if !client.hooks.isRetryableError(err) {
			return "", err
		}

		// Wait before retry
		if attempt < maxRetries {
			waitTime := client.config.RetryWaitBase * time.Duration(attempt)
			client.logger.Infof("⏳ Waiting %v before retry...", waitTime)
			time.Sleep(waitTime)
		}
	}

	return "", fmt.Errorf("still failed after %d retries: %w", maxRetries, lastErr)
}

// callWithRequest single AI API call (using Request object)
func (client *Client) callWithRequest(req *Request) (string, error) {
	// Print current AI configuration
	client.logger.Infof("📡 [%s] Request AI Server with Builder: BaseURL: %s", client.String(), client.BaseURL)
	client.logger.Debugf("[%s] Messages count: %d", client.String(), len(req.Messages))

	// Build request body (from Request object)
	requestBody := client.buildRequestBodyFromRequest(req)

	// Serialize request body
	jsonData, err := client.hooks.marshalRequestBody(requestBody)
	if err != nil {
		return "", err
	}

	// Build URL
	url := client.hooks.buildUrl()
	client.logger.Infof("📡 [MCP %s] Request URL: %s", client.String(), url)

	// Create HTTP request
	httpReq, err := client.hooks.buildRequest(url, jsonData)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	// Send HTTP request
	resp, err := client.httpClient.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	// Check HTTP status code
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API returned error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse response
	result, err := client.hooks.parseMCPResponse(body)
	if err != nil {
		return "", fmt.Errorf("fail to parse AI server response: %w", err)
	}

	return result, nil
}

// buildRequestBodyFromRequest builds request body from Request object
func (client *Client) buildRequestBodyFromRequest(req *Request) map[string]any {
	// Convert Message to API format
	messages := make([]map[string]string, 0, len(req.Messages))
	for _, msg := range req.Messages {
		messages = append(messages, map[string]string{
			"role":    msg.Role,
			"content": msg.Content,
		})
	}

	// Build basic request body
	requestBody := map[string]interface{}{
		"model":    req.Model,
		"messages": messages,
	}

	// Add optional parameters (only add non-nil parameters)
	if req.Temperature != nil {
		requestBody["temperature"] = *req.Temperature
	} else {
		// If not set in Request, use Client's configuration
		requestBody["temperature"] = client.config.Temperature
	}

	// OpenAI newer models use max_completion_tokens instead of max_tokens
	tokenKey := "max_tokens"
	if client.Provider == ProviderOpenAI {
		tokenKey = "max_completion_tokens"
	}

	maxTokens := client.MaxTokens
	if req.MaxTokens != nil {
		maxTokens = *req.MaxTokens
	}
	maxTokens = client.clampMaxTokens(maxTokens)
	// If not set in Request, use Client's MaxTokens
	requestBody[tokenKey] = maxTokens

	if req.TopP != nil {
		requestBody["top_p"] = *req.TopP
	}

	if req.FrequencyPenalty != nil {
		requestBody["frequency_penalty"] = *req.FrequencyPenalty
	}

	if req.PresencePenalty != nil {
		requestBody["presence_penalty"] = *req.PresencePenalty
	}

	if len(req.Stop) > 0 {
		requestBody["stop"] = req.Stop
	}

	if len(req.Tools) > 0 {
		requestBody["tools"] = req.Tools
	}

	if req.ToolChoice != "" {
		requestBody["tool_choice"] = req.ToolChoice
	}

	if req.Stream {
		requestBody["stream"] = true
	}

	return requestBody
}
