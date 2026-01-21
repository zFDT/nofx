# NOFX 项目部署指南
## 版本：2026-01-21

---

## 📋 目录

1. [部署概述](#部署概述)
2. [代码修改记录](#代码修改记录)
3. [部署前准备](#部署前准备)
4. [自动化部署流程](#自动化部署流程)
5. [手动部署流程](#手动部署流程)
6. [部署验证](#部署验证)
7. [回滚方案](#回滚方案)
8. [常见问题](#常见问题)

---

## 🎯 部署概述

### 项目信息
- **项目名称**: NOFX - AI驱动的交易系统
- **仓库地址**: https://github.com/zFDT/nofx.git
- **当前分支**: dev
- **部署环境**: Linux服务器 (testWeb@43.134.70.26)
- **项目路径**: /home/testWeb/nofx
- **运行端口**: 8080 (后端), 3000 (前端)

### 技术栈
- **后端**: Go 1.25.3
- **数据库**: SQLite / PostgreSQL
- **部署方式**: 直接编译部署 / Docker Compose

### 本次部署内容
- 提交最新代码修改
- 添加调查文档 (INVESTIGATION.md)
- 同步远程仓库到服务器
- 编译并重启服务

---

## 📝 代码修改记录

### 最近部署记录 (2026-01-21 23:17)

#### 部署方式
- **方法**: Docker Compose
- **服务器**: testWeb@43.134.70.26
- **源码目录**: /home/testWeb/nofx-source  
- **部署目录**: /home/testWeb/nofx

#### 遇到的问题及解决方案

1. **问题**: `deploy-server.sh` 文件找不到
   - **原因**: 部署目录和源码目录分离
   - **解决**: 从 `/home/testWeb/nofx-source` 执行脚本

2. **问题**: Kill进程权限不足（`Operation not permitted`）
   - **原因**: 进程以root用户运行
   - **解决**: 使用 `sudo kill` 命令

3. **问题**: Go编译失败（`go: not found`）
   - **原因**: 服务器未安装Go环境
   - **解决**: 改用Docker Compose部署

4. **问题**: 代码语法错误（`store/ai_model.go:32`）
   - **原因**: 结构体定义缺少闭合括号 `}`
   - **解决**: 本地修复后提交推送，服务器拉取最新代码

5. **问题**: Docker容器状态为"created"不运行
   - **原因**: Docker Compose配置或环境问题
   - **解决**: 使用 `docker compose rm -f` 删除后重新创建

#### 最终部署命令
```bash
# 1. 连接服务器
ssh testWeb@43.134.70.26

# 2. 拉取最新代码
cd /home/testWeb/nofx-source
git pull origin dev

# 3. 同步到部署目录
sudo cp -r * /home/testWeb/nofx/

# 4. Docker构建并启动
cd /home/testWeb/nofx
docker compose down
docker compose up -d --build

# ⚠️ 如果容器不启动（状态为"Created"）：
docker compose rm -f nofx
docker compose up -d nofx
sleep 10

# 5. 验证部署
docker ps
docker logs nofx-trading --tail 50
curl http://localhost:8080/api/health

# 6. 验证模型故障转移功能
docker logs nofx-trading 2>&1 | grep -E "(alternative|Loaded|models)" | tail -20
# 预期看到: "✓ Loaded 26 alternative Qwen models for failover"
```

#### 部署结果
✅ **成功部署**
- 后端服务: http://43.134.70.26:8080 (健康)
- 前端服务: http://43.134.70.26:3000 (运行中)
- 容器状态: 
  - `nofx-trading`: Up, healthy (10秒后)
  - `nofx-frontend`: Up
- 智能模型故障转移: 已激活，26个备用模型已加载
  - `qwen-turbo`, `qwen-flash`, `qwen-turbo-latest`, `qwen-plus-latest`, `qwen-max-latest`, `qwen-long-latest`
  - `qwq-plus`, `qwen-coder-plus`, `qwen2.5-72b-instruct`, `qwen2.5-32b-instruct`, `qwen2.5-14b-instruct`
  - `qwen2.5-7b-instruct`, `qwen-long`, `qwen-max-2025-01-25`, `qwen-turbo-2025-07-15`, `qwen-plus-2025-07-28`
  - `qwen-plus-2025-01-25`, `deepseek-v3`, `deepseek-v3.2`, `deepseek-r1`, `deepseek-r1-0528`
  - `qwen-math-plus`, `qwen-coder-turbo`, `qwq-32b`, `qwq-plus-latest`, `gui-plus`

---

### 提交历史

#### Commit: 9f8a22b5 (2026-01-21 22:02)
- **类型**: Bug修复
- **描述**: 修复ai_model.go语法错误 - 添加缺失的结构体闭合括号
- **文件变更**:
  - 修改: `store/ai_model.go` (+2行)

#### Commit: 18de504e (2026-01-21)
- **类型**: 文档添加
- **描述**: 添加部署指南和调查文档
- **文件变更**:
  - 新增: `DEPLOYMENT_GUIDE_2026-01-21.md` (776行)
  - 新增: `INVESTIGATION.md` (74行)
  - 新增: PR合并相关文档

### 最近提交记录

#### Commit: 74c8b89b (2026-01-21)
- **类型**: 文档添加
- **描述**: 添加调查文档 (INVESTIGATION.md)
- **文件变更**:
  - 新增: `INVESTIGATION.md` (74行)

#### Commit: 30f20c5f (之前)
- **文件变更**: deploy-server.sh 和其他修复

### 关键文件说明

| 文件路径 | 说明 | 作用 |
|---------|------|------|
| `main.go` | 主程序入口 | 启动Web服务器、初始化所有模块 |
| `deploy-server.sh` | 部署脚本 | 自动化部署流程（拉取、编译、重启） |
| `docker-compose.prod.yml` | Docker生产配置 | 容器化部署配置 |
| `.env` | 环境变量配置 | API密钥、数据库配置等 |
| `go.mod` | Go模块依赖 | 项目依赖管理 |
| `INVESTIGATION.md` | 调查文档 | 问题排查记录 |

---

## 🔧 部署前准备

### 1. 本地准备

#### 检查代码状态
```powershell
cd "d:\新建文件夹 (3)\web\nofx"
git status
git log -3
```

#### 确认推送成功
```powershell
# 查看远程分支状态
git fetch origin
git log origin/dev -3

# 确认本地与远程同步
git status
```

### 2. 服务器准备

#### 环境要求
- **操作系统**: Linux (Ubuntu/CentOS/Debian)
- **Go版本**: 1.21+
- **必备工具**: git, curl, wget
- **网络**: 能够访问GitHub和Go代理

#### 检查服务器连接
```bash
# 测试SSH连接
ssh testWeb@43.134.70.26

# 检查Go版本
go version

# 检查git配置
git --version
git config --list
```

#### 检查服务器磁盘空间
```bash
df -h /home/testWeb/nofx
du -sh /home/testWeb/nofx
```

---

## 🚀 自动化部署流程 (推荐)

### 方式1: 使用 Docker Compose (最推荐)

**适用场景**: 服务器已配置Docker环境（推荐用于生产环境）

#### 部署步骤

**步骤1: 连接服务器并进入源码目录**
```bash
ssh testWeb@43.134.70.26
cd /home/testWeb/nofx-source
```

**步骤2: 拉取最新代码**
```bash
git pull origin dev
```

**步骤3: 同步代码到部署目录**
```bash
sudo cp -r * /home/testWeb/nofx/
cd /home/testWeb/nofx
```

**步骤4: 构建并启动服务**
```bash
# 停止旧容器（如果有）
docker compose down

# 重新构建并启动
docker compose up -d --build

# 等待服务启动
sleep 10
# ⚠️ 如果容器创建但不运行（状态为"Created"）：
# docker compose rm -f nofx
# docker compose up -d nofx
# sleep 10```

**步骤5: 验证部署**
```bash
# 查看容器状态
docker ps

# 查看后端日志
docker logs nofx-trading --tail 50

# 测试API
curl http://localhost:8080/api/health

# 测试前端
curl -I http://localhost:3000/
```

**预期输出**:
```
CONTAINER ID   IMAGE         COMMAND    STATUS                   PORTS
8f774c6e4a77   nofx-nofx     "./nofx"   Up 2 minutes (healthy)   0.0.0.0:8080->8080/tcp
cd5c64d93e5f   nofx-frontend "..."      Up 2 hours               0.0.0.0:3000->80/tcp

# API健康检查
{"status":"ok","time":null}
```

#### 常见问题处理

**问题1: 容器创建但不运行（状态为 "created"）**
```bash
# 删除并重新创建容器
cd /home/testWeb/nofx
docker compose rm -f nofx
docker compose up -d nofx
```

**问题2: 端口冲突**
```bash
# 查找占用端口的进程
lsof -i :8080

# 停止旧进程
docker stop <container_id>
```

**问题3: 权限问题**
```bash
# data目录权限修复
sudo chown -R testWeb:testWeb /home/testWeb/nofx/data
```

---

### 方式2: 使用 deploy-server.sh 脚本

**适用场景**: 服务器已安装Go环境，直接编译部署（适用于开发环境）

#### 步骤1: SSH连接到服务器
```bash
ssh testWeb@43.134.70.26
```

#### 步骤2: 进入项目目录
```bash
cd /home/testWeb/nofx
```

#### 步骤3: 执行部署脚本
```bash
# 赋予执行权限（首次需要）
chmod +x deploy-server.sh

# 执行部署
./deploy-server.sh
```

#### 脚本执行流程说明

脚本会依次执行以下7个步骤：

1. **[1/7] 进入项目目录**
   - 切换到 `/home/testWeb/nofx`
   - 显示当前工作目录

2. **[2/7] 备份当前程序**
   - 备份现有可执行文件 `nofx` 为 `nofx.backup.YYYYMMDD_HHMMSS`
   - 如果没有现有程序，跳过备份

3. **[3/7] 停止当前服务**
   - 查找并停止正在运行的 `nofx` 进程
   - 等待2秒确保进程完全停止

4. **[4/7] 拉取最新代码**
   - 执行 `git pull origin dev`
   - 从远程仓库获取最新代码

5. **[5/7] 编译项目**
   - 设置Go代理: `GOPROXY=https://goproxy.cn,direct`
   - 禁用CGO: `CGO_ENABLED=0`
   - 编译: `go build -o nofx main.go`
   - 设置执行权限: `chmod +x nofx`

6. **[6/7] 启动服务**
   - 后台启动: `nohup ./nofx > nohup.out 2>&1 &`
   - 记录新进程PID

7. **[7/7] 验证服务状态**
   - 检查进程是否运行
   - 显示最近20行日志
   - 提供查看日志的命令提示

#### 预期输出示例
```
==========================================
NOFX 服务器部署脚本
==========================================

[1/7] 进入项目目录...
✓ 当前目录: /home/testWeb/nofx

[2/7] 备份当前程序...
✓ 备份完成: nofx.backup.20260121_143025

[3/7] 停止当前服务...
✓ 已停止进程: 12345

[4/7] 拉取最新代码...
From https://github.com/zFDT/nofx
 * branch            dev        -> FETCH_HEAD
Already up to date.
✓ 代码已更新

[5/7] 编译项目...
✓ 编译完成

[6/7] 启动服务...
✓ 服务已启动，PID: 23456

[7/7] 验证服务状态...
✓ 服务运行正常

最近的日志输出:
[日志内容...]

==========================================
部署完成!
==========================================

查看实时日志:
  tail -f nohup.out
  或
  tail -f data/nofx_2026-01-21.log
```

---

## 🔨 手动部署流程

如果自动脚本出现问题，可以使用手动部署方式。

### 步骤1: SSH连接服务器
```bash
ssh testWeb@43.134.70.26
```

### 步骤2: 进入项目目录
```bash
cd /home/testWeb/nofx
pwd  # 确认当前目录
```

### 步骤3: 备份当前程序
```bash
# 如果存在旧程序，先备份
if [ -f "nofx" ]; then
    cp nofx nofx.backup.$(date +%Y%m%d_%H%M%S)
    echo "备份完成"
fi

# 查看所有备份
ls -lh nofx.backup.*
```

### 步骤4: 停止当前服务
```bash
# 查找运行中的进程
ps aux | grep './nofx' | grep -v grep

# 获取进程ID并停止
PID=$(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')
if [ ! -z "$PID" ]; then
    echo "停止进程: $PID"
    kill $PID
    sleep 2
fi

# 确认进程已停止
ps aux | grep './nofx' | grep -v grep
```

### 步骤5: 拉取最新代码
```bash
# 检查当前分支
git branch -v

# 检查远程状态
git fetch origin
git status

# 拉取最新代码
git pull origin dev

# 查看最新提交
git log -3 --oneline
```

### 步骤6: 编译项目
```bash
# 设置Go环境变量
export GOPROXY=https://goproxy.cn,direct
export CGO_ENABLED=0

# 清理之前的构建（可选）
go clean

# 下载依赖（如果需要）
go mod download

# 编译主程序
go build -o nofx main.go

# 设置执行权限
chmod +x nofx

# 查看编译结果
ls -lh nofx
```

### 步骤7: 启动服务
```bash
# 后台启动服务
nohup ./nofx > nohup.out 2>&1 &

# 记录进程ID
echo "新进程PID: $!"

# 等待启动
sleep 3

# 查看进程状态
ps aux | grep './nofx' | grep -v grep
```

### 步骤8: 查看日志
```bash
# 查看启动日志
tail -30 nohup.out

# 实时监控日志
tail -f nohup.out

# 或查看应用日志
tail -f data/nofx_$(date +%Y-%m-%d).log
```

---

## ✅ 部署验证

### 1. 服务状态检查

#### 检查进程是否运行
```bash
# 方法1: 使用ps
ps aux | grep './nofx' | grep -v grep

# 方法2: 使用pgrep
pgrep -f './nofx'

# 方法3: 检查端口占用
netstat -tunlp | grep :8080
# 或
ss -tunlp | grep :8080
```

#### 检查服务响应
```bash
# 健康检查端点（如果有）
curl http://localhost:8080/api/health

# 或主页
curl -I http://localhost:8080
```

### 2. 日志检查

#### 启动日志
```bash
# 查看最近50行启动日志
tail -50 nohup.out

# 搜索关键启动信息
grep "NOFX" nohup.out | tail -10
grep "started" nohup.out | tail -5
grep "✅" nohup.out | tail -10
```

#### 应用日志
```bash
# 查看今天的应用日志
tail -50 data/nofx_$(date +%Y-%m-%d).log

# 搜索错误
grep -i "error" data/nofx_$(date +%Y-%m-%d).log
grep -i "fatal" data/nofx_$(date +%Y-%m-%d).log
```

### 3. 功能验证

#### API端点测试
```bash
# 测试API（根据实际端点调整）
curl http://localhost:8080/api/traders
curl http://localhost:8080/api/config

# 如果需要认证，添加token
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/traders
```

#### 数据库连接
```bash
# 检查SQLite数据库文件
ls -lh data/nofx.db

# 如果使用PostgreSQL，检查连接
# psql -h localhost -U nofx_user -d nofx_db -c "SELECT 1;"
```

### 4. 资源使用检查

#### 内存使用
```bash
# 查看进程内存占用
ps aux | grep './nofx' | grep -v grep | awk '{print $4 "% - " $6/1024 " MB"}'

# 使用top查看
top -p $(pgrep -f './nofx')
```

#### CPU使用
```bash
# 查看CPU占用
ps aux | grep './nofx' | grep -v grep | awk '{print $3 "%"}'
```

#### 磁盘使用
```bash
# 查看数据目录大小
du -sh data/

# 查看日志大小
du -sh data/*.log

# 查看可用空间
df -h /home/testWeb/nofx
```

---

## 🔄 回滚方案

如果新版本出现问题，可以快速回滚到之前的版本。

### 方案1: 使用备份程序回滚

```bash
# 1. 停止当前服务
PID=$(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')
kill $PID

# 2. 查看可用备份
ls -lht nofx.backup.*

# 3. 恢复到最近的备份
# 替换 YYYYMMDD_HHMMSS 为实际备份时间
cp nofx.backup.20260121_143025 nofx
chmod +x nofx

# 4. 重启服务
nohup ./nofx > nohup.out 2>&1 &

# 5. 验证
tail -30 nohup.out
```

### 方案2: 使用Git回滚

```bash
# 1. 停止服务
PID=$(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')
kill $PID

# 2. 查看提交历史
git log --oneline -10

# 3. 回滚到指定提交（替换为实际commit hash）
git checkout 30f20c5f

# 或回滚到上一个提交
git checkout HEAD~1

# 4. 重新编译
export GOPROXY=https://goproxy.cn,direct
export CGO_ENABLED=0
go build -o nofx main.go
chmod +x nofx

# 5. 启动服务
nohup ./nofx > nohup.out 2>&1 &

# 6. 验证
tail -30 nohup.out

# 7. 如果需要永久回滚，切回主分支
git checkout dev
git reset --hard 30f20c5f
```

### 方案3: 紧急恢复（使用最近备份的完整目录）

```bash
# 如果问题严重，可以从备份目录恢复
# （需要提前设置定期备份）

# 1. 停止服务
PID=$(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')
kill $PID

# 2. 从备份恢复
cd /home/testWeb
cp -r nofx.backup.daily nofx.restore
cd nofx.restore

# 3. 启动服务
nohup ./nofx > nohup.out 2>&1 &
```

---

## ❓ 常见问题

### Q1: 部署脚本执行权限问题
**问题**: `bash: ./deploy-server.sh: Permission denied`

**解决**:
```bash
chmod +x deploy-server.sh
./deploy-server.sh
```

### Q2: Git拉取失败
**问题**: `fatal: unable to access 'https://github.com/...': Could not resolve host`

**解决**:
```bash
# 检查网络连接
ping github.com

# 检查DNS
cat /etc/resolv.conf

# 尝试使用git协议
git remote set-url origin git@github.com:zFDT/nofx.git
git pull origin dev
```

### Q3: Go编译失败
**问题**: `go: module requires Go 1.25.3`

**解决**:
```bash
# 检查Go版本
go version

# 如果版本过低，更新Go
# 下载最新版本: https://golang.org/dl/
wget https://go.dev/dl/go1.25.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
```

### Q4: 端口被占用
**问题**: `bind: address already in use`

**解决**:
```bash
# 方法1: Docker环境
# 查找占用端口的容器
docker ps | grep 8080

# 停止容器
docker stop <container_name>

# 方法2: 非Docker环境  
# 查找占用端口的进程
lsof -i :8080
# 或
netstat -tunlp | grep :8080

# 停止占用的进程
kill -9 <PID>

# 或修改配置文件使用其他端口
vi .env
# 修改 PORT=8081
```

### Q5: Go编译失败（服务器未安装Go）
**问题**: `sh: 1: go: not found`

**解决方案**: 使用Docker Compose部署
```bash
cd /home/testWeb/nofx
docker compose up -d --build
```

### Q6: 代码语法错误导致编译失败
**问题**: `syntax error: unexpected keyword func`

**解决**:
```bash
# 1. 在本地修复语法错误
# 2. 提交并推送到远程仓库
git add .
git commit -m "Fix: 修复语法错误"
git push origin dev

# 3. 在服务器上拉取最新代码
cd /home/testWeb/nofx-source
git pull origin dev

# 4. 重新部署
sudo cp -r * /home/testWeb/nofx/
cd /home/testWeb/nofx
docker compose up -d --build
```

### Q5: 服务启动后立即停止
**问题**: 服务启动后几秒钟就停止

**解决**:
```bash
# Docker环境
# 1. 查看详细错误日志
docker logs nofx-trading --tail 100

# 2. 前台运行查看错误
docker run --rm --env-file .env -v $(pwd)/data:/app/data nofx-nofx ./nofx

# 3. 检查配置文件
cat .env

# 非Docker环境
# 1. 查看详细错误日志
tail -50 nohup.out

# 2. 前台运行查看错误
./nofx

# 3. 检查配置文件
cat .env

# 4. 检查数据库文件权限
ls -l data/

# 5. 检查是否缺少依赖配置
grep -i "missing" nohup.out
grep -i "required" nohup.out
```

### Q6: 找不到进程但端口被占用
**问题**: `ps aux | grep nofx` 找不到进程，但端口8080被占用

**解决**:
```bash
# 通过端口找进程
lsof -i :8080
# 或
netstat -tunlp | grep :8080

# 强制终止占用端口的进程
kill -9 <PID>

# 等待几秒后重启服务
sleep 3
nohup ./nofx > nohup.out 2>&1 &
```

### Q7: 日志文件过大
**问题**: 日志文件占用大量磁盘空间

**解决**:
```bash
# 查看日志大小
du -sh data/*.log

# 清理旧日志（保留最近7天）
find data/ -name "*.log" -type f -mtime +7 -delete

# 或手动清理
rm data/nofx_2026-01-*.log

# 压缩旧日志
gzip data/nofx_2026-01-*.log

# 设置日志轮转（创建 logrotate 配置）
sudo vi /etc/logrotate.d/nofx
```

### Q8: 依赖下载超时
**问题**: `go: module ... timeout`

**解决**:
```bash
# 使用国内代理
export GOPROXY=https://goproxy.cn,direct

# 或使用阿里云代理
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

# 增加超时时间
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 清理缓存重新下载
go clean -modcache
go mod download
```

---

## 📊 部署检查清单

### 部署前检查
- [ ] 本地代码已提交到Git
- [ ] 远程仓库已更新
- [ ] 服务器SSH连接正常
- [ ] 服务器磁盘空间充足 (至少1GB)
- [ ] 备份了当前运行的程序

### 部署中检查
- [ ] 旧服务已成功停止
- [ ] Git代码拉取成功
- [ ] Go编译无错误
- [ ] 新服务成功启动
- [ ] 进程运行正常

### 部署后检查
- [ ] API端点响应正常
- [ ] 日志无严重错误
- [ ] 数据库连接正常
- [ ] 内存CPU使用正常
- [ ] 功能验证通过

---

## 🔐 安全注意事项

1. **环境变量保护**
   - 不要在Git中提交 `.env` 文件
   - 服务器上的 `.env` 文件权限设置为 600
   ```bash
   chmod 600 .env
   ```

2. **API密钥管理**
   - 定期轮换API密钥
   - 使用环境变量存储敏感信息
   - 不要在代码或日志中打印完整密钥

3. **SSH安全**
   - 使用密钥认证而非密码
   - 定期更新SSH密钥
   - 限制SSH访问IP

4. **服务器防火墙**
   - 只开放必要端口 (8080, 3000, 22)
   - 配置fail2ban防止暴力破解

---

## 📞 技术支持

### 开发团队
- **项目负责人**: Tinkle ([@Web3Tinkle](https://x.com/Web3Tinkle))
- **官方Twitter**: [@nofx_official](https://x.com/nofx_official)
- **开发者社区**: [NOFX Developer Community](https://t.me/nofx_dev_community)

### 相关文档
- [README.md](README.md) - 项目介绍
- [DEPLOY_QUICKSTART.md](DEPLOY_QUICKSTART.md) - 快速部署指南
- [deploy-guide.md](deploy-guide.md) - 详细部署指南
- [INVESTIGATION.md](INVESTIGATION.md) - 问题调查文档

---

## 📅 维护计划

### 定期维护任务
1. **每日**
   - 检查服务运行状态
   - 查看错误日志
   - 监控资源使用

2. **每周**
   - 清理旧日志文件
   - 检查磁盘空间
   - 备份数据库

3. **每月**
   - 更新依赖包
   - 安全补丁更新
   - 性能优化评估

---

## 📈 性能监控

### 推荐监控指标
- CPU使用率 < 80%
- 内存使用率 < 80%
- 磁盘使用率 < 90%
- API响应时间 < 200ms
- 错误率 < 1%

### 监控命令
```bash
# 系统资源监控
htop

# 实时日志监控
tail -f nohup.out | grep -i "error\|fatal\|panic"

# 进程监控
watch -n 2 'ps aux | grep nofx | grep -v grep'

# 模型故障转移监控
docker logs nofx-trading --tail 100 | grep -E "Switching|Quota exceeded|unavailable"
```

---

## 🔄 AI模型智能故障转移机制

### 功能概述
系统实现了智能的AI模型故障转移机制，当主模型出现配额超限或不可用时，自动切换到备用模型，确保服务持续运行。

### 核心逻辑说明

#### 2.1 前端配置（支持批量导入200+模型）
- **位置**: AI配置页面 → 备用模型列表
- **功能**: 
  - 手动输入逗号分隔的模型列表
  - 批量导入（每行一个模型名称）
  - 快速模板（交易/性能/经济/DeepSeek优化）
- **限制**: 理论上无数量限制，支持导入200+模型
- **示例**: `qwen-turbo,qwen-flash,qwen-plus,deepseek-v3,deepseek-r1,...`

#### 2.2 运行时故障转移逻辑
**工作流程**:
1. **启动时加载**: 系统从数据库读取配置的备用模型列表
2. **按序尝试**: 按配置顺序依次尝试每个模型
3. **跳过不可用**: 已标记为不可用的模型会被自动跳过
4. **错误检测**: 识别两类错误触发标记：
   - 配额超限错误（HTTP 403/429，`AllocationQuota.FreeTierOnly`, `quota exceeded`, `rate limit`）
   - 模型不可用错误（HTTP 404/400，`InvalidParameter.Model.NotFound`, `model not found`）
5. **自动标记**: 遇到上述错误时，将模型标记为不可用
6. **寻找下一个**: 继续尝试列表中下一个未标记的模型
7. **全部失败**: 所有模型都不可用时，返回错误提示

**代码位置**: [mcp/client.go](mcp/client.go#L196-L240)

**日志示例**:
```log
[INFO] ✓ Loaded 26 alternative Qwen models for failover
[INFO] 🔄 Switching to model: qwen-flash (tried: 1, skipped: 0)
[WARN] ⚠️  Quota exceeded for model qwen-turbo, marking as unavailable
[DEBUG] ⏭️  Skipping unavailable model: qwen-turbo
[ERROR] ❌ All available models exhausted. Total: 26, Tried: 5, Skipped: 3, Unavailable: 8
```

#### 2.3 配置更新重置机制
**重要**: 每次创建新的交易机器人或更新AI配置时，不可用模型的标记**会被重置**。

**原因**: 
- 每次配置更新都会创建新的 `mcp.Client` 实例
- 新实例的 `unavailableModels` map 会重新初始化为空
- 这允许用户在充值额度后重新启用所有模型

**代码位置**: 
- 创建Client: [trader/auto_trader.go](trader/auto_trader.go#L189-L197)
- 配置初始化: [mcp/config.go](mcp/config.go#L58)

**操作流程**:
1. 用户在控制台充值API额度
2. 在前端编辑AI配置（无需修改模型列表）
3. 保存配置触发交易机器人重启
4. 新的Client实例创建，`unavailableModels` 重置为空
5. 所有模型（包括之前标记的）重新变为可用状态

### 配置示例

#### 数据库配置（SQLite）
```sql
-- 查看当前配置
SELECT id, provider, alternative_models 
FROM ai_models 
WHERE provider = 'qwen';

-- 更新备用模型列表
UPDATE ai_models 
SET alternative_models = 'qwen-turbo,qwen-flash,qwen-plus,deepseek-v3'
WHERE provider = 'qwen';
```

#### 前端UI配置
1. 进入 AI配置 页面
2. 选择 Qwen 模型配置
3. 在"备用模型列表"框中输入或批量导入
4. 点击"保存配置"

### 监控与调试

#### 查看已加载模型
```bash
docker logs nofx-trading 2>&1 | grep "Loaded.*alternative.*models"
```

#### 查看模型切换日志
```bash
docker logs nofx-trading 2>&1 | grep "Switching to model"
```

#### 查看不可用模型统计
```bash
docker logs nofx-trading 2>&1 | grep "Unavailable:"
```

---

**部署文档版本**: 1.1  
**创建日期**: 2026-01-21  
**最后更新**: 2026-01-21 23:30  
**维护人员**: NOFX团队

---

✅ **部署完成后，请保留此文档以备后续参考！**
