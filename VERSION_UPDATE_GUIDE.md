# 版本更新工具使用说明

## 问题说明

由于 PowerShell 的编码问题，含有中文字符的脚本可能会报错。因此推荐使用以下方案：

## ✅ 推荐方案：使用英文版脚本

### 方法 1: 自动递增（最简单）

```powershell
.\update-version.ps1 -Auto
```

然后按提示选择：
- 输入 `1` - Patch 版本 (v1.0.0 → v1.0.1) 用于修复bug
- 输入 `2` - Minor 版本 (v1.0.0 → v1.1.0) 用于新功能
- 输入 `3` - Major 版本 (v1.0.0 → v2.0.0) 用于重大更新

### 方法 2: 指定版本号

```powershell
.\update-version.ps1 -Version "v1.0.3" -Description "修复日志问题"
```

### 方法 3: 自动提交到 Git

```powershell
.\update-version.ps1 -Auto -Commit
```

## 🔧 备选方案：使用简化版脚本

如果你想要更简单的菜单式操作：

```powershell
.\update-version-simple.ps1
```

然后按照提示选择选项即可。

## 📝 常用示例

### 示例 1: 修复 bug，递增 patch 版本
```powershell
.\update-version.ps1 -Auto
# 选择 1
# 输入描述: 修复日志写入问题
```

### 示例 2: 添加新功能，递增 minor 版本
```powershell
.\update-version.ps1 -Auto
# 选择 2
# 输入描述: 添加版本显示页面
```

### 示例 3: 直接指定版本号
```powershell
.\update-version.ps1 -Version "v1.2.0" -Description "添加新的交易策略"
```

### 示例 4: 更新版本并自动提交
```powershell
.\update-version.ps1 -Version "v1.0.5" -Description "性能优化" -Commit
```

## 🎯 验证版本更新

### 查看版本文件
```powershell
Get-Content version.json
```

### 查看格式化的版本信息
```powershell
Get-Content version.json | ConvertFrom-Json | ConvertTo-Json
```

### 启动服务查看日志
```bash
go run main.go
# 应显示: 🔖 Version: v1.0.x | Commit: ...
```

### 测试 API
```bash
curl http://localhost:8080/api/version
```

### 前端验证
```
打开浏览器: http://localhost:8080/version
检查显示的版本号是否正确
```

## ⚠️ 注意事项

1. **不要使用 `update-version-zh.ps1`** - 该文件有编码问题
2. **使用 `update-version.ps1`（英文版）** - 这是稳定可用的版本
3. **或使用 `update-version-simple.ps1`** - 简化的菜单版本

## 📋 完整工作流程

```powershell
# 1. 更新版本
.\update-version.ps1 -Auto

# 2. 提交到 Git
git add version.json
git commit -m "chore: bump version to v1.0.x"
git push

# 3. 在服务器上部署
git pull
go build

# 4. 验证版本
curl http://localhost:8080/api/version
```

## 🚀 快捷命令

创建一个别名方便使用：

```powershell
# 添加到 PowerShell Profile
Set-Alias uv ".\update-version.ps1"

# 然后就可以使用
uv -Auto
```

## 💡 提示

- 每次开发完成后记得更新版本
- 版本描述要清晰说明改动内容
- 更新后验证版本号是否正确
- 定期查看 version.json 确保信息准确

## 🔍 故障排查

### 问题：脚本报编码错误
**解决**：使用 `update-version.ps1`（英文版）而不是中文版

### 问题：无法执行脚本
**解决**：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题：Git 信息获取失败
**解决**：确保在 Git 仓库目录中执行，或忽略此警告

### 问题：版本号格式错误
**解决**：使用 `vX.Y.Z` 格式，例如 `v1.0.1`
