# Build script for Windows that reads version.json and passes to docker-compose

# Read version.json
$versionInfo = Get-Content version.json | ConvertFrom-Json
$version = $versionInfo.version
$branch = $versionInfo.branch

# Get Git commit
try {
    $commit = (git rev-parse --short HEAD 2>$null)
    if (-not $commit) { $commit = "unknown" }
} catch {
    $commit = "unknown"
}

# Get build date
$buildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "Building with version info:" -ForegroundColor Green
Write-Host "  VERSION: $version" -ForegroundColor Cyan
Write-Host "  COMMIT: $commit" -ForegroundColor Cyan
Write-Host "  BRANCH: $branch" -ForegroundColor Cyan
Write-Host "  BUILD_DATE: $buildDate" -ForegroundColor Cyan

# Set environment variables
$env:VERSION = $version
$env:COMMIT = $commit
$env:BRANCH = $branch
$env:BUILD_DATE = $buildDate

# Build with docker-compose
docker-compose build --no-cache $args
