# 配置指南

## 环境变量配置

创建 `.env` 文件并添加以下配置：

```bash
# 应用基础配置
NEXT_PUBLIC_BASE_URL=http://localhost:3000
NODE_ENV=development

# Chrome 浏览器路径配置
# macOS 示例:
CHROME_PATH=/Applications/Google Chrome.app/Contents/MacOS/Google Chrome
# Linux 示例:
# CHROME_PATH=/usr/bin/google-chrome
# Windows 示例:
# CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe

# API 安全配置
# 设置此密码后，所有 API 调用都需要提供 password 参数
# 留空或删除此配置则跳过密码验证（向后兼容）
API_PASSWORD=your_secure_password_here
```

## 新功能说明

### 1. 自定义图片宽度功能

#### API 参数
- `width`: 图片宽度 (400-3840px，默认1200px)
- `height`: 图片高度 (300-2160px，默认800px)

#### 使用示例
```bash
curl -X POST 'http://localhost:3000/api/generatePosterImage' \
  -H 'Content-Type: application/json' \
  -d '{
    "markdown": "# 测试标题\n\n这是一个测试内容",
    "header": "自定义头部",
    "footer": "自定义底部",
    "theme": "SpringGradientWave",
    "width": 1920,
    "height": 1080,
    "password": "your_secure_password_here"
  }'
```

#### 响应格式
```json
{
  "url": "http://localhost:3000/uploads/posters/poster-1234567890.png",
  "filename": "poster-1234567890.png",
  "dimensions": {
    "width": 1920,
    "height": 1080,
    "requested": {
      "width": 1920,
      "height": 1080
    }
  },
  "fileSize": 256789,
  "generatedAt": "2024-01-15T10:30:45.123Z",
  "theme": "SpringGradientWave"
}
```

### 2. API 密码校验功能

#### 配置方式
1. 在 `.env` 文件中设置 `API_PASSWORD=your_secure_password`
2. 如果不设置密码，则跳过验证（向后兼容）

#### 认证失败响应
```json
{
  "error": "认证失败",
  "message": "请提供正确的API密码"
}
```

## 支持的参数列表

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `markdown` | string | ✅ | - | Markdown 内容 |
| `header` | string | ❌ | 当前日期 | 页眉文本 |
| `footer` | string | ❌ | 默认footer | 页脚文本 |
| `logo` | string | ❌ | /logo.png | Logo 图片URL |
| `theme` | string | ❌ | SpringGradientWave | 主题名称 |
| `width` | number | ❌ | 1200 | 图片宽度 (400-3840) |
| `height` | number | ❌ | 800 | 图片高度 (300-2160) |
| `password` | string | 条件 | - | API密码 (设置了API_PASSWORD时必需) |

## 错误处理

### 400 - 参数错误
```json
{
  "error": "参数错误",
  "message": "markdown 参数是必需的"
}
```

### 401 - 认证失败
```json
{
  "error": "认证失败", 
  "message": "请提供正确的API密码"
}
```

### 500 - 服务器错误
```json
{
  "error": "海报生成失败",
  "details": "具体错误信息 (仅开发环境)"
}
```

## 安全建议

1. **设置强密码**: 使用复杂的API密码
2. **HTTPS部署**: 生产环境使用HTTPS
3. **访问限制**: 配置防火墙或反向代理限制访问
4. **定期轮换**: 定期更换API密码
5. **日志监控**: 监控API调用日志，发现异常访问

## 部署配置

### Docker 环境变量
```bash
docker run -d \
  -p 3000:3000 \
  -e API_PASSWORD=your_secure_password \
  -e CHROME_PATH=/usr/bin/google-chrome-unstable \
  your-image:tag
```

### docker-compose 配置
```yaml
services:
  app:
    image: your-image:tag
    ports:
      - "3000:3000"
    environment:
      - API_PASSWORD=your_secure_password
      - CHROME_PATH=/usr/bin/google-chrome-unstable
```
