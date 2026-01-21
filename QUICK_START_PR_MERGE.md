# NoFx PR 合并快速指南

这是一个快速参考指南，帮助你高效地合并上游PR。

## 📦 工具文件说明

- **PR_MERGE_PLAN.md**: 详细的合并计划和进度跟踪
- **pr-merge-tool.ps1**: 自动化合并工具（PowerShell）
- **nofx-pr-analysis.md**: PR详细分析报告
- **PR_MERGE_LOG.txt**: 合并历史记录（自动生成）

## 🚀 快速开始

### 1. 查看当前状态
```powershell
.\pr-merge-tool.ps1 -Action status
```

### 2. 合并单个PR（推荐流程）

#### 方式A: 自动化完整流程
```powershell
# 一键完成：备份 → 获取 → 测试 → 合并
.\pr-merge-tool.ps1 -PRNumber 1186 -Action apply
```

#### 方式B: 分步执行（更安全）
```powershell
# 步骤1: 获取PR代码
.\pr-merge-tool.ps1 -PRNumber 1186 -Action fetch

# 步骤2: 手动审查代码
git diff HEAD~1

# 步骤3: 测试代码
.\pr-merge-tool.ps1 -Action test

# 步骤4: 如果测试通过，合并
.\pr-merge-tool.ps1 -PRNumber 1186 -Action merge
```

### 3. 如果出现问题，回滚
```powershell
.\pr-merge-tool.ps1 -PRNumber 1186 -Action rollback
```

## 📋 推荐合并顺序

按照优先级，建议按以下顺序合并：

### 第一批（关键安全修复）
```powershell
# 1. 安全类型断言 - 最重要！
.\pr-merge-tool.ps1 -PRNumber 1186 -Action apply

# 2. 安全审计修复
.\pr-merge-tool.ps1 -PRNumber 1081 -Action apply

# 3. 实时价格API
.\pr-merge-tool.ps1 -PRNumber 1114 -Action apply

# 4. 私钥验证
.\pr-merge-tool.ps1 -PRNumber 1319 -Action apply
```

### 第二批（数据库和回测）
```powershell
# 5. PostgreSQL修复
.\pr-merge-tool.ps1 -PRNumber 1313 -Action apply

# 6. 回测持仓时长
.\pr-merge-tool.ps1 -PRNumber 1291 -Action apply

# 7. 回测验证改进
.\pr-merge-tool.ps1 -PRNumber 1315 -Action apply
```

### 第三批（交易功能）
```powershell
# 8. 防止重复下单
.\pr-merge-tool.ps1 -PRNumber 1002 -Action apply

# 9. Bitget TPSL修复
.\pr-merge-tool.ps1 -PRNumber 1340 -Action apply

# 10. 测试网支持
.\pr-merge-tool.ps1 -PRNumber 1317 -Action apply
```

## ⚠️ 注意事项

### 合并前必做
- [x] 备份当前代码（工具自动完成）
- [x] 确保工作目录干净（无未提交更改）
- [ ] 阅读PR描述和讨论
- [ ] 理解代码变更内容

### 合并后必做
- [ ] 运行完整测试套件
- [ ] 手动测试关键功能
- [ ] 检查日志无异常
- [ ] 在测试环境验证
- [ ] 更新PR_MERGE_PLAN.md中的进度

### 如果遇到冲突
```powershell
# 1. 查看冲突文件
git status

# 2. 手动编辑解决冲突
# （使用VS Code打开冲突文件）

# 3. 标记为已解决
git add .

# 4. 完成合并
git commit -m "Resolve conflicts for PR #xxxx"
```

## 🧪 测试清单

每次合并后都应该测试：

### 后端测试
- [ ] `go build` 编译成功
- [ ] `go test ./...` 测试通过
- [ ] 应用能正常启动

### 前端测试（如有变更）
- [ ] `npm run build` 编译成功
- [ ] `npm run type-check` 类型检查通过
- [ ] UI界面正常显示

### 功能测试
- [ ] 创建新的trader
- [ ] 连接到交易所
- [ ] AI决策正常工作
- [ ] 查看交易历史
- [ ] 查看日志无错误

## 📊 跟踪进度

### 查看合并历史
```powershell
# 查看已合并的PR
cat PR_MERGE_LOG.txt

# 查看备份标签
git tag | Select-String "backup"

# 查看当前分支
git branch
```

### 更新计划文档
编辑 PR_MERGE_PLAN.md，将已完成的PR标记为 🟢：

```markdown
| PR号 | 标题 | 状态 | 测试状态 |
|-----|------|------|----------|
| #1186 | 安全类型断言 | 🟢 | ✅ 通过 |
```

## 🆘 故障排除

### 问题1: 获取PR失败
```powershell
# 检查网络连接
Test-NetConnection github.com

# 尝试手动下载patch
Invoke-WebRequest -Uri "https://github.com/NoFxAiOS/nofx/pull/1186.patch" -OutFile "1186.patch"
git apply 1186.patch
```

### 问题2: 测试失败
```powershell
# 清理并重新构建
go clean -cache
go mod tidy
go build

# 查看详细错误
go test -v ./...
```

### 问题3: 合并冲突
```powershell
# 取消合并
git merge --abort

# 查看冲突原因
git diff

# 手动处理或寻求帮助
```

### 问题4: 合并后出现bug
```powershell
# 立即回滚
.\pr-merge-tool.ps1 -PRNumber xxxx -Action rollback

# 或手动回滚
git reset --hard backup-before-pr-xxxx
```

## 💡 最佳实践

1. **一次合并一个PR**: 不要同时合并多个PR
2. **充分测试**: 每个PR合并后都要完整测试
3. **保持备份**: 不要删除备份标签
4. **记录问题**: 遇到问题及时记录
5. **分批部署**: Phase 1完成后再开始Phase 2
6. **定期推送**: 不要积累太多本地commit

## 📅 时间规划

- **每天合并**: 1-2个PR
- **测试时间**: 每个PR预留30-60分钟
- **完成Phase 1**: 预计2-3天
- **完成所有PR**: 预计1-2周

## 🎯 成功标准

- ✅ 所有高优先级PR已合并
- ✅ 测试通过率100%
- ✅ 无新增bug
- ✅ 生产环境稳定运行
- ✅ 文档已更新

---

**开始合并吧！祝顺利！** 🚀
