# 部署指南 - 修复版本部署到服务器

## 本次修复内容

1. ✅ 添加交易对有效性检查（避免交易已移除的交易对如FHEUSDT）
2. ✅ 添加保证金模式检查和同步
3. ✅ 添加交易对列表自动更新功能
4. ✅ 修复MCP客户端代码语法错误

---

## 步骤1: 提交代码到Git仓库

### 1.1 查看修改的文件

```powershell
cd "d:\新建文件夹 (3)\web\nofx"
git status
```

### 1.2 添加修改的文件

```powershell
# 添加所有修改的文件
git add trader/bitget_trader.go
git add mcp/client.go
git add FIXES_2026-01-21.md

# 或者添加所有修改
git add -A
```

### 1.3 提交修改

```powershell
git commit -m "fix: 添加交易对有效性检查和保证金模式同步

- 新增 IsSymbolValid() 检查交易对是否被移除
- 新增 GetAvailableSymbols() 获取所有可用交易对
- 新增 GetMarginMode() 获取当前保证金模式
- 改进 SetMarginMode() 在设置前检查当前模式
- 在 OpenLong/OpenShort 前验证交易对有效性
- 修复 mcp/client.go 语法错误
- 避免 40309 错误（交易对已被移除）"
```

### 1.4 推送到远程仓库

```powershell
# 推送到主分支
git push origin main

# 或者推送到其他分支
git push origin <你的分支名>
```

---

## 步骤2: SSH连接到服务器

### 2.1 连接服务器

```powershell
ssh testWeb@43.134.70.26
```

### 2.2 进入项目目录

```bash
cd /home/testWeb/nofx
```

---

## 步骤3: 在服务器上更新和编译

### 3.1 备份当前运行的程序

```bash
# 停止当前服务（如果有停止脚本）
./stop.sh
# 或者手动查找并停止进程
ps aux | grep nofx
kill <进程ID>

# 备份当前可执行文件
cp nofx nofx.backup.$(date +%Y%m%d_%H%M%S)
```

### 3.2 拉取最新代码

```bash
# 拉取最新代码
git pull origin main

# 查看当前提交
git log -1
```

### 3.3 编译项目

```bash
# 设置Go环境变量（如果需要）
export GOPROXY=https://goproxy.cn,direct
export CGO_ENABLED=0

# 编译项目
go build -o nofx main.go

# 检查编译结果
ls -lh nofx

# 赋予执行权限
chmod +x nofx
```

### 3.4 验证编译结果

```bash
# 查看版本信息（如果有）
./nofx --version

# 或者直接运行看是否有错误
./nofx --help
```

---

## 步骤4: 启动服务

### 4.1 启动方式1: 使用启动脚本

```bash
# 如果有启动脚本
./start.sh
```

### 4.2 启动方式2: 使用nohup后台运行

```bash
# 后台运行并输出日志
nohup ./nofx > nohup.out 2>&1 &

# 查看进程
ps aux | grep nofx

# 实时查看日志
tail -f nohup.out
```

### 4.3 启动方式3: 使用systemd服务（推荐）

如果配置了systemd服务：

```bash
# 重启服务
sudo systemctl restart nofx

# 查看服务状态
sudo systemctl status nofx

# 查看服务日志
sudo journalctl -u nofx -f
```

---

## 步骤5: 验证修复效果

### 5.1 查看日志

```bash
# 查看今天的日志
tail -f /home/testWeb/nofx/data/nofx_$(date +%Y-%m-%d).log

# 或查看nohup输出
tail -f /home/testWeb/nofx/nohup.out
```

### 5.2 检查关键日志

#### 检查交易对加载

```bash
# 应该看到类似这样的日志
grep "Loaded.*available symbols" /home/testWeb/nofx/data/nofx_*.log | tail -5
```

期望输出：
```
✓ [Bitget] Loaded 150 available symbols
```

#### 检查是否还有40309错误

```bash
# 检查今天是否还有40309错误
grep "40309" /home/testWeb/nofx/data/nofx_$(date +%Y-%m-%d).log
```

如果修复成功，应该看到：
```
❌ Failed to execute decision (FHEUSDT open_long): symbol FHEUSDT has been removed or is invalid, cannot open position
```

而不是之前的：
```
❌ failed to open long position: Bitget API error: code=40309, msg=The symbol has been removed
```

#### 检查保证金模式同步

```bash
# 查看保证金模式日志
grep "margin mode" /home/testWeb/nofx/data/nofx_$(date +%Y-%m-%d).log | tail -10
```

期望看到：
```
✓ BTCUSDT margin mode is already crossed, no change needed
🔄 ETHUSDT margin mode: crossed → isolated
✓ ETHUSDT margin mode set to isolated successfully
```

---

## 步骤6: 监控运行状态

### 6.1 持续监控日志

```bash
# 实时查看日志，关注错误信息
tail -f /home/testWeb/nofx/data/nofx_$(date +%Y-%m-%d).log | grep -E "❌|⚠️|ERROR"
```

### 6.2 检查进程状态

```bash
# 检查进程是否运行
ps aux | grep nofx | grep -v grep

# 查看资源占用
top -p $(pgrep nofx)
```

### 6.3 测试交易功能

观察日志中：
- ✅ 交易对验证是否正常
- ✅ 保证金模式是否正确设置
- ✅ 是否还有40309错误
- ✅ 交易执行是否成功

---

## 常见问题排查

### Q1: 编译失败

```bash
# 检查Go版本
go version

# 清理模块缓存
go clean -modcache

# 重新下载依赖
go mod download

# 再次编译
go build -o nofx main.go
```

### Q2: 依赖下载失败

```bash
# 设置国内代理
export GOPROXY=https://goproxy.cn,direct

# 或者使用阿里云代理
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
```

### Q3: 权限问题

```bash
# 确保有执行权限
chmod +x nofx

# 确保有日志目录写入权限
chmod 755 data/
```

### Q4: 服务启动失败

```bash
# 检查端口是否被占用
netstat -tlnp | grep 8080

# 检查配置文件
cat config.yaml

# 查看详细错误信息
./nofx 2>&1 | less
```

---

## 回滚方案

如果新版本有问题，可以快速回滚：

```bash
# 停止当前服务
./stop.sh  # 或 kill <进程ID>

# 恢复备份的可执行文件
cp nofx.backup.* nofx

# 重新启动
./start.sh
```

---

## 部署后检查清单

- [ ] 代码已推送到Git仓库
- [ ] 服务器已拉取最新代码
- [ ] 编译成功，无错误
- [ ] 服务启动成功
- [ ] 日志中显示"Loaded X available symbols"
- [ ] 不再出现40309错误（对于已移除的交易对）
- [ ] 保证金模式检查和设置正常
- [ ] 交易执行正常
- [ ] 进程稳定运行

---

## 技术支持

如遇到问题：
1. 查看日志文件了解详细错误信息
2. 检查Git提交历史确认代码已更新
3. 确认编译时没有警告或错误
4. 使用 `git diff` 对比本地和服务器的代码差异

---

## 下次优化建议

1. 配置CI/CD自动部署
2. 添加健康检查接口
3. 配置日志轮转（避免日志文件过大）
4. 添加性能监控和告警
5. 使用Docker容器化部署
