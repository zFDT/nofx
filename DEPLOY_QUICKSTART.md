# 🚀 快速部署指南

## 修复内容概述

本次修复解决了两个关键问题：

### ✅ 问题1: 交易对被移除错误 (40309)
- **症状**: FHEUSDT等交易对报错 `code=40309, msg=The symbol has been removed`
- **原因**: Bitget已将该交易对下架，但系统仍尝试交易
- **解决**: 
  - 启动时加载所有可用交易对列表（约150个）
  - 开仓前验证交易对是否有效
  - 对无效交易对返回清晰的错误信息

### ✅ 问题2: 保证金模式不一致
- **症状**: 机器人配置的全仓/逐仓与交易所不一致
- **原因**: 未检查当前设置就尝试修改
- **解决**:
  - 获取当前保证金模式
  - 只在不一致时才修改
  - 减少不必要的API调用

---

## 📋 部署步骤（3分钟）

### 方式1: 使用脚本自动部署 ⭐推荐

#### 步骤1: 本地提交（Windows）

```powershell
cd "d:\新建文件夹 (3)\web\nofx"
.\git-commit.ps1
```

按提示输入 `y` 推送到远程仓库。

#### 步骤2: 服务器部署

```bash
# SSH连接到服务器
ssh testWeb@43.134.70.26

# 下载并执行部署脚本
cd /home/testWeb/nofx
chmod +x deploy-server.sh
./deploy-server.sh
```

**完成！** 脚本会自动：
- 备份当前程序
- 停止旧服务
- 拉取最新代码
- 编译新程序
- 启动新服务
- 显示日志

---

### 方式2: 手动部署

#### 步骤1: 本地提交代码

```powershell
cd "d:\新建文件夹 (3)\web\nofx"

# 取消cherry-pick（如果有）
git cherry-pick --abort

# 添加修改
git add trader/bitget_trader.go mcp/client.go FIXES_2026-01-21.md deploy-guide.md

# 提交
git commit -m "fix: 添加交易对有效性检查和保证金模式同步"

# 推送
git push origin dev
```

#### 步骤2: 服务器更新

```bash
ssh testWeb@43.134.70.26
cd /home/testWeb/nofx

# 备份
cp nofx nofx.backup.$(date +%Y%m%d_%H%M%S)

# 停止服务
ps aux | grep nofx
kill <进程ID>

# 拉取代码
git pull origin dev

# 编译
export GOPROXY=https://goproxy.cn,direct
go build -o nofx main.go

# 启动
nohup ./nofx > nohup.out 2>&1 &

# 查看日志
tail -f nohup.out
```

---

## 🔍 验证修复效果

### 1. 检查交易对加载

```bash
# 应该看到类似输出
tail -50 nohup.out | grep "available symbols"
```

期望输出：
```
✓ [Bitget] Loaded 150 available symbols
```

### 2. 检查40309错误

```bash
# 查看今天的日志
grep "40309\|FHEUSDT" data/nofx_$(date +%Y-%m-%d).log | tail -5
```

**修复前**（会看到）：
```
❌ failed to open long position: Bitget API error: code=40309
```

**修复后**（应该看到）：
```
❌ symbol FHEUSDT has been removed or is invalid, cannot open position
```

### 3. 检查保证金模式

```bash
# 查看保证金模式日志
grep "margin mode" data/nofx_$(date +%Y-%m-%d).log | tail -10
```

应该看到：
```
✓ BTCUSDT margin mode is already crossed, no change needed
🔄 ETHUSDT margin mode: crossed → isolated
```

---

## 📊 关键改进

| 功能 | 修复前 | 修复后 |
|------|--------|--------|
| 交易对检查 | ❌ 无检查 | ✅ 开仓前验证 |
| 无效交易对 | ❌ API错误40309 | ✅ 清晰的错误提示 |
| 保证金模式 | ❌ 每次都设置 | ✅ 检查后按需设置 |
| 错误日志 | ❌ 技术错误码 | ✅ 用户友好的说明 |
| 启动速度 | ⚠️ 正常 | ✅ 预加载交易对列表 |

---

## 🎯 预期效果

### 立即生效
- ✅ 不再尝试交易FHEUSDT等已下架交易对
- ✅ 清晰的错误提示而非API错误码
- ✅ 减少无效的API调用

### 长期改进
- ✅ 自动发现新上线的交易对
- ✅ 自动识别下架的交易对
- ✅ 更好的日志可读性
- ✅ 更低的API请求频率

---

## 🆘 如遇问题

### Q: 编译失败

```bash
# 清理缓存重试
go clean -modcache
go mod download
go build -o nofx main.go
```

### Q: 服务启动失败

```bash
# 查看详细错误
tail -100 nohup.out

# 检查端口占用
netstat -tlnp | grep 8080
```

### Q: 还是有40309错误

```bash
# 检查是否是新的交易对
grep "40309" data/nofx_*.log | tail -1

# 手动刷新交易对列表（重启服务即可）
```

### Q: 回滚到之前版本

```bash
# 停止服务
kill $(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')

# 使用备份
cp nofx.backup.* nofx

# 重启
nohup ./nofx > nohup.out 2>&1 &
```

---

## 📞 下一步

部署完成后，请持续关注：

1. **监控日志** - 确认没有40309错误
2. **交易执行** - 确认交易正常进行
3. **保证金模式** - 确认与配置一致

如一切正常，建议：
- 记录可用交易对的变化
- 监控新交易对的上线
- 定期检查系统日志

---

## 📚 相关文档

- [FIXES_2026-01-21.md](./FIXES_2026-01-21.md) - 详细修复说明
- [deploy-guide.md](./deploy-guide.md) - 完整部署指南
- [git-commit.ps1](./git-commit.ps1) - 本地提交脚本
- [deploy-server.sh](./deploy-server.sh) - 服务器部署脚本

---

**祝部署顺利！** 🎉
