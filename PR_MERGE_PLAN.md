# NoFx PR 合并执行计划

**创建时间**: 2026年1月21日  
**状态跟踪**: 🔴未开始 🟡进行中 🟢已完成 ⚠️有问题

---

## 📋 合并优先级分组

### Phase 1: 关键安全和稳定性修复 (必须合并)
**目标**: 防止系统崩溃和安全漏洞  
**预计时间**: 2-3天

| PR号 | 标题 | 优先级 | 状态 | 测试状态 | 备注 |
|-----|------|--------|------|----------|------|
| #1186 | 安全类型断言防止panic | ⭐⭐⭐⭐⭐ | 🔴 | - | 必须第一个合并 |
| #1081 | 基于审计报告的安全修复 | ⭐⭐⭐⭐⭐ | 🔴 | - | 安全关键 |
| #1114 | 使用实时价格API | ⭐⭐⭐⭐⭐ | 🔴 | - | 影响交易准确性 |
| #1319 | Solana/EVM私钥验证 | ⭐⭐⭐⭐ | 🔴 | - | 安全增强 |

### Phase 2: 数据库和回测修复 (建议合并)
**目标**: 修复回测功能和数据库问题  
**预计时间**: 1-2天

| PR号 | 标题 | 优先级 | 状态 | 测试状态 | 备注 |
|-----|------|--------|------|----------|------|
| #1313 | PostgreSQL占位符语法错误 | ⭐⭐⭐⭐ | 🔴 | - | 如使用PG则必须 |
| #1291 | 回测持仓时长计算修复 | ⭐⭐⭐⭐ | 🔴 | - | 回测功能修复 |
| #1315 | 回测验证和错误消息改进 | ⭐⭐⭐ | 🔴 | - | 用户体验提升 |

### Phase 3: 交易功能增强 (推荐合并)
**目标**: 提升交易体验和防止问题  
**预计时间**: 2-3天

| PR号 | 标题 | 优先级 | 状态 | 测试状态 | 备注 |
|-----|------|--------|------|----------|------|
| #1002 | 防止AI重复下单 | ⭐⭐⭐⭐ | 🔴 | - | 重要功能 |
| #1340 | Bitget TPSL订单修复 | ⭐⭐⭐⭐ | 🔴 | - | Bitget用户必须 |
| #1317 | OKX/Hyperliquid测试网 | ⭐⭐⭐⭐ | 🔴 | - | 便于测试 |
| #1329 | 追踪止损功能 | ⭐⭐⭐ | 🔴 | - | 新功能 |

### Phase 4: 用户体验和代码质量 (可选合并)
**目标**: 改善用户体验和代码质量  
**预计时间**: 1-2天

| PR号 | 标题 | 优先级 | 状态 | 测试状态 | 备注 |
|-----|------|--------|------|----------|------|
| #996 | 降低初始余额限制 | ⭐⭐⭐ | 🔴 | - | 降低门槛 |
| #1261 | 修复测试编译错误 | ⭐⭐⭐ | 🔴 | - | 代码质量 |
| #1294 | AI接口重试逻辑 | ⭐⭐⭐ | 🔴 | - | 稳定性提升 |
| #1187 | Go代码格式化 | ⭐⭐ | 🔴 | - | 代码规范 |

---

## 🔄 每个PR的合并流程

### 1. 准备阶段
```powershell
# 创建工作分支
git checkout -b merge-pr-{PR号}

# 备份当前状态
git tag backup-before-pr-{PR号}
```

### 2. 获取PR
```powershell
# 方式1: 使用GitHub CLI（推荐）
gh pr checkout {PR号} --repo NoFxAiOS/nofx

# 方式2: 使用fetch和cherry-pick
git fetch https://github.com/NoFxAiOS/nofx.git pull/{PR号}/head:pr-{PR号}
git checkout pr-{PR号}

# 方式3: 下载patch文件
Invoke-WebRequest -Uri "https://github.com/NoFxAiOS/nofx/pull/{PR号}.patch" -OutFile "pr-{PR号}.patch"
git apply pr-{PR号}.patch
```

### 3. 代码审查
- [ ] 阅读PR描述和讨论
- [ ] 查看文件变更：`git diff HEAD~1`
- [ ] 检查是否有冲突
- [ ] 理解代码逻辑

### 4. 本地测试
```powershell
# 后端测试
cd nofx
go mod tidy
go build -v
go test ./...

# 前端测试（如有前端变更）
cd web
npm install
npm run build
npm run test
```

### 5. 功能测试清单
- [ ] 应用启动正常
- [ ] 创建trader功能正常
- [ ] 连接交易所正常
- [ ] AI决策功能正常
- [ ] 查看日志无异常

### 6. 合并到主分支
```powershell
# 切回主分支
git checkout main

# 合并PR分支
git merge --no-ff merge-pr-{PR号} -m "Merge PR #{PR号}: {标题}"

# 推送到远程
git push origin main
```

### 7. 记录和清理
```powershell
# 更新合并日志
echo "✅ PR #{PR号} 已成功合并 - $(Get-Date)" >> PR_MERGE_LOG.txt

# 删除工作分支
git branch -d merge-pr-{PR号}
```

---

## ⚠️ 冲突解决指南

### 常见冲突类型

#### 1. 依赖冲突 (go.mod)
```powershell
# 重新整理依赖
go mod tidy
go mod verify
```

#### 2. 前端类型冲突 (.ts/.tsx)
```powershell
# 重新生成类型
npm run type-check
```

#### 3. 数据库迁移冲突
```powershell
# 检查migration文件
# 确保migration顺序正确
# 必要时手动调整
```

### 冲突处理流程
```powershell
# 1. 标记冲突文件
git status

# 2. 手动编辑解决冲突
# （编辑器中处理）

# 3. 标记为已解决
git add {冲突文件}

# 4. 继续合并
git commit -m "Resolve conflicts for PR #{PR号}"
```

---

## 📊 进度跟踪

### Phase 1 进度: 0/4 (0%)
- [ ] #1186
- [ ] #1081
- [ ] #1114
- [ ] #1319

### Phase 2 进度: 0/3 (0%)
- [ ] #1313
- [ ] #1291
- [ ] #1315

### Phase 3 进度: 0/4 (0%)
- [ ] #1002
- [ ] #1340
- [ ] #1317
- [ ] #1329

### Phase 4 进度: 0/4 (0%)
- [ ] #996
- [ ] #1261
- [ ] #1294
- [ ] #1187

---

## 📝 每日工作计划

### 第1天 (今天)
- [x] 分析PR优先级
- [ ] 设置自动化工具
- [ ] 合并 #1186 (安全类型断言)
- [ ] 测试验证

### 第2天
- [ ] 合并 #1081 (安全审计)
- [ ] 合并 #1114 (实时价格)
- [ ] 全面测试 Phase 1
- [ ] 部署到测试环境

### 第3天
- [ ] 合并 #1319 (私钥验证)
- [ ] 合并 #1313 (PostgreSQL修复)
- [ ] 测试数据库功能

### 第4天
- [ ] 合并 #1291 (回测修复)
- [ ] 合并 #1315 (回测改进)
- [ ] 测试回测功能

### 第5天
- [ ] 合并 #1002 (防重复下单)
- [ ] 合并 #1340 (Bitget修复)
- [ ] 测试交易功能

---

## 🚨 回滚计划

如果合并后出现严重问题：

```powershell
# 方式1: 回滚到标签
git reset --hard backup-before-pr-{PR号}
git push origin main --force

# 方式2: 创建回滚commit
git revert HEAD
git push origin main

# 方式3: 切换到备份分支
git checkout backup-before-merge
git branch -D main
git checkout -b main
git push origin main --force
```

---

## 📈 成功指标

- [ ] 所有Phase 1 PR成功合并
- [ ] 单元测试通过率 100%
- [ ] 手动测试无严重bug
- [ ] 生产环境稳定运行24小时
- [ ] 无用户报告的新问题

---

## 📞 遇到问题时

1. **检查上游PR讨论**: 查看其他人是否遇到相同问题
2. **查看commit历史**: 理解变更原因
3. **咨询原PR作者**: 在PR中提问
4. **暂时跳过**: 标记为"待调查"，继续下一个
5. **记录问题**: 更新此文档的问题章节

---

**最后更新**: 2026年1月21日  
**下次审查**: 每完成一个Phase后更新
