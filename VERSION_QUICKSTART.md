# 快速开始：版本管理

## 更新版本

每次开发完成后，更新版本号：

```powershell
# Windows
.\update-version.ps1 -Auto

# Linux/Mac
chmod +x update-version.sh
./update-version.sh
```

## 提交代码

```bash
git add version.json
git commit -m "chore: bump version to v1.0.1"
git push
```

## 服务器部署

```bash
# 拉取最新代码
git pull

# 确认版本已更新
cat version.json

# 构建项目
make build

# 重启服务
systemctl restart nofx  # 或使用你的服务管理方式
```

## 验证版本

### 方法 1: 查看启动日志

```
🔖 Version: v1.0.1 | Commit: abc1234 | Branch: main | Build: 2026-01-22T12:00:00Z
```

### 方法 2: 调用 API

```bash
curl http://localhost:8080/api/version | jq
```

### 方法 3: 使用检查脚本

```powershell
# 检查本地和服务器版本
.\check-version.ps1 -Compare

# 检查远程服务器
.\check-version.ps1 -ServerUrl http://your-server:8080 -Compare
```

## 版本号规范

- `v1.0.0 → v1.0.1` - Bug 修复
- `v1.0.0 → v1.1.0` - 新功能
- `v1.0.0 → v2.0.0` - 重大更新

详细说明请查看 [VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md)
