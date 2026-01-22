package version

import "runtime"

// These variables can be overridden at build time via -ldflags
// Example:
//   go build -ldflags "-X nofx/version.Version=v1.2.3 -X nofx/version.Commit=abc123 -X nofx/version.Branch=main -X nofx/version.BuildDate=2026-01-22T12:00:00Z"
var (
	Version   = "dev"
	Commit    = ""
	Branch    = ""
	BuildDate = ""
)

type Info struct {
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	Branch    string `json:"branch"`
	BuildDate string `json:"buildDate"`
	GoVersion string `json:"goVersion"`
}

func Get() Info {
	return Info{
		Version:   Version,
		Commit:    Commit,
		Branch:    Branch,
		BuildDate: BuildDate,
		GoVersion: runtime.Version(),
	}
}
