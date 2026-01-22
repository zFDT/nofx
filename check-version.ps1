# 版本检查脚本
# 快速检查本地和远程服务器的版本信息

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "http://localhost:8080",
    
    [Parameter(Mandatory=$false)]
    [switch]$Compare
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           🔍 NOFX 版本检查工具                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 读取本地 version.json
$localVersion = $null
if (Test-Path "version.json") {
    try {
        $localVersion = Get-Content "version.json" | ConvertFrom-Json
        Write-Host "📁 本地版本 (version.json):" -ForegroundColor Green
        Write-Host "   版本: $($localVersion.version)" -ForegroundColor White
        Write-Host "   描述: $($localVersion.description)" -ForegroundColor Gray
        Write-Host "   日期: $($localVersion.buildDate)" -ForegroundColor Gray
        Write-Host "   提交: $($localVersion.commit)" -ForegroundColor Gray
        Write-Host "   分支: $($localVersion.branch)" -ForegroundColor Gray
    } catch {
        Write-Host "⚠️  警告: 无法读取本地 version.json" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  警告: 找不到本地 version.json 文件" -ForegroundColor Yellow
}

Write-Host ""

# 查询远程服务器版本
$remoteVersion = $null
try {
    Write-Host "🌐 查询服务器版本 ($ServerUrl/api/version)..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "$ServerUrl/api/version" -Method Get -TimeoutSec 5
    $remoteVersion = $response
    
    Write-Host "✅ 服务器版本:" -ForegroundColor Green
    Write-Host "   版本: $($remoteVersion.version)" -ForegroundColor White
    Write-Host "   描述: $($remoteVersion.description)" -ForegroundColor Gray
    Write-Host "   日期: $($remoteVersion.buildDate)" -ForegroundColor Gray
    Write-Host "   提交: $($remoteVersion.commit)" -ForegroundColor Gray
    Write-Host "   分支: $($remoteVersion.branch)" -ForegroundColor Gray
    Write-Host "   Go版本: $($remoteVersion.goVersion)" -ForegroundColor Gray
} catch {
    Write-Host "❌ 无法连接到服务器: $_" -ForegroundColor Red
    Write-Host "   请确保服务器正在运行: $ServerUrl" -ForegroundColor Yellow
}

# 版本对比
if ($Compare -and $localVersion -and $remoteVersion) {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📊 版本对比:" -ForegroundColor Cyan
    Write-Host ""
    
    $versionMatch = $localVersion.version -eq $remoteVersion.version
    $commitMatch = $localVersion.commit -eq $remoteVersion.commit
    
    if ($versionMatch) {
        Write-Host "   ✅ 版本号一致: $($localVersion.version)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 版本号不一致!" -ForegroundColor Red
        Write-Host "      本地: $($localVersion.version)" -ForegroundColor Yellow
        Write-Host "      服务器: $($remoteVersion.version)" -ForegroundColor Yellow
    }
    
    if ($commitMatch -and $localVersion.commit) {
        Write-Host "   ✅ Commit 一致: $($localVersion.commit)" -ForegroundColor Green
    } elseif ($localVersion.commit -and $remoteVersion.commit) {
        Write-Host "   ⚠️  Commit 不一致" -ForegroundColor Yellow
        Write-Host "      本地: $($localVersion.commit)" -ForegroundColor Yellow
        Write-Host "      服务器: $($remoteVersion.commit)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    if ($versionMatch -and ($commitMatch -or -not $localVersion.commit)) {
        Write-Host "   🎉 服务器运行的是最新版本!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  服务器可能未更新到最新版本" -ForegroundColor Yellow
        Write-Host "   💡 请在服务器上执行: git pull && make build" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "💡 使用提示:" -ForegroundColor Cyan
Write-Host "   - 对比版本: .\check-version.ps1 -Compare" -ForegroundColor Gray
Write-Host "   - 指定服务器: .\check-version.ps1 -ServerUrl http://example.com:8080" -ForegroundColor Gray
Write-Host "   - 更新版本: .\update-version.ps1" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
