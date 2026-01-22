#!/bin/bash
# 版本更新脚本 (Linux/Mac 版本)
# 用于快速更新 version.json 文件

set -e

VERSION_FILE="version.json"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           🔖 NOFX 版本更新工具                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 检查 version.json 是否存在
if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ 错误: 找不到 $VERSION_FILE 文件"
    exit 1
fi

# 检查是否安装了 jq
if ! command -v jq &> /dev/null; then
    echo "⚠️  警告: 未安装 jq，将使用简化版本"
    USE_JQ=false
else
    USE_JQ=true
fi

# 读取当前版本信息
if [ "$USE_JQ" = true ]; then
    CURRENT_VERSION=$(jq -r '.version' "$VERSION_FILE")
    CURRENT_DESC=$(jq -r '.description' "$VERSION_FILE")
    CURRENT_DATE=$(jq -r '.buildDate' "$VERSION_FILE")
else
    CURRENT_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$VERSION_FILE" | cut -d'"' -f4)
    CURRENT_DESC=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$VERSION_FILE" | cut -d'"' -f4)
fi

echo "📋 当前版本信息:"
echo "   版本: $CURRENT_VERSION"
echo "   描述: $CURRENT_DESC"
echo ""

# 询问版本号
echo "请输入新版本号 (例如: v1.0.1, 留空保持不变):"
read -r NEW_VERSION

if [ -z "$NEW_VERSION" ]; then
    NEW_VERSION="$CURRENT_VERSION"
fi

# 确保版本号以 v 开头
if [[ ! "$NEW_VERSION" =~ ^v ]]; then
    if [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        NEW_VERSION="v$NEW_VERSION"
    fi
fi

# 询问描述
echo "请输入版本描述 (留空保持不变):"
read -r NEW_DESC

if [ -z "$NEW_DESC" ]; then
    NEW_DESC="$CURRENT_DESC"
fi

# 获取 Git 信息
GIT_COMMIT=""
GIT_BRANCH="main"

if command -v git &> /dev/null; then
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
fi

# 构建日期
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 显示新版本信息
echo ""
echo "📝 新版本信息:"
echo "   版本: $NEW_VERSION"
echo "   描述: $NEW_DESC"
echo "   日期: $BUILD_DATE"
echo "   提交: $GIT_COMMIT"
echo "   分支: $GIT_BRANCH"
echo ""

# 确认更新
echo "确认更新版本信息? (Y/n)"
read -r CONFIRM

if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
    echo "❌ 已取消更新"
    exit 0
fi

# 写入文件
if [ "$USE_JQ" = true ]; then
    # 使用 jq 更新（保持格式）
    jq --arg version "$NEW_VERSION" \
       --arg description "$NEW_DESC" \
       --arg buildDate "$BUILD_DATE" \
       --arg commit "$GIT_COMMIT" \
       --arg branch "$GIT_BRANCH" \
       '.version = $version | .description = $description | .buildDate = $buildDate | .commit = $commit | .branch = $branch' \
       "$VERSION_FILE" > "${VERSION_FILE}.tmp" && mv "${VERSION_FILE}.tmp" "$VERSION_FILE"
else
    # 简单替换（不保证完美格式）
    sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" "$VERSION_FILE"
    sed -i.bak "s/\"buildDate\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"buildDate\": \"$BUILD_DATE\"/" "$VERSION_FILE"
    rm -f "${VERSION_FILE}.bak"
fi

echo "✅ 版本信息已更新到 $VERSION_FILE"

# 询问是否提交
echo ""
echo "是否提交到 Git? (y/N)"
read -r DO_COMMIT

if [ "$DO_COMMIT" = "y" ] || [ "$DO_COMMIT" = "Y" ]; then
    git add "$VERSION_FILE"
    git commit -m "chore: bump version to $NEW_VERSION"
    echo "✅ 已提交到 Git"
    
    echo "是否推送到远程仓库? (y/N)"
    read -r DO_PUSH
    
    if [ "$DO_PUSH" = "y" ] || [ "$DO_PUSH" = "Y" ]; then
        git push
        echo "✅ 已推送到远程仓库"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🎉 完成! 版本已更新为 $NEW_VERSION"
echo ""
echo "💡 提示:"
echo "   - 构建项目: go build"
echo "   - 验证版本: curl http://localhost:8080/api/version"
echo "   - 查看日志: 启动后会显示版本信息"
echo "════════════════════════════════════════════════════════════"
