package version

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"sync"
)

// Config represents the version configuration from version.json
type Config struct {
	Version     string   `json:"version"`
	Description string   `json:"description"`
	BuildDate   string   `json:"buildDate"`
	Commit      string   `json:"commit"`
	Branch      string   `json:"branch"`
	Features    []string `json:"features"`
}

type Info struct {
	Version     string   `json:"version"`
	Commit      string   `json:"commit"`
	Branch      string   `json:"branch"`
	BuildDate   string   `json:"buildDate"`
	GoVersion   string   `json:"goVersion"`
	Description string   `json:"description,omitempty"`
	Features    []string `json:"features,omitempty"`
}

var (
	versionInfo Info
	once        sync.Once
)

// loadVersion loads version information from version.json
func loadVersion() {
	once.Do(func() {
		// Default values in case file is missing
		versionInfo = Info{
			Version:   "dev",
			Commit:    "",
			Branch:    "unknown",
			BuildDate: "",
			GoVersion: runtime.Version(),
		}

		// Try to read version.json
		configPath := "version.json"

		// Check if running from a different directory
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			// Try executable directory
			if exePath, err := os.Executable(); err == nil {
				configPath = filepath.Join(filepath.Dir(exePath), "version.json")
			}
		}

		data, err := os.ReadFile(configPath)
		if err != nil {
			// If file doesn't exist, use defaults
			return
		}

		var config Config
		if err := json.Unmarshal(data, &config); err != nil {
			// If parsing fails, use defaults
			return
		}

		// Update version info from config
		versionInfo.Version = config.Version
		versionInfo.Commit = config.Commit
		versionInfo.Branch = config.Branch
		versionInfo.BuildDate = config.BuildDate
		versionInfo.Description = config.Description
		versionInfo.Features = config.Features
		versionInfo.GoVersion = runtime.Version()
	})
}

func Get() Info {
	loadVersion()
	return versionInfo
}
