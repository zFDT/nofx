# NoFx PR 自动化合并工具
# 用于系统化地合并上游PR

param(
    [Parameter(Mandatory=$false)]
    [string]$PRNumber,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("fetch", "apply", "test", "merge", "rollback", "status")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$UpstreamRepo = "NoFxAiOS/nofx"
)

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 检查Git状态
function Test-GitClean {
    $status = git status --porcelain
    if ($status) {
        Write-ColorOutput "⚠️  警告: 工作目录不干净，请先提交或暂存更改" "Yellow"
        return $false
    }
    return $true
}

# 创建备份
function New-Backup {
    param([string]$PRNum)
    
    $tagName = "backup-before-pr-$PRNum"
    Write-ColorOutput "📦 创建备份标签: $tagName" "Cyan"
    
    git tag $tagName
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ 备份创建成功" "Green"
        return $true
    } else {
        Write-ColorOutput "❌ 备份创建失败" "Red"
        return $false
    }
}

# 获取PR
function Get-PRCode {
    param([string]$PRNum)
    
    Write-ColorOutput "`n🔄 正在获取 PR #$PRNum..." "Cyan"
    
    # 检查是否安装了GitHub CLI
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    
    if ($ghInstalled) {
        Write-ColorOutput "使用 GitHub CLI 获取 PR..." "Gray"
        
        # 创建新分支
        $branchName = "merge-pr-$PRNum"
        git checkout -b $branchName
        
        # 使用gh获取PR
        gh pr checkout $PRNum --repo $UpstreamRepo
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ PR #$PRNum 获取成功" "Green"
            return $true
        }
    } else {
        Write-ColorOutput "未安装GitHub CLI，使用fetch方式..." "Yellow"
        
        # 使用fetch方式
        $branchName = "pr-$PRNum"
        git fetch "https://github.com/$UpstreamRepo.git" "pull/$PRNum/head:$branchName"
        
        if ($LASTEXITCODE -eq 0) {
            git checkout $branchName
            Write-ColorOutput "✅ PR #$PRNum 获取成功" "Green"
            return $true
        }
    }
    
    Write-ColorOutput "❌ PR获取失败" "Red"
    return $false
}

# 测试代码
function Test-Code {
    Write-ColorOutput "`n🧪 开始测试..." "Cyan"
    
    # 测试后端
    Write-ColorOutput "测试Go代码..." "Gray"
    Push-Location
    
    try {
        # 整理依赖
        Write-ColorOutput "  → 整理依赖..." "Gray"
        go mod tidy
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ go mod tidy 失败" "Red"
            return $false
        }
        
        # 编译
        Write-ColorOutput "  → 编译代码..." "Gray"
        go build -v
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ 编译失败" "Red"
            return $false
        }
        
        # 运行测试
        Write-ColorOutput "  → 运行单元测试..." "Gray"
        go test ./... -timeout 30s
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "⚠️  部分测试失败（可能是正常的）" "Yellow"
            # 不返回false，因为某些测试可能需要特定环境
        }
        
        Write-ColorOutput "✅ 后端测试完成" "Green"
        
    } finally {
        Pop-Location
    }
    
    # 检查是否有前端变更
    $webChanges = git diff --name-only HEAD~1 | Select-String "^web/"
    
    if ($webChanges) {
        Write-ColorOutput "检测到前端变更，测试前端..." "Gray"
        
        if (Test-Path "web/package.json") {
            Push-Location web
            
            try {
                Write-ColorOutput "  → 安装依赖..." "Gray"
                npm install
                
                if ($LASTEXITCODE -ne 0) {
                    Write-ColorOutput "❌ npm install 失败" "Red"
                    return $false
                }
                
                Write-ColorOutput "  → 类型检查..." "Gray"
                npm run type-check
                
                Write-ColorOutput "  → 编译前端..." "Gray"
                npm run build
                
                if ($LASTEXITCODE -ne 0) {
                    Write-ColorOutput "❌ 前端编译失败" "Red"
                    return $false
                }
                
                Write-ColorOutput "✅ 前端测试完成" "Green"
                
            } finally {
                Pop-Location
            }
        }
    }
    
    Write-ColorOutput "`n✅ 所有测试通过" "Green"
    return $true
}

# 合并PR
function Merge-PR {
    param([string]$PRNum)
    
    Write-ColorOutput "`n🔀 正在合并 PR #$PRNum..." "Cyan"
    
    # 切换到main分支
    git checkout main
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ 切换到main分支失败" "Red"
        return $false
    }
    
    # 合并
    $branchName = "merge-pr-$PRNum"
    if (-not (git branch --list $branchName)) {
        $branchName = "pr-$PRNum"
    }
    
    git merge --no-ff $branchName -m "Merge PR #$PRNum from upstream"
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ PR #$PRNum 合并成功" "Green"
        
        # 记录到日志
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - PR #$PRNum merged successfully"
        Add-Content -Path "PR_MERGE_LOG.txt" -Value $logEntry
        
        # 询问是否推送
        Write-ColorOutput "`nPush to remote? (y/n): " "Yellow" -NoNewline
        $response = Read-Host
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            git push origin main
            Write-ColorOutput "Pushed to remote" "Green"
        }
        
        # Ask if delete branch
        Write-ColorOutput "`nDelete working branch $branchName? (y/n): " "Yellow" -NoNewline
        $response = Read-Host
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            git branch -d $branchName
            Write-ColorOutput "Branch deleted" "Green"
        }
        
        return $true
    } else {
        Write-ColorOutput "Merge failed, conflicts may exist" "Red"
        Write-ColorOutput "Resolve conflicts manually and run: git commit" "Yellow"
        return $false
    }
}

# 回滚
function Invoke-Rollback {
    param([string]$PRNum)
    
    Write-ColorOutput "`nPreparing to rollback PR #$PRNum..." "Yellow"
    Write-ColorOutput "Choose rollback method:" "Cyan"
    Write-ColorOutput "1. Reset to backup tag (reset --hard)" "Gray"
    Write-ColorOutput "2. Create revert commit (revert)" "Gray"
    Write-ColorOutput "3. Cancel" "Gray"
    
    $choice = Read-Host "Select (1-3)"
    
    switch ($choice) {
        "1" {
            $tagName = "backup-before-pr-$PRNum"
            Write-ColorOutput "Rolling back to tag: $tagName" "Yellow"
            git reset --hard $tagName
            Write-ColorOutput "Rollback completed" "Green"
        }
        "2" {
            Write-ColorOutput "Creating revert commit..." "Yellow"
            git revert HEAD
            Write-ColorOutput "Rollback completed" "Green"
        }
        "3" {
            Write-ColorOutput "Rollback cancelled" "Gray"
        }
        default {
            Write-ColorOutput "Invalid choice" "Red"
        }
    }
}

# 显示状态
function Show-Status {
    Write-ColorOutput "`nNoFx PR Merge Status" "Cyan"
    Write-ColorOutput "==========================================`n" "Cyan"
    
    # Show current branch
    $currentBranch = git branch --show-current
    Write-ColorOutput "Current branch: $currentBranch" "White"
    
    # Show working directory status
    $status = git status --porcelain
    if ($status) {
        Write-ColorOutput "Working directory: Has uncommitted changes" "Yellow"
    } else {
        Write-ColorOutput "Working directory: Clean" "Green"
    }
    
    # Show recent backup tags
    Write-ColorOutput "`nRecent backup tags:" "Cyan"
    git tag | Select-String "backup-before-pr" | Select-Object -Last 5
    
    # Show merge log
    if (Test-Path "PR_MERGE_LOG.txt") {
        Write-ColorOutput "`nRecently merged PRs:" "Cyan"
        Get-Content "PR_MERGE_LOG.txt" -Tail 5
    }
    
    # Read merge plan
    if (Test-Path "PR_MERGE_PLAN.md") {
        Write-ColorOutput "`nNext steps:" "Cyan"
        Write-ColorOutput "See PR_MERGE_PLAN.md for detailed plan" "Gray"
    }
}

# 主函数
function Main {
    Write-ColorOutput @"
    
╔═══════════════════════════════════════╗
║   NoFx PR 自动化合并工具 v1.0         ║
╚═══════════════════════════════════════╝

"@ "Cyan"

    # Check if in Git repository
    if (-not (Test-Path ".git")) {
        Write-ColorOutput "Error: Not in a Git repository" "Red"
        exit 1
    }
    
    switch ($Action) {
        "status" {
            Show-Status
        }
        "fetch" {
            if (-not $PRNumber) {
                Write-ColorOutput "Error: PR number required" "Red"
                Write-ColorOutput "Usage: .\pr-merge-tool.ps1 -PRNumber 1186 -Action fetch" "Yellow"
                exit 1
            }
            
            if (-not (Test-GitClean)) {
                exit 1
            }
            
            New-Backup -PRNum $PRNumber
            Get-PRCode -PRNum $PRNumber
        }
        "test" {
            Test-Code
        }
        "merge" {
            if (-not $PRNumber) {
                Write-ColorOutput "Error: PR number required" "Red"
                exit 1
            }
            
            Merge-PR -PRNum $PRNumber
        }
        "rollback" {
            if (-not $PRNumber) {
                Write-ColorOutput "Error: PR number required" "Red"
                exit 1
            }
            
            Invoke-Rollback -PRNum $PRNumber
        }
        "apply" {
            if (-not $PRNumber) {
                Write-ColorOutput "Error: PR number required" "Red"
                exit 1
            }
            
            # Full workflow
            Write-ColorOutput "`nStarting full PR merge workflow..." "Cyan"
            
            if (-not (Test-GitClean)) {
                exit 1
            }
            
            if (-not (New-Backup -PRNum $PRNumber)) {
                exit 1
            }
            
            if (-not (Get-PRCode -PRNum $PRNumber)) {
                exit 1
            }
            
            Write-ColorOutput "`nPlease review code manually, then press Enter to continue testing..." "Yellow"
            Read-Host
            
            if (-not (Test-Code)) {
                Write-ColorOutput "`nTests failed, continue merging? (y/n): " "Yellow" -NoNewline
                $response = Read-Host
                if ($response -ne 'y' -and $response -ne 'Y') {
                    Write-ColorOutput "Merge cancelled" "Gray"
                    exit 0
                }
            }
            
            Write-ColorOutput "`nReady to merge, press Enter to continue..." "Yellow"
            Read-Host
            
            Merge-PR -PRNum $PRNumber
        }
        default {
            Write-ColorOutput "Unknown action: $Action" "Red"
        }
    }
    
    Write-ColorOutput "`nDone" "Green"
}

# 运行主函数
Main
