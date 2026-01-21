#!/bin/bash
# 更新Qwen备用模型列表
# 当主模型额度用完时，系统会自动按顺序尝试这些备用模型

echo "🔧 更新Qwen AI备用模型配置..."

# 推荐的模型降级策略（按成本和可用性排序）
# 1. qwen-turbo - 快速且便宜
# 2. qwen-plus-latest - 平衡性能和成本
# 3. qwen-max-latest - 高性能
# 4. qwen-long-latest - 长文本支持
# 5. qwen-flash - 超快速响应
# 6. qwq-plus - 推理能力强
# 7. deepseek-v3 - 备用方案（如果Qwen全部配额用完）

ALTERNATIVE_MODELS="qwen-turbo,qwen-plus-latest,qwen-max-latest,qwen-long-latest,qwen-flash,qwq-plus,deepseek-v3"

# 获取容器名称
CONTAINER_NAME="nofx-trading"

# 检查容器是否运行
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "❌ 错误: 容器 $CONTAINER_NAME 未运行"
    exit 1
fi

# 更新数据库
echo "📝 更新数据库配置..."
docker exec $CONTAINER_NAME sqlite3 /app/data/data.db \
    "UPDATE ai_models SET alternative_models='$ALTERNATIVE_MODELS' WHERE provider='qwen';"

# 验证更新
echo "✅ 验证配置..."
RESULT=$(docker exec $CONTAINER_NAME sqlite3 /app/data/data.db \
    "SELECT provider, custom_model_name, alternative_models FROM ai_models WHERE provider='qwen';")

echo "当前配置:"
echo "$RESULT"

# 重启服务
echo ""
echo "🔄 重启服务以应用配置..."
cd /home/testWeb/nofx
docker compose restart nofx

# 等待启动
echo "⏳ 等待服务启动..."
sleep 8

# 验证日志
echo ""
echo "📊 验证备用模型加载情况:"
docker logs $CONTAINER_NAME --tail 100 | grep -i "alternative.*models"

echo ""
echo "🎉 配置更新完成！"
echo ""
echo "📋 当前备用模型顺序:"
echo "1. qwen-turbo (主模型)"
echo "2. qwen-plus-latest"
echo "3. qwen-max-latest"
echo "4. qwen-long-latest"
echo "5. qwen-flash"
echo "6. qwq-plus"
echo "7. deepseek-v3 (最后备份)"
echo ""
echo "💡 当主模型配额用完时，系统会自动按上述顺序切换"
