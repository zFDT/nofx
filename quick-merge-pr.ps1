#!/usr/bin/env pwsh
# Quick Start - Merge PR from upstream NoFx repository
# Usage: .\quick-merge-pr.ps1 1186

param(
    [Parameter(Mandatory=$true, Position=0)]
    [int]$PRNumber
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Quick Merge PR #$PRNumber" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check git status
$status = git status --porcelain
if ($status) {
    Write-Host "ERROR: Working directory is not clean. Commit or stash changes first." -ForegroundColor Red
    exit 1
}

# Create backup
$backupTag = "backup-before-pr-$PRNumber"
Write-Host "[1/5] Creating backup tag: $backupTag..." -ForegroundColor Yellow
git tag $backupTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create backup tag" -ForegroundColor Red
    exit 1
}
Write-Host "      Backup created successfully`n" -ForegroundColor Green

# Fetch PR
Write-Host "[2/5] Fetching PR #$PRNumber from upstream..." -ForegroundColor Yellow
$branchName = "pr-$PRNumber"
git fetch https://github.com/NoFxAiOS/nofx.git "pull/$PRNumber/head:$branchName" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to fetch PR" -ForegroundColor Red
    git tag -d $backupTag | Out-Null
    exit 1
}
Write-Host "      PR fetched successfully`n" -ForegroundColor Green

# Review changes
Write-Host "[3/5] Checking out PR branch..." -ForegroundColor Yellow
git checkout $branchName | Out-Null

Write-Host "`n=== REVIEW CHANGES ===" -ForegroundColor Cyan
Write-Host "Files changed:" -ForegroundColor White
git diff --name-status dev | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

Write-Host "`nPress ENTER to continue with testing, or Ctrl+C to abort..." -ForegroundColor Yellow
Read-Host

# Test
Write-Host "`n[4/5] Testing code..." -ForegroundColor Yellow
Write-Host "  Running go mod tidy..." -ForegroundColor Gray
go mod tidy 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Running go build..." -ForegroundColor Gray
    go build -v 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Tests passed`n" -ForegroundColor Green
        $testsPassed = $true
    } else {
        Write-Host "      Build failed`n" -ForegroundColor Red
        $testsPassed = $false
    }
} else {
    Write-Host "      go mod tidy failed`n" -ForegroundColor Red
    $testsPassed = $false
}

if (-not $testsPassed) {
    Write-Host "Continue with merge anyway? (y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "`nMerge cancelled. Cleaning up..." -ForegroundColor Gray
        git checkout dev | Out-Null
        git branch -D $branchName | Out-Null
        git tag -d $backupTag | Out-Null
        exit 0
    }
}

# Merge
Write-Host "`n[5/5] Merging PR #$PRNumber..." -ForegroundColor Yellow
git checkout dev | Out-Null

$currentBranch = git branch --show-current
if ($currentBranch -ne "dev") {
    Write-Host "ERROR: Not on dev branch" -ForegroundColor Red
    exit 1
}

git merge --no-ff $branchName -m "Merge upstream PR #$PRNumber"

if ($LASTEXITCODE -eq 0) {
    Write-Host "      PR merged successfully`n" -ForegroundColor Green
    
    # Log merge
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - PR #$PRNumber merged"
    Add-Content -Path "PR_MERGE_LOG.txt" -Value $logEntry
    
    # Update plan
    Write-Host "=== MERGE COMPLETE ===" -ForegroundColor Green
    Write-Host "PR #$PRNumber has been merged to dev branch`n" -ForegroundColor White
    
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test the application thoroughly" -ForegroundColor Gray
    Write-Host "  2. Update PR_MERGE_PLAN.md to mark as complete" -ForegroundColor Gray
    Write-Host "  3. Push to remote: git push origin dev" -ForegroundColor Gray
    Write-Host "  4. Clean up branch: git branch -d $branchName`n" -ForegroundColor Gray
    
    Write-Host "To rollback if needed: git reset --hard $backupTag`n" -ForegroundColor Yellow
    
} else {
    Write-Host "ERROR: Merge failed (conflicts may exist)" -ForegroundColor Red
    Write-Host "`nTo resolve:" -ForegroundColor Yellow
    Write-Host "  1. Fix conflicts in the files" -ForegroundColor Gray
    Write-Host "  2. git add <resolved-files>" -ForegroundColor Gray
    Write-Host "  3. git commit" -ForegroundColor Gray
    Write-Host "`nTo abort: git merge --abort`n" -ForegroundColor Gray
    exit 1
}

Write-Host "Done!" -ForegroundColor Green
