# AI API 配额错误修复指南

## 问题描述

**错误信息**:
```
Failed to get AI decision: AI API call failed: API returned error (status 403)
Error: AllocationQuota.FreeTierOnly
Message: The free tier of the model has been exhausted. 
If you wish to continue access the model on a paid basis, 
please disable the "use free tier only" mode in the management console.
```

**原因**: 阿里云Qwen API的免费配额已用完

**时间**: 2026-01-21 22:49:58

---

## 解决方案

### 方案1: 添加DeepSeek API密钥（推荐 - 免费额度大）

DeepSeek提供较大的免费额度，适合中小规模使用。

#### 步骤1: 获取DeepSeek API密钥
1. 访问: https://platform.deepseek.com/
2. 注册/登录账号
3. 进入"API Keys"页面
4. 创建新的API密钥

#### 步骤2: 更新服务器配置
```bash
# 连接服务器
ssh testWeb@43.134.70.26

# 编辑配置文件
cd /home/testWeb/nofx
nano .env

# 添加以下配置（或更新现有配置）
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat

# 保存并退出 (Ctrl+X, Y, Enter)
```

#### 步骤3: 重启服务
```bash
cd /home/testWeb/nofx
docker compose restart nofx
```

#### 步骤4: 验证
```bash
# 查看日志确认启动成功
docker logs nofx-trading --tail 30 | grep -i deepseek

# 应该看到类似输出：
# ✓ Using DeepSeek AI
```

---

### 方案2: 更新Qwen API密钥（需要付费或新账号）

如果您有新的Qwen API密钥或愿意开通付费版本。

#### 步骤1: 在阿里云控制台操作
1. 访问: https://dashscope.console.aliyun.com/
2. 选择以下之一：
   - **选项A**: 禁用"仅使用免费层"模式（需要付费）
   - **选项B**: 创建新账号获取新的免费额度
   - **选项C**: 使用新的API密钥

#### 步骤2: 更新配置
```bash
ssh testWeb@43.134.70.26
cd /home/testWeb/nofx
nano .env

# 更新Qwen配置
QWEN_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_MODEL=qwen-plus

# 保存退出
```

#### 步骤3: 重启服务
```bash
docker compose restart nofx
docker logs nofx-trading --tail 30
```

---

### 方案3: 添加OpenAI API密钥（需要付费）

如果您有OpenAI账号并愿意付费使用。

#### 配置示例
```bash
# .env 文件添加
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini

# 或使用国内转发服务（如有）
OPENAI_BASE_URL=https://your-proxy-url/v1
```

---

### 方案4: 切换到其他AI提供商

系统支持多个AI提供商，您可以根据需求选择：

| 提供商 | 免费额度 | 性能 | 成本 | 推荐场景 |
|--------|---------|------|------|---------|
| DeepSeek | ✅ 大额度 | 高 | 低 | 推荐首选 |
| Qwen | ⚠️ 用完 | 高 | 中 | 需要付费 |
| OpenAI | ❌ 无 | 最高 | 高 | 专业用户 |
| 智谱AI | ✅ 有 | 中 | 中 | 备选方案 |

#### 智谱AI配置示例
```bash
ZHIPU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ZHIPU_BASE_URL=https://open.bigmodel.cn/api/paas/v4/
ZHIPU_MODEL=glm-4
```

---

## 快速修复脚本

为了快速解决问题，您可以使用以下脚本：

### 自动配置DeepSeek（推荐）

```bash
#!/bin/bash
# 文件名: fix_ai_api.sh

echo "🔧 修复AI API配额问题..."

# 请替换为您的实际API密钥
DEEPSEEK_KEY="sk-your-deepseek-api-key-here"

if [ "$DEEPSEEK_KEY" = "sk-your-deepseek-api-key-here" ]; then
    echo "❌ 错误: 请先设置您的DeepSeek API密钥"
    echo "编辑此脚本，将 DEEPSEEK_KEY 替换为实际的密钥"
    exit 1
fi

# 备份原配置
cp /home/testWeb/nofx/.env /home/testWeb/nofx/.env.backup.$(date +%Y%m%d_%H%M%S)

# 检查是否已存在配置
if grep -q "DEEPSEEK_API_KEY" /home/testWeb/nofx/.env; then
    echo "更新现有DeepSeek配置..."
    sed -i "s|DEEPSEEK_API_KEY=.*|DEEPSEEK_API_KEY=$DEEPSEEK_KEY|g" /home/testWeb/nofx/.env
else
    echo "添加新的DeepSeek配置..."
    echo "" >> /home/testWeb/nofx/.env
    echo "# DeepSeek AI Configuration" >> /home/testWeb/nofx/.env
    echo "DEEPSEEK_API_KEY=$DEEPSEEK_KEY" >> /home/testWeb/nofx/.env
    echo "DEEPSEEK_BASE_URL=https://api.deepseek.com/v1" >> /home/testWeb/nofx/.env
    echo "DEEPSEEK_MODEL=deepseek-chat" >> /home/testWeb/nofx/.env
fi

# 重启服务
echo "🔄 重启服务..."
cd /home/testWeb/nofx
docker compose restart nofx

# 等待启动
sleep 10

# 验证
echo "✅ 验证服务状态..."
docker logs nofx-trading --tail 20 | grep -i "deepseek\|started"

echo "🎉 修复完成！"
```

---

## 配置优先级

系统会按以下优先级选择AI提供商：

1. **DEEPSEEK_API_KEY** - DeepSeek（如果配置）
2. **QWEN_API_KEY** - 阿里云通义千问（如果配置）
3. **OPENAI_API_KEY** - OpenAI（如果配置）
4. **环境变量中的其他AI配置**

**建议**: 配置多个AI提供商作为备份，系统会自动切换。

---

## 验证修复

### 1. 检查日志
```bash
docker logs nofx-trading --tail 50 | grep -i "ai\|error"
```

**正常输出应包含**:
```
✓ Using DeepSeek AI
或
✓ Using Alibaba Cloud Qwen AI
```

### 2. 测试API健康
```bash
curl http://localhost:8080/api/health
```

### 3. 检查交易决策
```bash
# 查看最近的AI决策
docker logs nofx-trading 2>&1 | grep "AI decision" | tail -10
```

### 4. 通过Web界面验证
访问: http://43.134.70.26:3000
- 查看Dashboard是否正常显示
- 启动一个交易者
- 观察是否有新的AI决策生成

---

## 常见问题

### Q1: 配置后仍然报错
**检查**:
```bash
# 1. 确认API密钥格式正确
cat /home/testWeb/nofx/.env | grep API_KEY

# 2. 检查是否有多余的空格或引号
# API密钥不应该有引号: DEEPSEEK_API_KEY=sk-xxx  ✓
# 错误示例: DEEPSEEK_API_KEY="sk-xxx"  ✗

# 3. 重新启动服务
docker compose restart nofx
```

### Q2: 如何查看当前使用的AI提供商
```bash
docker logs nofx-trading 2>&1 | grep "Using.*AI" | tail -1
```

### Q3: 配置多个AI密钥后如何切换
在 `.env` 文件中，注释掉不想用的配置：
```bash
# 使用DeepSeek
DEEPSEEK_API_KEY=sk-xxx

# 不使用Qwen（注释掉）
#QWEN_API_KEY=sk-xxx
```

### Q4: API密钥在哪里配置
有两个地方可以配置：
1. **环境变量文件** (推荐): `/home/testWeb/nofx/.env`
2. **Web界面**: http://43.134.70.26:3000/settings → AI Models

建议在环境变量文件中配置，重启后生效。

---

## 成本估算

### DeepSeek（推荐）
- **免费额度**: 500万tokens/月
- **付费价格**: ¥0.001/1K tokens
- **预估成本**: 中等使用约¥5-20/月

### Qwen
- **免费额度**: 100万tokens（已用完）
- **付费价格**: ¥0.008/1K tokens (qwen-plus)
- **预估成本**: 中等使用约¥40-160/月

### OpenAI
- **免费额度**: 无
- **付费价格**: $0.15/1M tokens (gpt-4o-mini)
- **预估成本**: 中等使用约$7.5-30/月

---

## 推荐配置

### 小规模使用（个人）
```bash
# 仅配置DeepSeek
DEEPSEEK_API_KEY=sk-xxx
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
```

### 中等规模使用（团队）
```bash
# 主要使用DeepSeek
DEEPSEEK_API_KEY=sk-xxx
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat

# Qwen作为备份（付费）
QWEN_API_KEY=sk-xxx
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_MODEL=qwen-plus
```

### 专业使用（生产环境）
```bash
# OpenAI主力
OPENAI_API_KEY=sk-xxx
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini

# DeepSeek备份
DEEPSEEK_API_KEY=sk-xxx
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
```

---

## 立即行动

**最快解决方案（5分钟内）**:

1. 获取DeepSeek API密钥: https://platform.deepseek.com/
2. SSH连接服务器: `ssh testWeb@43.134.70.26`
3. 编辑配置: `nano /home/testWeb/nofx/.env`
4. 添加: `DEEPSEEK_API_KEY=sk-your-key-here`
5. 重启: `docker compose restart nofx`
6. 验证: `docker logs nofx-trading --tail 30`

---

**文档版本**: 1.0  
**创建时间**: 2026-01-21 22:55  
**适用版本**: NOFX v1.x

需要帮助？查看: [DEPLOYMENT_GUIDE_2026-01-21.md](DEPLOYMENT_GUIDE_2026-01-21.md)
