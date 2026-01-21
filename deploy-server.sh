#!/bin/bash

# SSH服务器部署脚本
# 在SSH连接的服务器上执行此脚本

set -e  # 遇到错误立即退出

echo "=========================================="
echo "NOFX 服务器部署脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/home/testWeb/nofx"

# 1. 进入项目目录
echo -e "${YELLOW}[1/7] 进入项目目录...${NC}"
cd $PROJECT_DIR
echo -e "${GREEN}✓ 当前目录: $(pwd)${NC}"
echo ""

# 2. 备份当前程序
echo -e "${YELLOW}[2/7] 备份当前程序...${NC}"
if [ -f "nofx" ]; then
    BACKUP_NAME="nofx.backup.$(date +%Y%m%d_%H%M%S)"
    cp nofx $BACKUP_NAME
    echo -e "${GREEN}✓ 备份完成: $BACKUP_NAME${NC}"
else
    echo -e "${YELLOW}⚠ 未找到现有程序，跳过备份${NC}"
fi
echo ""

# 3. 停止当前服务
echo -e "${YELLOW}[3/7] 停止当前服务...${NC}"
PID=$(ps aux | grep './nofx' | grep -v grep | awk '{print $2}')
if [ ! -z "$PID" ]; then
    kill $PID
    echo -e "${GREEN}✓ 已停止进程: $PID${NC}"
    sleep 2
else
    echo -e "${YELLOW}⚠ 未找到运行的进程${NC}"
fi
echo ""

# 4. 拉取最新代码
echo -e "${YELLOW}[4/7] 拉取最新代码...${NC}"
git pull origin dev
echo -e "${GREEN}✓ 代码已更新${NC}"
echo ""

# 5. 编译项目
echo -e "${YELLOW}[5/7] 编译项目...${NC}"
export GOPROXY=https://goproxy.cn,direct
export CGO_ENABLED=0
go build -o nofx main.go
chmod +x nofx
echo -e "${GREEN}✓ 编译完成${NC}"
echo ""

# 6. 启动服务
echo -e "${YELLOW}[6/7] 启动服务...${NC}"
nohup ./nofx > nohup.out 2>&1 &
NEW_PID=$!
echo -e "${GREEN}✓ 服务已启动，PID: $NEW_PID${NC}"
sleep 2
echo ""

# 7. 验证服务状态
echo -e "${YELLOW}[7/7] 验证服务状态...${NC}"
if ps -p $NEW_PID > /dev/null; then
    echo -e "${GREEN}✓ 服务运行正常${NC}"
    
    # 显示最近的日志
    echo ""
    echo -e "${YELLOW}最近的日志输出:${NC}"
    tail -20 nohup.out
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "部署完成!"
    echo "==========================================${NC}"
    echo ""
    echo "查看实时日志:"
    echo "  tail -f nohup.out"
    echo "  或"
    echo "  tail -f data/nofx_$(date +%Y-%m-%d).log"
    echo ""
    echo "检查交易对加载:"
    echo "  grep 'available symbols' nohup.out"
    echo ""
    echo "检查40309错误:"
    echo "  grep '40309' data/nofx_$(date +%Y-%m-%d).log"
    echo ""
else
    echo -e "${RED}✗ 服务启动失败！${NC}"
    echo "查看错误日志:"
    tail -50 nohup.out
    exit 1
fi
