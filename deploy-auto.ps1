# 自动化部署脚本
# 功能：提交代码到远程仓库并触发服务器部署

param(
    [string]$CommitMessage = "",
    [string]$Branch = "dev",
    [switch]$SkipTests = $false,
    [switch]$AutoDeploy = $false,
    [string]$Server = "testWeb@43.134.70.26",
    [string]$ServerPath = "/home/testWeb/nofx"
)

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 错误处理函数
function Handle-Error {
    param([string]$ErrorMessage)
    Write-ColorOutput "❌ 错误: $ErrorMessage" "Red"
    exit 1
}

# 执行命令并检查结果
function Invoke-CommandSafe {
    param(
        [string]$Command,
        [string]$ErrorMessage = "命令执行失败"
    )
    
    Write-ColorOutput "执行: $Command" "Cyan"
    Invoke-Expression $Command
    
    if ($LASTEXITCODE -ne 0) {
        Handle-Error $ErrorMessage
    }
}

# 显示标题
Write-ColorOutput "`n╔════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║         🚀 NOFX 自动化部署脚本                              ║" "Cyan"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝`n" "Cyan"

# 步骤 1: 检查 Git 状态
Write-ColorOutput "📋 步骤 1/7: 检查 Git 状态" "Yellow"
git status

$hasChanges = git status --porcelain
if (-not $hasChanges) {
    Write-ColorOutput "✓ 没有需要提交的变更" "Green"
    
    $continue = Read-Host "`n是否继续执行远程部署? (y/n)"
    if ($continue -ne 'y') {
        Write-ColorOutput "操作已取消" "Yellow"
        exit 0
    }
    
    # 跳到部署步骤
    $skipCommit = $true
} else {
    $skipCommit = $false
}

if (-not $skipCommit) {
    # 步骤 2: 处理 cherry-pick（如果有）
    Write-ColorOutput "`n📋 步骤 2/7: 检查并处理 cherry-pick" "Yellow"
    $cherryPickStatus = git status | Select-String "cherry-pick"
    if ($cherryPickStatus) {
        Write-ColorOutput "检测到未完成的 cherry-pick，尝试完成..." "Yellow"
        git cherry-pick --continue 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Cherry-pick 失败，尝试中止..." "Yellow"
            git cherry-pick --abort 2>&1 | Out-Null
        }
    } else {
        Write-ColorOutput "✓ 无待处理的 cherry-pick" "Green"
    }

    # 步骤 3: 添加文件
    Write-ColorOutput "`n📋 步骤 3/7: 添加变更文件" "Yellow"
    
    # 显示待添加的文件
    Write-ColorOutput "待添加的文件:" "Cyan"
    git status --short
    
    $addAll = Read-Host "`n是否添加所有变更? (y/n)"
    if ($addAll -eq 'y') {
        Invoke-CommandSafe "git add ." "添加文件失败"
        Write-ColorOutput "✓ 已添加所有变更文件" "Green"
    } else {
        Write-ColorOutput "请手动添加文件，然后重新运行脚本" "Yellow"
        exit 0
    }

    # 步骤 4: 获取提交消息
    Write-ColorOutput "`n📋 步骤 4/7: 创建提交" "Yellow"
    
    if ($CommitMessage -eq "") {
        Write-ColorOutput "请输入提交消息类型:" "Cyan"
        Write-ColorOutput "1) feat     - 新功能" "White"
        Write-ColorOutput "2) fix      - Bug修复" "White"
        Write-ColorOutput "3) docs     - 文档更新" "White"
        Write-ColorOutput "4) refactor - 重构" "White"
        Write-ColorOutput "5) perf     - 性能优化" "White"
        Write-ColorOutput "6) test     - 测试" "White"
        Write-ColorOutput "7) chore    - 构建/工具" "White"
        Write-ColorOutput "8) style    - 代码格式" "White"
        
        $typeChoice = Read-Host "`n选择类型 (1-8)"
        
        $types = @{
            "1" = "feat"
            "2" = "fix"
            "3" = "docs"
            "4" = "refactor"
            "5" = "perf"
            "6" = "test"
            "7" = "chore"
            "8" = "style"
        }
        
        if (-not $types.ContainsKey($typeChoice)) {
            Handle-Error "无效的类型选择"
        }
        
        $type = $types[$typeChoice]
        
        $scope = Read-Host "输入范围 (如: trader, api, backtest) [可选，直接回车跳过]"
        $subject = Read-Host "输入简短描述 (50字符以内)"
        
        if ($subject -eq "") {
            Handle-Error "提交描述不能为空"
        }
        
        if ($scope -ne "") {
            $CommitMessage = "${type}(${scope}): ${subject}"
        } else {
            $CommitMessage = "${type}: ${subject}"
        }
        
        $needBody = Read-Host "`n是否添加详细描述? (y/n)"
        if ($needBody -eq 'y') {
            $body = Read-Host "输入详细描述"
            $CommitMessage = "${CommitMessage}`n`n${body}"
        }
    }
    
    Write-ColorOutput "`n提交消息:" "Cyan"
    Write-ColorOutput $CommitMessage "White"
    
    $confirmCommit = Read-Host "`n确认提交? (y/n)"
    if ($confirmCommit -ne 'y') {
        Handle-Error "用户取消提交"
    }
    
    git commit -m $CommitMessage
    if ($LASTEXITCODE -ne 0) {
        Handle-Error "提交失败"
    }
    
    Write-ColorOutput "✓ 提交成功" "Green"

    # 步骤 5: 运行测试（可选）
    if (-not $SkipTests) {
        Write-ColorOutput "`n📋 步骤 5/7: 运行测试" "Yellow"
        
        $runTests = Read-Host "是否运行测试? (y/n)"
        if ($runTests -eq 'y') {
            Write-ColorOutput "运行 Go 测试..." "Cyan"
            
            # 切换到项目目录
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            Push-Location $scriptPath
            
            go test ./... -v
            
            if ($LASTEXITCODE -ne 0) {
                Pop-Location
                Handle-Error "测试失败，请修复后再提交"
            }
            
            Pop-Location
            Write-ColorOutput "✓ 测试通过" "Green"
        } else {
            Write-ColorOutput "⚠ 跳过测试" "Yellow"
        }
    } else {
        Write-ColorOutput "`n📋 步骤 5/7: 跳过测试 (--SkipTests)" "Yellow"
    }

    # 步骤 6: 推送到远程
    Write-ColorOutput "`n📋 步骤 6/7: 推送到远程仓库" "Yellow"
    Write-ColorOutput "当前分支: $Branch" "Cyan"
    
    $confirmPush = Read-Host "是否推送到 origin/$Branch? (y/n)"
    if ($confirmPush -ne 'y') {
        Write-ColorOutput "跳过推送，已完成本地提交" "Yellow"
        exit 0
    }
    
    try {
        Write-ColorOutput "推送到 origin/$Branch..." "Cyan"
        git push origin $Branch
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "推送失败，可能需要先拉取远程变更" "Red"
            
            $pullFirst = Read-Host "是否先拉取远程变更? (y/n)"
            if ($pullFirst -eq 'y') {
                git pull origin $Branch --rebase
                
                if ($LASTEXITCODE -ne 0) {
                    Handle-Error "拉取失败，请手动解决冲突"
                }
                
                git push origin $Branch
                
                if ($LASTEXITCODE -ne 0) {
                    Handle-Error "推送仍然失败"
                }
            } else {
                Handle-Error "推送失败"
            }
        }
        
        Write-ColorOutput "✓ 推送成功!" "Green"
    } catch {
        Handle-Error "推送过程中发生错误: $_"
    }
}

# 步骤 7: 远程部署（可选）
Write-ColorOutput "`n📋 步骤 7/7: 远程服务器部署" "Yellow"

if (-not $AutoDeploy) {
    $deployNow = Read-Host "是否立即在服务器上部署? (y/n)"
    if ($deployNow -ne 'y') {
        Write-ColorOutput "`n✅ 本地操作完成！" "Green"
        Write-ColorOutput "`n如需手动部署，请执行:" "Cyan"
        Write-ColorOutput "ssh $Server" "White"
        Write-ColorOutput "cd $ServerPath" "White"
        Write-ColorOutput "./deploy-server.sh" "White"
        exit 0
    }
}

# 执行远程部署
Write-ColorOutput "`n开始远程部署..." "Yellow"
Write-ColorOutput "服务器: $Server" "Cyan"
Write-ColorOutput "路径: $ServerPath" "Cyan"

# 检查 SSH 连接
Write-ColorOutput "`n测试 SSH 连接..." "Cyan"
ssh -o ConnectTimeout=10 -o BatchMode=yes $Server "echo '连接成功'" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "⚠ SSH 连接失败，无法自动部署" "Red"
    Write-ColorOutput "请手动登录服务器执行部署:" "Yellow"
    Write-ColorOutput "ssh $Server" "White"
    Write-ColorOutput "cd $ServerPath" "White"
    Write-ColorOutput "./deploy-server.sh" "White"
    exit 1
}

Write-ColorOutput "✓ SSH 连接正常" "Green"

# 执行部署脚本
Write-ColorOutput "`n执行部署脚本..." "Cyan"

$deployCommand = @"
cd $ServerPath && \
echo '当前目录: ' && pwd && \
echo '拉取最新代码...' && \
git pull origin $Branch && \
echo '执行部署脚本...' && \
bash ./deploy-server.sh
"@

try {
    ssh $Server $deployCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "`n✅ 部署完成！" "Green"
        Write-ColorOutput "`n查看日志:" "Cyan"
        Write-ColorOutput "ssh $Server 'tail -f $ServerPath/logs/nofx.log'" "White"
    } else {
        Write-ColorOutput "`n❌ 部署过程中出现错误" "Red"
        Write-ColorOutput "请登录服务器检查日志:" "Yellow"
        Write-ColorOutput "ssh $Server" "White"
        Write-ColorOutput "cd $ServerPath" "White"
        Write-ColorOutput "cat logs/deploy.log" "White"
        exit 1
    }
} catch {
    Write-ColorOutput "`n❌ 远程部署失败: $_" "Red"
    exit 1
}

# 显示完成信息
Write-ColorOutput "`n╔════════════════════════════════════════════════════════════╗" "Green"
Write-ColorOutput "║                   ✅ 全部完成！                              ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Green"

Write-ColorOutput "`n部署信息:" "Cyan"
Write-ColorOutput "• 分支: $Branch" "White"
Write-ColorOutput "• 提交: $CommitMessage" "White"
Write-ColorOutput "• 服务器: $Server" "White"
Write-ColorOutput "• 状态: 运行中" "White"

Write-ColorOutput "`n常用命令:" "Cyan"
Write-ColorOutput "# 查看服务器日志" "White"
Write-ColorOutput "ssh $Server 'tail -f $ServerPath/logs/nofx.log'" "Gray"
Write-ColorOutput "`n# 查看服务状态" "White"
Write-ColorOutput "ssh $Server 'cd $ServerPath && docker-compose ps'" "Gray"
Write-ColorOutput "`n# 重启服务" "White"
Write-ColorOutput "ssh $Server 'cd $ServerPath && docker-compose restart'" "Gray"

Write-ColorOutput "`n" "White"
