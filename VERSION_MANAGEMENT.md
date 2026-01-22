# 版本管理使用指南

## 📋 概述

NOFX 使用基于配置文件的版本管理系统，确保每次部署都能准确验证代码版本。

## 🎯 设计目的

1. **手动控制版本号** - 每次开发后手动更新版本信息
2. **代码版本验证** - 通过版本号确认服务器运行的是最新代码
3. **问题追踪** - 解决日志代码未生效等部署问题

## 📁 文件说明

### 1. `version.json` - 版本配置文件

```json
{
  "version": "v1.0.0",
  "description": "Initial version with manual version management",
  "buildDate": "2026-01-22T00:00:00Z",
  "commit": "",
  "branch": "main",
  "features": [
    "Manual version configuration",
    "Version verification system"
  ]
}
```

### 2. `update-version.ps1` - 版本更新脚本

快速更新版本号的 PowerShell 脚本。

### 3. `version/version.go` - 版本读取模块

从 `version.json` 读取版本信息并提供给应用程序。

## 🚀 使用流程

### 步骤 1: 开发代码

正常进行开发工作。

### 步骤 2: 更新版本号

开发完成后，使用以下方式之一更新版本：

#### 方式 A: 使用脚本（推荐）

```powershell
# 交互式更新
.\update-version.ps1

# 自动递增版本号
.\update-version.ps1 -Auto

# 直接指定版本
.\update-version.ps1 -Version v1.2.0 -Description "添加新功能"

# 更新并自动提交
.\update-version.ps1 -Auto -Commit
```

#### 方式 B: 手动编辑

直接编辑 `version.json` 文件：

```json
{
  "version": "v1.0.1",
  "description": "修复日志写入问题",
  "buildDate": "2026-01-22T12:00:00Z",
  "commit": "abc1234",
  "branch": "main",
  "features": [
    "修复日志写入",
    "优化性能"
  ]
}
```

### 步骤 3: 提交到远程仓库

```bash
git add version.json
git commit -m "chore: bump version to v1.0.1"
git push
```

### 步骤 4: 服务器部署

在服务器上：

```bash
# 拉取最新代码
git pull

# 确认版本文件已更新
cat version.json

# 构建项目
go build

# 或使用 Makefile
make build
```

### 步骤 5: 验证版本

#### 方式 A: 查看启动日志

启动服务后，查看日志输出：

```
╔════════════════════════════════════════════════════════════╗
║           🚀 NOFX - AI-Powered Trading System              ║
╚════════════════════════════════════════════════════════════╝
🔖 Version: v1.0.1 | Commit: abc1234 | Branch: main | Build: 2026-01-22T12:00:00Z | Go: go1.21.0
```

#### 方式 B: 调用 API

```bash
# 查询版本信息
curl http://localhost:8080/api/version

# 或使用 jq 格式化输出
curl -s http://localhost:8080/api/version | jq
```

返回示例：

```json
{
  "version": "v1.0.1",
  "commit": "abc1234",
  "branch": "main",
  "buildDate": "2026-01-22T12:00:00Z",
  "goVersion": "go1.21.0",
  "description": "修复日志写入问题",
  "features": [
    "修复日志写入",
    "优化性能"
  ]
}
```

## 🔍 版本验证检查清单

在部署后，确认以下内容：

- [ ] 版本号与 `version.json` 一致
- [ ] 构建时间是最新的
- [ ] Commit hash 匹配（如果填写）
- [ ] 分支信息正确
- [ ] 新功能在 features 列表中

## 💡 最佳实践

### 1. 版本号规范

遵循语义化版本 (Semantic Versioning)：

- **v1.0.0 → v1.0.1** - 修复 bug (Patch)
- **v1.0.0 → v1.1.0** - 新增功能 (Minor)
- **v1.0.0 → v2.0.0** - 重大更新 (Major)

### 2. 描述信息

在 `description` 中简明扼要地说明本次更新的主要内容：

```json
{
  "description": "修复日志写入问题，优化数据库性能"
}
```

### 3. 功能列表

在 `features` 数组中列出重要变更：

```json
{
  "features": [
    "修复日志无法写入的问题",
    "优化数据库查询性能",
    "添加版本验证功能"
  ]
}
```

### 4. 提交信息

Git commit 信息应包含版本号：

```bash
git commit -m "chore: bump version to v1.0.1 - 修复日志写入问题"
```

### 5. 部署验证

每次部署后必须验证版本信息，确保：

1. 本地 `version.json` 已提交
2. 服务器已拉取最新代码
3. API 返回的版本正确
4. 启动日志显示正确版本

## 🛠️ 故障排查

### 问题 1: API 返回旧版本号

**原因**: 服务器未拉取最新代码或未重启服务

**解决**:
```bash
git pull
make build
# 重启服务
```

### 问题 2: 启动时显示 "dev" 版本

**原因**: `version.json` 文件未找到

**解决**:
```bash
# 确认文件存在
ls -l version.json

# 确认文件权限
chmod 644 version.json
```

### 问题 3: 版本号未更新

**原因**: 忘记提交 `version.json` 或忘记推送

**解决**:
```bash
# 检查 Git 状态
git status

# 如果未提交
git add version.json
git commit -m "chore: update version"

# 如果未推送
git push
```

## 📊 版本历史示例

维护一个 CHANGELOG.md 记录版本历史：

```markdown
## [v1.0.2] - 2026-01-22

### Fixed
- 修复日志写入失败的问题
- 修复 API 响应延迟

### Added
- 添加版本验证功能
- 添加版本更新脚本

## [v1.0.1] - 2026-01-21

### Changed
- 优化数据库性能
- 改进错误处理

## [v1.0.0] - 2026-01-20

### Added
- 初始版本发布
```

## 🎯 与之前的差异

### 旧方式（构建时注入）

```bash
go build -ldflags "-X nofx/version.Version=v1.2.3"
```

❌ **问题**:
- 容易忘记设置
- 不同环境可能版本不一致
- 难以追踪实际代码版本

### 新方式（配置文件）

```json
{
  "version": "v1.2.3"
}
```

✅ **优点**:
- 版本信息随代码提交
- 自动跟踪代码变更
- 便于验证和审计
- 支持更多元信息

## 📞 支持

如有问题，请查看：
- [主 README](README.md)
- [部署指南](DEPLOY_QUICKSTART.md)
- [变更日志](CHANGELOG.md)
