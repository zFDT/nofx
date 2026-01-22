# 版本更新脚本
# 用于快速更新 version.json 文件

param(
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main",
    
    [Parameter(Mandatory=$false)]
    [switch]$Auto,
    
    [Parameter(Mandatory=$false)]
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$versionFile = "version.json"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           🔖 NOFX 版本更新工具                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查 version.json 是否存在
if (-not (Test-Path $versionFile)) {
    Write-Host "❌ 错误: 找不到 $versionFile 文件" -ForegroundColor Red
    exit 1
}

# 读取当前版本信息
$currentVersion = Get-Content $versionFile | ConvertFrom-Json
Write-Host "📋 当前版本信息:" -ForegroundColor Yellow
Write-Host "   版本: $($currentVersion.version)" -ForegroundColor Gray
Write-Host "   描述: $($currentVersion.description)" -ForegroundColor Gray
Write-Host "   日期: $($currentVersion.buildDate)" -ForegroundColor Gray
Write-Host ""

# 如果使用 -Auto 参数，自动递增版本号
if ($Auto) {
    $versionParts = $currentVersion.version -replace '^v', '' -split '\.'
    if ($versionParts.Count -eq 3) {
        $major = [int]$versionParts[0]
        $minor = [int]$versionParts[1]
        $patch = [int]$versionParts[2]
        
        Write-Host "🔢 选择版本递增类型:" -ForegroundColor Cyan
        Write-Host "   1. Patch (v$major.$minor.$($patch+1)) - 修复bug"
        Write-Host "   2. Minor (v$major.$($minor+1).0) - 新功能"
        Write-Host "   3. Major (v$($major+1).0.0) - 重大更新"
        
        $choice = Read-Host "请选择 (1-3, 默认: 1)"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
        
        switch ($choice) {
            "1" { $Version = "v$major.$minor.$($patch+1)" }
            "2" { $Version = "v$major.$($minor+1).0" }
            "3" { $Version = "v$($major+1).0.0" }
            default { $Version = "v$major.$minor.$($patch+1)" }
        }
        
        Write-Host "✅ 自动版本号: $Version" -ForegroundColor Green
    }
}

# 交互式输入版本号
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Read-Host "请输入新版本号 (例如: v1.0.1, 留空保持不变)"
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = $currentVersion.version
    }
}

# 确保版本号以 v 开头
if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    if ($Version -match '^\d+\.\d+\.\d+$') {
        $Version = "v$Version"
    } else {
        Write-Host "⚠️  警告: 版本号格式不标准，建议使用 vX.Y.Z 格式" -ForegroundColor Yellow
    }
}

# 交互式输入描述
if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = Read-Host "请输入版本描述 (留空保持不变)"
    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Description = $currentVersion.description
    }
}

# 获取 Git 信息
$gitCommit = ""
$gitBranch = $Branch
try {
    $gitCommit = (git rev-parse --short HEAD 2>$null)
    $gitBranch = (git rev-parse --abbrev-ref HEAD 2>$null)
    if ([string]::IsNullOrWhiteSpace($gitBranch)) {
        $gitBranch = $Branch
    }
} catch {
    Write-Host "⚠️  警告: 无法获取 Git 信息" -ForegroundColor Yellow
}

# 构建新的版本信息
$buildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$newVersion = @{
    version = $Version
    description = $Description
    buildDate = $buildDate
    commit = $gitCommit
    branch = $gitBranch
    features = $currentVersion.features
}

# 显示新版本信息
Write-Host ""
Write-Host "📝 新版本信息:" -ForegroundColor Cyan
Write-Host "   版本: $Version" -ForegroundColor Green
Write-Host "   描述: $Description" -ForegroundColor Green
Write-Host "   日期: $buildDate" -ForegroundColor Green
Write-Host "   提交: $gitCommit" -ForegroundColor Green
Write-Host "   分支: $gitBranch" -ForegroundColor Green
Write-Host ""

# 确认更新
$confirm = Read-Host "确认更新版本信息? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "❌ 已取消更新" -ForegroundColor Yellow
    exit 0
}

# 写入文件
try {
    $newVersion | ConvertTo-Json -Depth 10 | Set-Content $versionFile -Encoding UTF8
    Write-Host "✅ 版本信息已更新到 $versionFile" -ForegroundColor Green
} catch {
    Write-Host "❌ 错误: 无法写入文件 - $_" -ForegroundColor Red
    exit 1
}

# 如果指定了 -Commit 参数，自动提交到 Git
if ($Commit) {
    Write-Host ""
    Write-Host "📦 提交到 Git..." -ForegroundColor Cyan
    
    try {
        git add $versionFile
        git commit -m "chore: bump version to $Version"
        Write-Host "✅ 已提交到 Git" -ForegroundColor Green
        
        $push = Read-Host "是否推送到远程仓库? (y/N)"
        if ($push -eq "y" -or $push -eq "Y") {
            git push
            Write-Host "✅ 已推送到远程仓库" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  警告: Git 操作失败 - $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 完成! 版本已更新为 $Version" -ForegroundColor Green
Write-Host ""
Write-Host "💡 提示:" -ForegroundColor Cyan
Write-Host "   - 构建项目: go build" -ForegroundColor Gray
Write-Host "   - 验证版本: curl http://localhost:8080/api/version" -ForegroundColor Gray
Write-Host "   - 查看日志: 启动后会显示版本信息" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
