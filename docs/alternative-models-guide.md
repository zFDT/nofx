# Qwen备用模型自动切换指南

## 功能说明

当使用Qwen API时，如果主模型的配额用完（返回403错误），系统会自动切换到备用模型继续运行，无需手动干预。

## 工作原理

系统会尝试所有模型组合：
1. **主模型** (custom_model_name): 如 `qwen-plus`
2. **备用模型** (alternative_models): 逗号分隔的模型列表

当遇到配额错误时：
- 先重试主模型3次
- 如果仍然失败，切换到第一个备用模型
- 依次尝试所有备用模型
- 如果所有模型都失败，返回错误

## 当前配置

### 主模型
- **qwen-plus**: 主力模型

### 备用模型（按顺序）
1. **qwen-turbo** - 快速、便宜、适合高频请求
2. **qwen-plus-latest** - 最新版本的plus模型
3. **qwen-max-latest** - 高性能模型
4. **qwen-long-latest** - 长文本支持
5. **qwen-flash** - 超快速响应
6. **qwq-plus** - 强推理能力
7. **deepseek-v3** - 终极备份（跨提供商）

## 查看配置

### 方法1: 查看数据库
```bash
docker exec nofx-trading sqlite3 /app/data/data.db \
  "SELECT provider, custom_model_name, alternative_models FROM ai_models WHERE provider='qwen';"
```

### 方法2: 查看启动日志
```bash
docker logs nofx-trading | grep -i "alternative"
```

应该看到类似输出：
```
✓ Loaded 7 alternative Qwen models for failover: 
[qwen-turbo qwen-plus-latest qwen-max-latest qwen-long-latest qwen-flash qwq-plus deepseek-v3]
```

## 手动更新配置

### 方法1: 使用脚本（推荐）
```bash
cd /home/testWeb/nofx-source
chmod +x scripts/update-alternative-models.sh
./scripts/update-alternative-models.sh
```

### 方法2: 直接修改数据库
```bash
# 连接服务器
ssh testWeb@43.134.70.26

# 更新配置
docker exec nofx-trading sqlite3 /app/data/data.db \
  "UPDATE ai_models SET alternative_models='qwen-turbo,qwen-flash,qwen-max-latest' WHERE provider='qwen';"

# 重启服务
cd /home/testWeb/nofx
docker compose restart nofx
```

### 方法3: 通过Web界面（推荐 - 未来支持）
访问: http://43.134.70.26:3000/settings → AI Models
在"Alternative Models"字段中输入逗号分隔的模型名称

## 推荐的模型组合

### 策略1: 成本优先
```
qwen-turbo,qwen-flash,qwen-plus-latest
```
- 优先使用便宜的模型
- 适合预算有限的场景

### 策略2: 性能优先
```
qwen-max-latest,qwen-plus-latest,qwen-turbo
```
- 优先使用高性能模型
- 适合对质量要求高的场景

### 策略3: 平衡策略（当前使用）
```
qwen-turbo,qwen-plus-latest,qwen-max-latest,qwen-long-latest,qwen-flash,qwq-plus,deepseek-v3
```
- 平衡成本和性能
- 多层次降级
- 跨提供商备份（deepseek-v3）

### 策略4: 全模型覆盖
使用 `qwen-models-batch-import.txt` 中的所有模型：
```bash
qwen-plus,qwen-turbo,qwen-flash,qwen-max-latest,qwen-long-latest,qwq-plus,qwen-vl-max,qvq-max,deepseek-v3.2,qwen-coder-plus,glm-4.7,kimi-k2-thinking
```

## 验证自动切换

### 测试方法
1. 启动一个交易者
2. 观察日志中的AI调用
3. 当主模型配额用完时，会看到：
```
⚠️  Quota exceeded for model qwen-plus
🔄 Switching to model: qwen-turbo
✓ AI API call succeeded with key 1 model qwen-turbo
```

### 监控日志
```bash
# 实时监控AI调用
docker logs -f nofx-trading | grep -i "ai\|model\|quota"

# 查看最近的错误和切换
docker logs nofx-trading --tail 200 | grep -E "failed|exceeded|switching"
```

## 故障排查

### 问题1: 备用模型未加载
**症状**: 日志中没有 "Loaded alternative models" 信息

**检查**:
```bash
# 1. 确认数据库配置
docker exec nofx-trading sqlite3 /app/data/data.db \
  "SELECT alternative_models FROM ai_models WHERE provider='qwen';"

# 2. 如果为空，手动配置
docker exec nofx-trading sqlite3 /app/data/data.db \
  "UPDATE ai_models SET alternative_models='qwen-turbo,qwen-flash' WHERE provider='qwen';"

# 3. 重启服务
docker compose restart nofx
```

### 问题2: 所有模型都配额用完
**症状**: 日志显示 "all X combinations failed"

**解决方案**:
1. 添加更多备用模型
2. 配置其他AI提供商（DeepSeek、OpenAI）
3. 等待Qwen配额重置（通常按月重置）

### 问题3: 切换后仍然报错
**可能原因**:
- 备用模型也没有配额
- API密钥无效
- 网络问题

**检查**:
```bash
# 查看详细错误
docker logs nofx-trading --tail 100 | grep -i "error"

# 测试API密钥
curl -X POST https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen-turbo","messages":[{"role":"user","content":"test"}]}'
```

## 模型对比

| 模型 | 速度 | 成本 | 性能 | 推荐场景 |
|------|------|------|------|---------|
| qwen-turbo | ⚡⚡⚡ | 💰 | ⭐⭐⭐ | 高频交易、快速决策 |
| qwen-plus | ⚡⚡ | 💰💰 | ⭐⭐⭐⭐ | 通用场景、平衡 |
| qwen-max | ⚡ | 💰💰💰 | ⭐⭐⭐⭐⭐ | 复杂分析、高要求 |
| qwen-flash | ⚡⚡⚡⚡ | 💰 | ⭐⭐ | 超快响应、简单任务 |
| qwen-long | ⚡ | 💰💰 | ⭐⭐⭐⭐ | 长文本、深度分析 |
| qwq-plus | ⚡ | 💰💰💰 | ⭐⭐⭐⭐⭐ | 复杂推理、策略优化 |

## 最佳实践

### 1. 定期检查配额使用
```bash
# 查看最近的配额错误
docker logs nofx-trading | grep -i "quota\|exceeded" | tail -20
```

### 2. 监控模型切换频率
```bash
# 统计模型切换次数
docker logs nofx-trading | grep "Switching to model" | wc -l
```

### 3. 优化模型顺序
- 将最常用的模型放在前面
- 将备用额度大的模型放在中间
- 将跨提供商的模型（如deepseek）放在最后

### 4. 配置多个API密钥
除了配置多个模型，还可以配置多个Qwen API密钥：
```bash
# 在Web界面中添加多个Qwen配置
# 系统会自动尝试所有 (密钥 × 模型) 的组合
```

## 成本优化建议

### 低成本配置（每月<¥20）
```
主模型: qwen-turbo
备用: qwen-flash, qwen-plus-latest
```

### 中等成本配置（每月¥20-50）
```
主模型: qwen-plus
备用: qwen-turbo, qwen-max-latest, qwen-flash
```

### 高性能配置（每月>¥50）
```
主模型: qwen-max-latest
备用: qwen-plus-latest, qwq-plus, qwen-long-latest
```

## 相关文档

- [AI_API_FIX_GUIDE.md](../AI_API_FIX_GUIDE.md) - AI API故障修复指南
- [DEPLOYMENT_GUIDE_2026-01-21.md](../DEPLOYMENT_GUIDE_2026-01-21.md) - 部署指南
- Git Commit: `512dd9f` - 添加备用模型支持的提交

## 更新日志

- **2026-01-21**: 首次配置7个备用模型
- **2026-01-21**: 创建此文档和管理脚本

---

**提示**: 配置备用模型后，系统会在配额用完时自动切换，无需人工干预。建议定期查看日志以了解切换情况。
