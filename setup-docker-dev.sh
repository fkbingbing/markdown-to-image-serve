#!/bin/bash
# 🐳 Docker开发环境设置（无需升级Node.js）
# ========================================

set -e

echo "🐳 Docker开发环境设置"
echo "===================="
echo ""

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    echo "请先安装Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "✅ Docker版本: $(docker --version)"
echo ""

# 创建开发用的docker-compose文件
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - NEXT_PUBLIC_BASE_URL=http://localhost:3000
      - CHROME_PATH=/usr/bin/chromium
      - API_PASSWORD=123456
    volumes:
      # 挂载源代码以支持热重载
      - ./src:/app/src:delegated
      - ./public:/app/public:delegated
      - ./next.config.mjs:/app/next.config.mjs:ro
      - ./.env.local:/app/.env.local:ro
      # 保持依赖和构建产物
      - node_modules_cache:/app/node_modules
      - next_cache:/app/.next
    command: yarn dev
    stdin_open: true
    tty: true

volumes:
  node_modules_cache:
  next_cache:
EOF

# 创建开发环境变量文件
cat > .env.local << EOF
NODE_ENV=development
NEXT_PUBLIC_BASE_URL=http://localhost:3000
API_PASSWORD=123456
CHROME_PATH=/usr/bin/chromium
NEXT_TELEMETRY_DISABLED=1
EOF

# 创建Docker开发启动脚本
cat > start-docker-dev.sh << 'EOF'
#!/bin/bash
# 🚀 启动Docker开发环境

echo "🚀 启动Docker开发环境..."
echo "========================="
echo ""

# 停止现有容器
echo "🧹 清理现有容器..."
docker-compose -f docker-compose.dev.yml down

# 构建并启动开发容器
echo "🏗️  构建开发镜像..."
docker-compose -f docker-compose.dev.yml build --no-cache

echo "🚀 启动开发容器..."
docker-compose -f docker-compose.dev.yml up -d

echo "✅ 开发环境已启动"
echo ""
echo "🌐 访问地址: http://localhost:3000"
echo "🔍 查看日志: docker-compose -f docker-compose.dev.yml logs -f"
echo "⏹️  停止服务: docker-compose -f docker-compose.dev.yml down"
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 测试服务
if curl -s http://localhost:3000 >/dev/null; then
    echo "✅ 开发服务器已就绪！"
else
    echo "⚠️  服务可能还在启动中..."
    echo "📋 查看详细日志: docker-compose -f docker-compose.dev.yml logs app"
fi
EOF

chmod +x start-docker-dev.sh

# 创建Docker API测试脚本
cat > test-docker-api.sh << 'EOF'
#!/bin/bash
# 🧪 测试Docker开发环境API

echo "🧪 测试Docker开发环境API"
echo "========================"
echo ""

API_URL="http://localhost:3000"

# 检查服务是否运行
echo "🔌 检查服务状态..."
if ! curl -s "$API_URL" >/dev/null; then
    echo "❌ 服务未运行，请先启动: ./start-docker-dev.sh"
    exit 1
fi

echo "✅ 服务正常运行"
echo ""

# 测试内容尺寸修复
echo "🖼️  测试内容尺寸修复..."

echo "📱 手机版测试 (400px):"
curl -s -X POST "$API_URL/api/generatePosterImage" \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📱 手机版\n\n字体应该较小，适合手机阅读。",
    "header": "手机版测试",
    "width": 400,
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error'

echo ""

echo "🖥️  桌面版测试 (1200px):"
curl -s -X POST "$API_URL/api/generatePosterImage" \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🖥️ 桌面版\n\n字体应该较大，适合桌面阅读。\n\n如果修复成功，这段文字应该比手机版明显更大！",
    "header": "桌面版测试",
    "width": 1200,
    "height": 800,
    "password": "123456"
  }' | jq -r '.url // .error'

echo ""
echo "🎉 测试完成！"
echo "📖 在浏览器中查看生成的图片进行对比"
EOF

chmod +x test-docker-api.sh

echo ""
echo "🎉 Docker开发环境设置完成！"
echo ""
echo "📂 创建的文件："
echo "   ✅ docker-compose.dev.yml - 开发环境配置"
echo "   ✅ .env.local - 环境变量"
echo "   ✅ start-docker-dev.sh - 启动脚本"
echo "   ✅ test-docker-api.sh - 测试脚本"
echo ""
echo "🚀 启动开发环境："
echo "   ./start-docker-dev.sh"
echo ""
echo "🧪 测试API："
echo "   ./test-docker-api.sh"
echo ""
echo "💡 优势："
echo "   ✅ 无需升级本机Node.js"
echo "   ✅ 隔离的开发环境"
echo "   ✅ 支持代码热重载"
echo "   ✅ 一键启动和测试"
