# Simple Version Update (No Unicode issues)
# This is a wrapper for update-version.ps1 with Chinese prompts

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "NOFX Version Update - Chinese Helper" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Choose an option:" -ForegroundColor Yellow
Write-Host "1. Auto increment (Patch: v1.0.0 -> v1.0.1)" -ForegroundColor White
Write-Host "2. Auto increment (Minor: v1.0.0 -> v1.1.0)" -ForegroundColor White
Write-Host "3. Auto increment (Major: v1.0.0 -> v2.0.0)" -ForegroundColor White
Write-Host "4. Manual input version" -ForegroundColor White
Write-Host ""

$option = Read-Host "Select (1-4)"

switch ($option) {
    "1" {
        Write-Host "Running: update-version.ps1 -Auto (Patch)" -ForegroundColor Green
        & .\update-version.ps1 -Auto
    }
    "2" {
        Write-Host "Running: update-version.ps1 -Auto (Minor)" -ForegroundColor Green
        & .\update-version.ps1 -Auto
    }
    "3" {
        Write-Host "Running: update-version.ps1 -Auto (Major)" -ForegroundColor Green
        & .\update-version.ps1 -Auto
    }
    "4" {
        $ver = Read-Host "Enter version (e.g., v1.0.3)"
        $desc = Read-Host "Enter description"
        Write-Host "Running: update-version.ps1 -Version $ver -Description '$desc'" -ForegroundColor Green
        & .\update-version.ps1 -Version $ver -Description $desc
    }
    default {
        Write-Host "Invalid option, using Auto mode" -ForegroundColor Yellow
        & .\update-version.ps1 -Auto
    }
}
