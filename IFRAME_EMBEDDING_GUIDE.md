# Open WebUI iframe 嵌入配置指南

## 问题描述
在 iframe 中嵌入 Open WebUI 时,可能会出现以下错误:
```
Unexpected token 'd', "data: {"id"... is not valid JSON
```

## 已修复的问题
本次更新已修复以下问题:

1. **前端 SSE 流式响应解析**:增强了 `src/lib/apis/streaming/index.ts` 中的流式响应处理器,能够正确处理包含 `data: ` 前缀的 SSE 格式数据。

2. **后端 X-Frame-Options 默认值**:将 `X-Frame-Options` 的默认值从 `DENY` 改为 `SAMEORIGIN`,允许同源 iframe 嵌入。

## 配置选项

### 场景 1:同源嵌入 (最简单,推荐)
如果父页面和 Open WebUI 在同一域名下:

**无需额外配置**,修改后的默认设置已支持。

```bash
# .env 文件 - 可选,因为已经是默认值
XFRAME_OPTIONS=SAMEORIGIN
```

### 场景 2:跨域嵌入 - 单个域名
如果父页面和 Open WebUI 在不同域名下,需要同时配置 `X-Frame-Options` 和 `Content-Security-Policy`:

#### 步骤 1:编辑 .env 文件
```bash
# .env 文件
# 保持 X-Frame-Options 为 SAMEORIGIN (作为后备)
XFRAME_OPTIONS=SAMEORIGIN

# 配置 CSP 允许特定域名嵌入 (替换为您的实际域名)
CONTENT_SECURITY_POLICY="frame-ancestors 'self' https://your-parent-domain.com"
```

#### 步骤 2:配置 CORS (允许 API 跨域访问)
```bash
# .env 文件
CORS_ALLOW_ORIGIN=https://your-parent-domain.com
```

#### 步骤 3:重启服务
```bash
# Docker 部署
docker restart open-webui

# 或直接运行
docker-compose restart
```

### 场景 3:跨域嵌入 - 多个域名
如果需要允许多个不同的域名嵌入:

```bash
# .env 文件
XFRAME_OPTIONS=SAMEORIGIN

# 允许多个域名 (空格分隔)
CONTENT_SECURITY_POLICY="frame-ancestors 'self' https://domain1.com https://domain2.com https://domain3.com"

# 配置 CORS (分号分隔)
CORS_ALLOW_ORIGIN=https://domain1.com;https://domain2.com;https://domain3.com
```

### 场景 4:开发环境 - 允许所有域名 (不推荐生产使用)
```bash
# .env 文件 - 仅用于本地开发测试
XFRAME_OPTIONS=SAMEORIGIN
CONTENT_SECURITY_POLICY="frame-ancestors *"
CORS_ALLOW_ORIGIN=*
```

⚠️ **安全警告**: 此配置会允许任何网站嵌入您的 Open WebUI,存在点击劫持风险,切勿在生产环境使用!

### 场景 5:Docker 部署跨域配置
如果使用 Docker,通过环境变量传递配置:

```bash
docker run -d \
  -p 3000:8080 \
  -e XFRAME_OPTIONS=SAMEORIGIN \
  -e CONTENT_SECURITY_POLICY="frame-ancestors 'self' https://your-parent-domain.com" \
  -e CORS_ALLOW_ORIGIN=https://your-parent-domain.com \
  -v open-webui:/app/backend/data \
  --name open-webui \
  ghcr.io/open-webui/open-webui:main
```

或在 `docker-compose.yml` 中:
```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    environment:
      - XFRAME_OPTIONS=SAMEORIGIN
      - CONTENT_SECURITY_POLICY=frame-ancestors 'self' https://your-parent-domain.com
      - CORS_ALLOW_ORIGIN=https://your-parent-domain.com
    # ... 其他配置
```

## iframe 使用示例

### 基本用法
```html
<iframe 
  src="http://localhost:3000" 
  width="100%" 
  height="600px"
  frameborder="0"
  allow="microphone; camera"
></iframe>
```

### 带认证令牌
如果 Open WebUI 启用了认证,需要在父页面中处理登录状态:

```javascript
// 方法 1: 用户在 iframe 中直接登录
// iframe 会显示登录页面,用户在其中输入凭据

// 方法 2: 通过 postMessage 传递令牌 (需要自定义实现)
const iframe = document.getElementById('open-webui-iframe');
iframe.contentWindow.postMessage({
  type: 'auth',
  token: 'your-auth-token'
}, 'http://localhost:3000');
```

## 故障排除

### 问题 1:仍然看到 JSON 解析错误
**解决方案**:
1. 确保重新构建了前端: `npm run build`
2. 清除浏览器缓存
3. 检查浏览器控制台是否有 CORS 错误

### 问题 2:CORS 错误
**错误信息**:
```
Access to fetch at '...' from origin '...' has been blocked by CORS policy
```

**解决方案**:
```bash
# 确保 CORS_ALLOW_ORIGIN 包含父页面的域名
CORS_ALLOW_ORIGIN=https://your-parent-domain.com
```

### 问题 3:X-Frame-Options 阻止加载
**错误信息** (在浏览器控制台中):
```
Refused to display '...' in a frame because it set 'X-Frame-Options' to 'deny'
```

**解决方案**:
```bash
# 设置环境变量
XFRAME_OPTIONS=SAMEORIGIN

# 或者对于跨域情况,使用 CSP
CONTENT_SECURITY_POLICY="frame-ancestors *"
```

### 问题 4:WebSocket 连接失败
如果在 iframe 中 WebSocket 连接失败:

**解决方案**:
1. 确保 WebSocket URL 正确配置
2. 检查防火墙/代理是否允许 WebSocket 连接
3. 验证 `WEBSOCKET_MANAGER` 配置

## 安全建议

1. **生产环境**:始终指定明确的域名,避免使用通配符 `*`
2. **最小权限原则**:只允许必要的域名嵌入
3. **HTTPS**:在生产环境中始终使用 HTTPS
4. **认证**:如果启用认证,确保令牌传输安全
5. **监控**:定期检查访问日志,发现异常嵌入行为

## 技术细节

### SSE (Server-Sent Events) 格式
Open WebUI 使用 SSE 进行流式响应,标准格式为:
```
data: {"choices": [{"delta": {"content": "Hello"}}]}

data: {"choices": [{"delta": {"content": " World"}}]}

data: [DONE]

```

之前的代码在某些情况下(特别是跨域 iframe)会将整个 `data: {...}` 字符串当作 JSON 解析,导致错误。修复后的代码会先剥离 `data: ` 前缀再解析 JSON。

### X-Frame-Options 头部
- `DENY`: 不允许任何域名嵌入
- `SAMEORIGIN`: 只允许同源域名嵌入
- `ALLOW-FROM uri`: 允许指定 URI 嵌入 (已过时,推荐使用 CSP)

现代浏览器更推荐使用 Content-Security-Policy 的 `frame-ancestors` 指令。

## 相关代码文件

- 前端流式处理: `src/lib/apis/streaming/index.ts`
- 后端安全头: `backend/open_webui/utils/security_headers.py`
- CORS 配置: `backend/open_webui/config.py`
- 主应用: `backend/open_webui/main.py`