# Git 提交规范指导手册

## 概述

本文档定义了 NOFX 项目的 Git 工作流规范，包括提交消息格式、分支管理策略、开源/闭源版本管理等。

---

## 提交消息规范

### 基本格式

采用 **Conventional Commits** 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | feat(trader): 添加 Hyperliquid 交易所支持 |
| `fix` | Bug 修复 | fix(bitget): 修复交易对验证逻辑 |
| `docs` | 文档更新 | docs(readme): 更新部署指南 |
| `style` | 代码格式（不影响功能） | style(api): 统一错误处理格式 |
| `refactor` | 重构（不修复bug也不添加功能） | refactor(backtest): 优化回测引擎性能 |
| `perf` | 性能优化 | perf(db): 添加数据库查询缓存 |
| `test` | 添加或修改测试 | test(trader): 添加保证金模式单元测试 |
| `chore` | 构建过程或辅助工具变动 | chore(deps): 升级 gin 框架到 1.11.0 |
| `ci` | CI/CD 配置变更 | ci(docker): 优化 Docker 构建流程 |
| `revert` | 回滚之前的提交 | revert: 回滚 feat(trader): 添加... |

### Scope 范围

常用的 scope：

- `trader` - 交易所适配器
- `api` - HTTP API
- `backtest` - 回测引擎
- `llm` - AI 模型集成
- `kernel` - 核心交易引擎
- `auth` - 认证模块
- `config` - 配置管理
- `crypto` - 加密服务
- `logger` - 日志系统
- `store` - 数据持久化
- `web` - 前端
- `docker` - Docker 相关
- `docs` - 文档

### Subject 主题

- 使用祈使句，现在时态：使用 "添加" 而不是 "添加了" 或 "添加的"
- 不要大写首字母（中文可以忽略）
- 结尾不加句号
- 限制在 50 个字符以内（中文约 25 字）

### Body 正文（可选）

- 详细描述修改的内容和原因
- 可以分多行
- 每行限制在 72 个字符以内

### Footer 页脚（可选）

- **Breaking Changes**: 不兼容的变更
- **Issue 引用**: `Closes #123`, `Fixes #456`

---

## 提交示例

### 示例 1: 新功能

```
feat(trader): 添加交易对有效性检查

新增功能:
- GetAvailableSymbols() 获取所有可用交易对列表
- IsSymbolValid() 检查交易对是否被移除
- 启动时自动加载可用交易对列表

解决问题:
- 避免交易已下架的交易对（如FHEUSDT的40309错误）

Closes #123
```

### 示例 2: Bug 修复

```
fix(bitget): 修复保证金模式重复设置问题

修复内容:
- 新增 GetMarginMode() 获取当前保证金模式
- 改进 SetMarginMode() 在设置前检查当前模式
- 避免不必要的API调用

问题描述:
机器人尝试重复设置已经正确的保证金模式，导致不必要的API调用

Fixes #456
```

### 示例 3: 文档更新

```
docs(deploy): 更新快速部署指南

- 添加自动化部署脚本说明
- 更新服务器部署步骤
- 补充常见问题解决方案
```

### 示例 4: 重构

```
refactor(backtest): 优化回测引擎性能

性能优化:
- 使用 Worker Pool 管理并发
- 添加交易对数据缓存（1小时过期）
- 批量查询替代 N+1 查询

性能提升:
- 回测速度提升 3x
- 内存使用减少 40%
```

### 示例 5: 多个变更

```
chore: 项目维护更新

- feat(mcp): 添加 MCP 协议支持
- fix(api): 修复 WebSocket 连接泄漏
- docs(readme): 更新支持的交易所列表
- chore(deps): 更新依赖包
```

---

## 分支管理策略

### 开源版本（GitHub Flow）

适用于高频更新的开源项目。

#### 分支类型

```
main (稳定分支，用于发布)
  ↑
dev (开发分支，高频更新)
  ↑
feat/* (功能分支)
hotfix/* (热修复分支)
```

#### 分支命名规范

| 分支类型 | 命名格式 | 示例 |
|----------|----------|------|
| 主分支 | `main` | main |
| 开发分支 | `dev` | dev |
| 功能分支 | `feat/<描述>` | feat/add-hyperliquid-support |
| 修复分支 | `hotfix/<描述>` | hotfix/fix-api-rate-limit |
| 文档分支 | `docs/<描述>` | docs/update-deployment-guide |

#### 工作流程

1. **创建功能分支**
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feat/add-new-exchange
   ```

2. **开发和提交**
   ```bash
   # 进行开发...
   git add .
   git commit -m "feat(trader): 添加新交易所支持"
   ```

3. **推送到远程**
   ```bash
   git push origin feat/add-new-exchange
   ```

4. **创建 Pull Request**
   - 在 GitHub 上创建 PR，目标分支为 `dev`
   - 填写 PR 描述，说明变更内容
   - 等待代码审查

5. **合并到 dev**
   - PR 审查通过后，合并到 `dev` 分支
   - 删除功能分支

6. **发布到 main**
   ```bash
   # 完整测试 dev 分支后
   git checkout main
   git merge dev
   git push origin main
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

#### 完整测试频率

- 至少每周一次
- 重要功能发布后
- 紧急修复后

### 闭源版本（简化版 Git Flow）

适用于需要严格测试流程的闭源项目。

#### 分支类型

```
main (生产环境)
  ↑
test (测试环境)
  ↑
test-cp (临时测试分支)
  ↑
feat/* / hotfix/* (开发分支)
```

#### 工作流程

1. **创建开发分支**
   ```bash
   git checkout test
   git pull origin test
   git checkout -b feat/support-sql-driver
   ```

2. **开发和提交**
   ```bash
   # 进行开发...
   git add .
   git commit -m "feat(store): 添加 SQL 驱动支持"
   git push origin feat/support-sql-driver
   ```

3. **测试人员测试**
   ```bash
   # 测试人员操作
   git checkout test
   git pull origin test
   git checkout -b test-cp
   git merge feat/support-sql-driver
   # 运行测试...
   ```

4. **合并到 test**
   ```bash
   # 测试通过后
   git checkout test
   git merge feat/support-sql-driver
   git push origin test
   ```

5. **部署到测试环境**
   - 在测试服务器上拉取最新 `test` 分支
   - 运行完整测试套件

6. **发布到生产环境**
   ```bash
   # 测试环境验证通过后
   git checkout main
   git merge test
   git push origin main
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

---

## 开源与闭源版本管理

### 仓库分离策略

```
上游 (开源版本)              下游 (闭源版本)
[公有仓库]                   [私有仓库]
    |                           |
 开源核心代码 ←─────────────→ 商业版本完整代码
    |                           |
   社区贡献                     闭源功能
```

### 代码同步规则

#### 从开源到闭源

```bash
# 在闭源仓库中
git remote add upstream <开源仓库URL>
git fetch upstream
git checkout main
git merge upstream/main
# 解决冲突...
git push origin main
```

#### 从闭源到开源（谨慎操作）

```bash
# 只同步不涉及商业机密的改进
git checkout -b sync-to-opensource
# 挑选特定提交
git cherry-pick <commit-hash>
# 审查后推送到开源仓库
```

### 敏感信息处理

开源版本中需要移除的内容：

- ❌ API 密钥和凭证
- ❌ 商业策略算法
- ❌ 付费功能代码
- ❌ 内部服务器地址
- ❌ 客户数据
- ✅ 核心框架和接口
- ✅ 公共工具函数
- ✅ 示例配置（占位符）

---

## Pull Request 规范

### PR 标题

采用与提交消息相同的格式：

```
feat(trader): 添加 Bybit 交易所支持
```

### PR 描述模板

```markdown
## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 代码重构
- [ ] 性能优化
- [ ] 测试
- [ ] 其他

## 变更内容
简要描述本次 PR 的主要变更...

## 解决的问题
Closes #123
Fixes #456

## 测试
- [ ] 已添加单元测试
- [ ] 已添加集成测试
- [ ] 已在本地测试
- [ ] 已在测试环境验证

## 截图（如适用）
[添加截图]

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 已更新相关文档
- [ ] 所有测试通过
- [ ] 无冲突需要解决
- [ ] 已自我审查代码

## 备注
其他需要说明的内容...
```

### PR 审查要点

审查者应检查：

1. **代码质量**
   - 是否遵循编码规范
   - 是否有明显的 bug 或逻辑错误
   - 错误处理是否完善

2. **测试覆盖**
   - 是否添加了必要的测试
   - 测试是否覆盖了主要场景

3. **文档更新**
   - API 变更是否更新了文档
   - 是否添加了必要的注释

4. **性能影响**
   - 是否会影响系统性能
   - 是否需要性能测试

5. **安全性**
   - 是否引入了安全风险
   - 敏感数据是否正确处理

---

## 代码审查规范

### 审查流程

1. **自我审查**（提交者）
   - 提交 PR 前先自己审查一遍代码
   - 运行所有测试
   - 检查是否有调试代码残留

2. **同行审查**（审查者）
   - 通读全部变更
   - 在有问题的地方添加评论
   - 提出改进建议

3. **修改和迭代**
   - 提交者根据反馈修改
   - 标记已解决的评论
   - 重新请求审查

4. **批准和合并**
   - 至少一位审查者批准
   - 解决所有评论
   - 通过所有 CI 检查
   - 合并到目标分支

### 审查礼仪

**作为审查者：**
- ✅ 保持友好和建设性
- ✅ 解释"为什么"而不只是"改什么"
- ✅ 赞扬好的代码
- ❌ 不要人身攻击
- ❌ 不要过于苛刻

**作为提交者：**
- ✅ 保持开放心态
- ✅ 认真对待每一条反馈
- ✅ 及时回应评论
- ❌ 不要防御性回应
- ❌ 不要忽略建议

---

## 版本号规范

采用 **语义化版本 (Semantic Versioning)**：

```
MAJOR.MINOR.PATCH
```

### 版本号规则

- **MAJOR**: 不兼容的 API 变更
- **MINOR**: 向后兼容的新功能
- **PATCH**: 向后兼容的 bug 修复

### 示例

- `1.0.0` - 第一个稳定版本
- `1.1.0` - 添加新功能（向后兼容）
- `1.1.1` - 修复 bug
- `2.0.0` - 重大变更（不兼容）

### 预发布版本

- `1.0.0-alpha` - Alpha 版本
- `1.0.0-beta` - Beta 版本
- `1.0.0-rc.1` - Release Candidate

---

## 标签（Tag）管理

### 创建标签

```bash
# 创建带注释的标签
git tag -a v1.2.0 -m "Release version 1.2.0

新增功能:
- 添加 Hyperliquid 支持
- AI 辩论引擎优化

Bug 修复:
- 修复保证金模式同步问题
"

# 推送标签到远程
git push origin v1.2.0

# 推送所有标签
git push origin --tags
```

### 查看标签

```bash
# 列出所有标签
git tag

# 查看标签详情
git show v1.2.0
```

### 删除标签

```bash
# 删除本地标签
git tag -d v1.2.0

# 删除远程标签
git push origin :refs/tags/v1.2.0
```

---

## 冲突解决

### 合并冲突

```bash
# 1. 更新本地分支
git checkout dev
git pull origin dev

# 2. 合并到功能分支
git checkout feat/my-feature
git merge dev

# 3. 解决冲突
# 编辑冲突文件，查找 <<<<<<< HEAD 标记
# 保留正确的代码，删除冲突标记

# 4. 标记为已解决
git add <冲突文件>
git commit -m "merge: 解决与 dev 分支的冲突"

# 5. 推送
git push origin feat/my-feature
```

### 预防冲突

- 经常从 `dev` 拉取最新代码
- 功能分支不要存在太久
- 避免多人同时修改同一文件的同一部分
- 使用代码格式化工具保持一致性

---

## Cherry-Pick 使用

### 场景

需要将某个提交从一个分支应用到另一个分支，而不合并整个分支。

### 操作步骤

```bash
# 1. 查看要cherry-pick的提交
git log --oneline

# 2. 切换到目标分支
git checkout hotfix/urgent-fix

# 3. Cherry-pick 指定提交
git cherry-pick <commit-hash>

# 4. 解决冲突（如有）
git add <文件>
git cherry-pick --continue

# 5. 推送
git push origin hotfix/urgent-fix
```

### 中止 Cherry-Pick

```bash
git cherry-pick --abort
```

---

## 回滚操作

### 撤销最后一次提交（未推送）

```bash
# 保留修改
git reset --soft HEAD~1

# 不保留修改
git reset --hard HEAD~1
```

### 撤销已推送的提交

```bash
# 1. 创建一个新的反向提交
git revert <commit-hash>

# 2. 推送
git push origin <branch>
```

### 回滚到指定版本

```bash
# 1. 查看历史
git log --oneline

# 2. 回滚到指定提交
git reset --hard <commit-hash>

# 3. 强制推送（谨慎使用！）
git push origin <branch> --force
```

---

## Git 命令速查

### 常用命令

```bash
# 克隆仓库
git clone <url>

# 查看状态
git status

# 查看差异
git diff
git diff --staged

# 添加文件
git add <file>
git add .

# 提交
git commit -m "message"
git commit --amend  # 修改最后一次提交

# 推送
git push origin <branch>
git push --force  # 强制推送（谨慎！）

# 拉取
git pull origin <branch>
git fetch origin

# 分支操作
git branch  # 列出本地分支
git branch -a  # 列出所有分支
git checkout <branch>  # 切换分支
git checkout -b <branch>  # 创建并切换分支
git branch -d <branch>  # 删除分支

# 合并
git merge <branch>
git merge --no-ff <branch>  # 禁用快进合并

# 日志
git log
git log --oneline
git log --graph --all --decorate

# 存储临时修改
git stash
git stash pop
git stash list

# 标签
git tag
git tag -a <tag> -m "message"
git push origin <tag>
```

---

## 自动化工具

### 提交消息验证

使用 `commitlint` 验证提交消息格式：

```bash
# 安装
npm install --save-dev @commitlint/cli @commitlint/config-conventional

# 配置 .commitlintrc.json
{
  "extends": ["@commitlint/config-conventional"]
}

# Git hook
# .husky/commit-msg
npx --no-install commitlint --edit $1
```

### 代码格式化

提交前自动格式化代码：

```bash
# Go 代码
gofmt -w .
go vet ./...

# TypeScript/JavaScript
npm run lint
npm run format
```

---

## 最佳实践总结

### ✅ 应该做的

1. **频繁提交**：小步提交，每个提交完成一个小功能
2. **清晰的消息**：提交消息要清晰描述变更内容
3. **定期同步**：经常从主分支拉取最新代码
4. **测试后提交**：确保代码通过测试再提交
5. **及时审查**：尽快审查和回应 PR
6. **保护主分支**：通过 PR 合并，不直接推送到 main
7. **使用分支**：为每个功能/修复创建独立分支

### ❌ 不应该做的

1. **大型提交**：避免一次性提交大量变更
2. **模糊消息**：如 "修复bug", "更新代码"
3. **直接推送到主分支**：绕过审查流程
4. **提交敏感信息**：API 密钥、密码等
5. **忽略冲突**：随意解决冲突可能导致代码丢失
6. **功能分支存在太久**：容易产生大量冲突
7. **强制推送共享分支**：会覆盖他人的工作

---

## 相关文档

- [GitHub Copilot 开发指导](copilot-instructions.md)
- [项目 README](../README.md)
- [部署指南](../DEPLOY_QUICKSTART.md)
- [Git 工作流规范](../docs/Git工作流规范.md)

---

## 联系方式

如有疑问，请联系：
- **官方 Twitter**: [@nofx_official](https://x.com/nofx_official)
- **开发者社区**: [Telegram](https://t.me/nofx_dev_community)

---

**最后更新**: 2026-01-22
