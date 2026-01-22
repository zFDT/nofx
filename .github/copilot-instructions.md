# GitHub Copilot 开发指导手册

## 项目概述

**NOFX** 是一个开源的AI驱动的多资产交易平台，支持加密货币、美股、外汇等多种资产类型的自动化交易。

### 核心技术栈
- **后端**: Go 1.25+
- **前端**: React 18+ + TypeScript 5.0+
- **数据库**: SQLite (modernc.org/sqlite)
- **实时通信**: WebSocket (gorilla/websocket)
- **Web框架**: Gin (gin-gonic/gin)
- **日志**: Zerolog
- **加密**: Go crypto 库
- **容器化**: Docker + Docker Compose

### 支持的交易所
- **中心化交易所**: Binance, Bybit, OKX, Bitget
- **去中心化永续合约交易所**: Hyperliquid, Aster DEX, Lighter

### 支持的AI模型
DeepSeek, Qwen, OpenAI GPT, Claude, Gemini, Grok, Kimi

---

## 项目架构

### 目录结构

```
nofx/
├── main.go              # 主入口文件
├── go.mod               # Go 模块依赖
├── .env                 # 环境变量配置
├── api/                 # HTTP API 层
│   ├── server.go        # API 服务器
│   ├── crypto_handler.go
│   ├── debate.go
│   └── strategy.go
├── auth/                # 认证模块
│   └── auth.go          # JWT 认证
├── backtest/            # 回测引擎
│   ├── runner.go        # 回测运行器
│   ├── ai_client.go     # AI 客户端
│   ├── storage.go       # 数据存储
│   └── metrics.go       # 性能指标
├── config/              # 配置管理
│   └── config.go
├── crypto/              # 加密服务
│   └── crypto.go        # 数据加密/解密
├── debate/              # AI 辩论引擎
│   └── engine.go
├── experience/          # 经验值系统
│   └── experience.go
├── hook/                # 钩子系统
│   ├── hooks.go
│   ├── trader_hook.go
│   └── ip_hook.go
├── kernel/              # 核心交易引擎
│   ├── engine.go
│   └── formatter.go
├── llm/                 # LLM 提供商集成
│   ├── factory.go
│   ├── provider.go
│   └── [各个AI模型实现]
├── logger/              # 日志系统
│   └── logger.go
├── manager/             # 交易管理器
│   └── [管理器实现]
├── market/              # 市场数据
│   └── [市场数据实现]
├── mcp/                 # MCP 协议支持
│   └── client.go
├── provider/            # 数据提供商
├── security/            # 安全模块
├── store/               # 数据持久化
│   └── [数据库操作]
├── trader/              # 交易所适配器
│   ├── bitget_trader.go
│   ├── binance_trader.go
│   ├── bybit_trader.go
│   └── [其他交易所]
├── version/             # 版本信息
│   └── version.go
└── web/                 # 前端资源
```

---

## 编码规范

### Go 代码规范

#### 1. 命名规范
- **包名**: 小写单个词，如 `config`, `trader`, `backtest`
- **文件名**: 小写+下划线，如 `bitget_trader.go`
- **类型名**: 大驼峰，如 `TraderConfig`, `AIClient`
- **函数名**: 大驼峰（导出）或小驼峰（内部），如 `GetAvailableSymbols()`, `isSymbolValid()`
- **变量名**: 小驼峰，如 `traderId`, `maxRetries`
- **常量名**: 大驼峰或全大写（短常量），如 `MaxRetryAttempts`, `DEBUG`

#### 2. 错误处理
```go
// ✅ 推荐：立即检查错误
result, err := someFunction()
if err != nil {
    logger.Errorf("Failed to execute: %v", err)
    return nil, fmt.Errorf("operation failed: %w", err)
}

// ❌ 避免：延迟错误检查
result, err := someFunction()
// ... 其他代码
if err != nil { ... }
```

#### 3. 日志规范
使用项目的 `logger` 包，不要直接使用 `fmt.Println` 或 `log.Println`:

```go
logger.Info("Starting trading bot")
logger.Infof("Trading pair: %s", symbol)
logger.Warn("API rate limit approaching")
logger.Error("Failed to connect to exchange")
logger.Errorf("Connection error: %v", err)
logger.Fatal("Critical error, shutting down")
```

#### 4. 结构体定义
```go
// ✅ 推荐：带注释、JSON标签、数据库标签
type TradingConfig struct {
    // Symbol is the trading pair (e.g., BTCUSDT)
    Symbol string `json:"symbol" db:"symbol"`
    
    // Leverage for the position (1-125)
    Leverage int `json:"leverage" db:"leverage"`
    
    // MarginMode: "isolated" or "crossed"
    MarginMode string `json:"margin_mode" db:"margin_mode"`
}
```

#### 5. 接口设计
```go
// Trader 接口定义了所有交易所必须实现的方法
type Trader interface {
    // OpenLong 开多单
    OpenLong(symbol string, amount float64) error
    
    // OpenShort 开空单
    OpenShort(symbol string, amount float64) error
    
    // ClosePosition 平仓
    ClosePosition(symbol string) error
    
    // GetBalance 获取余额
    GetBalance() (float64, error)
    
    // IsSymbolValid 检查交易对是否有效
    IsSymbolValid(symbol string) bool
}
```

#### 6. 上下文使用
对于长时间运行的操作，使用 `context.Context`:

```go
func (t *Trader) FetchData(ctx context.Context) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
        // 执行操作
    }
}
```

#### 7. 并发安全
使用互斥锁保护共享资源:

```go
type SafeMap struct {
    mu    sync.RWMutex
    data  map[string]interface{}
}

func (m *SafeMap) Get(key string) (interface{}, bool) {
    m.mu.RLock()
    defer m.mu.RUnlock()
    val, ok := m.data[key]
    return val, ok
}

func (m *SafeMap) Set(key string, value interface{}) {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.data[key] = value
}
```

### TypeScript/React 代码规范

#### 1. 组件结构
```typescript
// ✅ 推荐：函数式组件 + TypeScript
import React, { useState, useEffect } from 'react';

interface TradingPanelProps {
    traderId: string;
    onUpdate?: (data: any) => void;
}

export const TradingPanel: React.FC<TradingPanelProps> = ({ 
    traderId, 
    onUpdate 
}) => {
    const [positions, setPositions] = useState<Position[]>([]);
    
    useEffect(() => {
        // 副作用逻辑
    }, [traderId]);
    
    return (
        <div className="trading-panel">
            {/* UI 内容 */}
        </div>
    );
};
```

#### 2. API 调用
```typescript
// 使用统一的 API 客户端
import { apiClient } from '@/utils/api';

const fetchPositions = async (traderId: string) => {
    try {
        const response = await apiClient.get(`/api/traders/${traderId}/positions`);
        return response.data;
    } catch (error) {
        console.error('Failed to fetch positions:', error);
        throw error;
    }
};
```

---

## 交易系统核心概念

### 1. 交易对验证
在执行任何交易操作前，必须验证交易对是否有效：

```go
// ✅ 正确的流程
if !trader.IsSymbolValid(symbol) {
    return fmt.Errorf("symbol %s is not available or has been delisted", symbol)
}

// 然后执行交易
err := trader.OpenLong(symbol, amount)
```

### 2. 保证金模式管理
在设置保证金模式前，检查当前模式：

```go
// ✅ 避免不必要的 API 调用
currentMode, err := trader.GetMarginMode(symbol)
if err != nil {
    return err
}

if currentMode != desiredMode {
    err = trader.SetMarginMode(symbol, desiredMode)
    if err != nil {
        return err
    }
}
```

### 3. API 限流处理
交易所 API 都有限流，需要合理处理：

```go
// 使用重试机制
const maxRetries = 3
var err error
for i := 0; i < maxRetries; i++ {
    err = trader.SomeOperation()
    if err == nil {
        break
    }
    
    if isRateLimitError(err) {
        time.Sleep(time.Second * time.Duration(i+1))
        continue
    }
    
    return err // 非限流错误，直接返回
}
```

### 4. 数据加密
敏感数据（API Key, Secret）必须加密存储：

```go
// 存储时加密
encryptedKey, err := cryptoService.Encrypt(apiKey)
if err != nil {
    return err
}

// 使用时解密
apiKey, err := cryptoService.Decrypt(encryptedKey)
if err != nil {
    return err
}
```

---

## AI 集成规范

### 1. LLM Provider 接口
```go
type LLMProvider interface {
    // Chat 发送消息并获取回复
    Chat(ctx context.Context, messages []Message) (string, error)
    
    // StreamChat 流式聊天
    StreamChat(ctx context.Context, messages []Message, callback func(string)) error
    
    // GetModelName 获取模型名称
    GetModelName() string
}
```

### 2. AI 决策日志
所有 AI 决策都应该记录：

```go
logger.Infof("[AI Decision] Model: %s, Symbol: %s, Decision: %s, Confidence: %.2f", 
    modelName, symbol, decision, confidence)
```

### 3. Chain of Thought
在请求 AI 时，要求其提供思考过程：

```go
systemPrompt := `You are a professional trader. When making decisions:
1. Analyze the current market conditions
2. Consider technical indicators
3. Evaluate risk/reward ratio
4. Provide your reasoning (Chain of Thought)
5. Make a final decision (BUY/SELL/HOLD)`
```

---

## 测试规范

### 1. 单元测试
```go
func TestIsSymbolValid(t *testing.T) {
    trader := NewBitgetTrader(config)
    
    // 测试有效交易对
    assert.True(t, trader.IsSymbolValid("BTCUSDT"))
    
    // 测试无效交易对
    assert.False(t, trader.IsSymbolValid("INVALIDPAIR"))
}
```

### 2. 集成测试
使用 Mock 进行集成测试，避免调用真实 API：

```go
type MockExchangeAPI struct {
    mock.Mock
}

func (m *MockExchangeAPI) GetBalance() (float64, error) {
    args := m.Called()
    return args.Get(0).(float64), args.Error(1)
}
```

---

## 安全注意事项

### 1. 永远不要硬编码密钥
```go
// ❌ 错误
apiKey := "hardcoded-api-key"

// ✅ 正确
apiKey := os.Getenv("EXCHANGE_API_KEY")
if apiKey == "" {
    logger.Fatal("EXCHANGE_API_KEY not set")
}
```

### 2. 验证用户输入
```go
func validateSymbol(symbol string) error {
    if symbol == "" {
        return errors.New("symbol cannot be empty")
    }
    
    // 只允许字母和数字
    matched, _ := regexp.MatchString("^[A-Z0-9]+$", symbol)
    if !matched {
        return errors.New("invalid symbol format")
    }
    
    return nil
}
```

### 3. 使用 HTTPS
所有 API 调用必须使用 HTTPS。

---

## 性能优化

### 1. 数据库查询优化
```go
// ❌ N+1 查询问题
for _, trader := range traders {
    positions := db.GetPositions(trader.ID)
    // ...
}

// ✅ 批量查询
traderIDs := extractIDs(traders)
positions := db.GetPositionsByTraderIDs(traderIDs)
```

### 2. 缓存策略
对于不常变化的数据（如交易对列表），使用缓存：

```go
type SymbolCache struct {
    symbols   []string
    updatedAt time.Time
    mu        sync.RWMutex
}

func (c *SymbolCache) Get() []string {
    c.mu.RLock()
    defer c.mu.RUnlock()
    
    // 缓存1小时
    if time.Since(c.updatedAt) > time.Hour {
        return nil // 需要刷新
    }
    
    return c.symbols
}
```

### 3. Goroutine 管理
使用 Worker Pool 模式管理并发：

```go
func processSymbols(symbols []string, workers int) {
    jobs := make(chan string, len(symbols))
    results := make(chan Result, len(symbols))
    
    // 启动 workers
    for w := 0; w < workers; w++ {
        go worker(jobs, results)
    }
    
    // 分发任务
    for _, symbol := range symbols {
        jobs <- symbol
    }
    close(jobs)
    
    // 收集结果
    for i := 0; i < len(symbols); i++ {
        <-results
    }
}
```

---

## 部署相关

### 1. 环境变量
所有配置通过环境变量管理，`.env` 文件示例：

```env
# 服务器配置
PORT=8080
GIN_MODE=release

# 数据库
DB_PATH=./data/nofx.db

# 加密密钥
ENCRYPTION_KEY=your-32-byte-encryption-key

# 交易所 API（示例）
BINANCE_API_KEY=
BINANCE_SECRET_KEY=

# AI 模型
DEEPSEEK_API_KEY=
OPENAI_API_KEY=
```

### 2. Docker 构建
```dockerfile
# 多阶段构建
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=1 go build -o nofx .

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /root/
COPY --from=builder /app/nofx .
EXPOSE 8080
CMD ["./nofx"]
```

### 3. 健康检查
```go
// 添加健康检查端点
router.GET("/health", func(c *gin.Context) {
    c.JSON(200, gin.H{
        "status": "ok",
        "version": version.Get().Version,
        "uptime": time.Since(startTime).String(),
    })
})
```

---

## Git 工作流

请参考 [git-commit-instructions.md](git-commit-instructions.md) 了解完整的 Git 工作流规范。

---

## 常见问题解决

### 1. 交易对被移除错误 (40309)
**问题**: `The symbol has been removed`
**解决**: 启动时调用 `GetAvailableSymbols()` 加载可用交易对，使用前调用 `IsSymbolValid()` 验证

### 2. 保证金模式不一致
**问题**: 机器人配置的保证金模式与交易所不一致
**解决**: 设置前先调用 `GetMarginMode()` 检查当前模式

### 3. API 限流
**问题**: `429 Too Many Requests`
**解决**: 实现指数退避重试机制，合理控制请求频率

### 4. 数据库锁
**问题**: `database is locked`
**解决**: 
- 使用连接池
- 设置合理的 busy_timeout
- 避免长事务

---

## 开发辅助工具

### 1. 日志分析
```bash
# 查看错误日志
grep "ERROR" logs/nofx.log

# 查看特定交易对的日志
grep "BTCUSDT" logs/nofx.log

# 实时查看日志
tail -f logs/nofx.log
```

### 2. 数据库查询
```bash
# 查看所有机器人
sqlite3 data/nofx.db "SELECT * FROM traders;"

# 查看交易记录
sqlite3 data/nofx.db "SELECT * FROM trades ORDER BY created_at DESC LIMIT 10;"
```

---

## 参考资源

- [Go 官方文档](https://golang.org/doc/)
- [Gin 框架文档](https://gin-gonic.com/docs/)
- [React 官方文档](https://react.dev/)
- [TypeScript 手册](https://www.typescriptlang.org/docs/)

---

## 联系方式

- **官方网站**: https://nofxai.com
- **Twitter**: [@nofx_official](https://x.com/nofx_official)
- **开发者社区**: [Telegram](https://t.me/nofx_dev_community)

---

**最后更新**: 2026-01-22
