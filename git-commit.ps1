# Git 提交和推送脚本

# 1. 完成cherry-pick或取消
Write-Host "完成cherry-pick..." -ForegroundColor Yellow
git cherry-pick --continue
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cherry-pick失败，尝试中止..." -ForegroundColor Yellow
    git cherry-pick --abort
}

# 2. 查看当前状态
Write-Host "`n当前Git状态:" -ForegroundColor Cyan
git status

# 3. 添加所有修改
Write-Host "`n添加修改的文件..." -ForegroundColor Yellow
git add trader/bitget_trader.go
git add mcp/client.go  
git add FIXES_2026-01-21.md
git add deploy-guide.md

# 4. 提交修改
Write-Host "`n提交修改..." -ForegroundColor Yellow
$commitMsg = @"
fix: 添加交易对有效性检查和保证金模式同步

修复内容:
- 新增 GetAvailableSymbols() 获取所有可用交易对列表
- 新增 IsSymbolValid() 检查交易对是否被移除
- 新增 GetMarginMode() 获取当前保证金模式
- 改进 SetMarginMode() 在设置前检查当前模式，避免重复API调用
- 在 OpenLong/OpenShort/SetLeverage 前验证交易对有效性
- 修复 mcp/client.go 语法错误（重复的花括号）

解决问题:
- 避免交易已移除的交易对（如FHEUSDT的40309错误）
- 确保机器人配置的保证金模式与交易所一致
- 启动时自动加载可用交易对列表
- 减少不必要的API调用
"@

git commit -m $commitMsg

# 5. 推送到远程
Write-Host "`n推送到远程仓库..." -ForegroundColor Yellow
Write-Host "当前分支: dev" -ForegroundColor Cyan
$confirm = Read-Host "是否推送到 origin/dev? (y/n)"
if ($confirm -eq 'y') {
    git push origin dev
    Write-Host "`n✓ 推送成功!" -ForegroundColor Green
} else {
    Write-Host "`n已取消推送" -ForegroundColor Yellow
}

Write-Host "`n完成! 接下来请到服务器执行以下命令:" -ForegroundColor Green
Write-Host "ssh testWeb@43.134.70.26" -ForegroundColor Cyan
Write-Host "cd /home/testWeb/nofx" -ForegroundColor Cyan
Write-Host "git pull origin dev" -ForegroundColor Cyan
Write-Host "go build -o nofx main.go" -ForegroundColor Cyan
Write-Host "./stop.sh && nohup ./nofx > nohup.out 2>&1 &" -ForegroundColor Cyan
