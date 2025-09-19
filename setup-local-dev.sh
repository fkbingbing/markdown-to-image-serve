#!/bin/bash
# 🛠️ 本机开发环境设置脚本
# ==============================

set -e

echo "🛠️  设置本机开发测试环境"
echo "=========================="
echo ""

# 检查Node.js和yarn是否安装
echo "🔍 检查开发环境..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo "请先安装Node.js: https://nodejs.org/"
    exit 1
fi

if ! command -v yarn &> /dev/null; then
    echo "📦 安装yarn..."
    npm install -g yarn
fi

echo "✅ Node.js 版本: $(node --version)"
echo "✅ Yarn 版本: $(yarn --version)"
echo ""

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在markdown-to-image-serve目录中运行此脚本"
    exit 1
fi

echo "📋 当前目录: $(pwd)"
echo ""

# 清理旧的依赖和缓存
echo "🧹 清理旧依赖和缓存..."
rm -rf node_modules
rm -rf .next
rm -f yarn.lock
rm -f package-lock.json

# 安装依赖
echo "📦 安装开发依赖..."
echo "   使用官方npm源确保稳定性"

yarn config set registry https://registry.npmjs.org/
yarn install

echo "✅ 依赖安装完成"
echo ""

# 检查关键依赖
echo "🔍 检查关键依赖..."
REQUIRED_DEPS=("next" "@next/mdx" "@mdx-js/loader" "@mdx-js/react" "puppeteer" "markdown-to-poster")

for dep in "${REQUIRED_DEPS[@]}"; do
    if [ -d "node_modules/$dep" ]; then
        echo "✅ $dep"
    else
        echo "❌ $dep (缺失)"
        yarn add "$dep"
    fi
done

echo ""

# 设置环境变量
echo "🔧 设置本地环境变量..."
cat > .env.local << EOF
# 本地开发环境配置
NODE_ENV=development
NEXT_PUBLIC_BASE_URL=http://localhost:3000
API_PASSWORD=123456

# Chrome路径 (macOS)
CHROME_PATH=/Applications/Google Chrome.app/Contents/MacOS/Google Chrome

# 如果没有Chrome，可以使用Chromium
# CHROME_PATH=/usr/bin/chromium

# 开发模式配置
NEXT_TELEMETRY_DISABLED=1
EOF

echo "✅ 环境变量已配置"
echo ""

# 创建开发启动脚本
cat > start-dev.sh << 'EOF'
#!/bin/bash
# 🚀 启动开发服务器

echo "🚀 启动开发服务器..."
echo "========================"
echo ""

# 设置开发模式环境变量
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1

# 检查端口是否被占用
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  端口3000已被占用"
    echo "正在终止占用端口的进程..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

echo "🏃‍♂️ 启动Next.js开发服务器..."
echo "访问地址: http://localhost:3000"
echo "API测试: http://localhost:3000/api/generatePosterImage"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

yarn dev
EOF

chmod +x start-dev.sh

# 创建API测试脚本
cat > test-local-api.sh << 'EOF'
#!/bin/bash
# 🧪 测试本地API

echo "🧪 测试本地API"
echo "=============="
echo ""

API_URL="http://localhost:3000"

# 检查服务是否运行
echo "🔌 检查服务状态..."
if ! curl -s "$API_URL" >/dev/null; then
    echo "❌ 服务未运行，请先启动: ./start-dev.sh"
    exit 1
fi

echo "✅ 服务正常运行"
echo ""

# 测试API
echo "🖼️  测试海报生成API..."

# 测试1: 手机尺寸 (应该使用mobile)
echo "📱 测试1: 手机尺寸 (400px - mobile)"
curl -s -X POST "$API_URL/api/generatePosterImage" \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📱 手机版测试\n\n这是手机版尺寸测试。字体应该相对较小，适合手机阅读。",
    "header": "📱 手机版",
    "footer": "宽度400px - mobile尺寸",
    "width": 400,
    "height": 600,
    "password": "123456"
  }' | jq .

echo ""

# 测试2: 平板尺寸 (应该使用tablet)
echo "📊 测试2: 平板尺寸 (800px - tablet)"
curl -s -X POST "$API_URL/api/generatePosterImage" \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📊 平板版测试\n\n这是平板版尺寸测试。字体应该适中，适合平板阅读。",
    "header": "📊 平板版",
    "footer": "宽度800px - tablet尺寸",
    "width": 800,
    "height": 600,
    "password": "123456"
  }' | jq .

echo ""

# 测试3: 桌面尺寸 (应该使用desktop)
echo "🖥️  测试3: 桌面尺寸 (1200px - desktop)"
curl -s -X POST "$API_URL/api/generatePosterImage" \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🖥️ 桌面版测试\n\n这是桌面版尺寸测试。字体应该较大，适合桌面阅读。\n\n## 测试内容\n- 这段文字应该清晰易读\n- 字体大小适合桌面显示\n- 行间距舒适\n\n**如果修复成功，这段文字应该明显比手机版大！**",
    "header": "🖥️ 桌面版",
    "footer": "宽度1200px - desktop尺寸",
    "width": 1200,
    "height": 800,
    "password": "123456"
  }' | jq .

echo ""
echo "🎉 API测试完成！"
echo "📖 查看生成的图片: http://localhost:3000/api/images/poster-*.png"
EOF

chmod +x test-local-api.sh

echo ""
echo "🎉 本地开发环境设置完成！"
echo ""
echo "🚀 启动开发服务器："
echo "   ./start-dev.sh"
echo ""
echo "🧪 测试API："
echo "   ./test-local-api.sh"
echo ""
echo "📂 项目结构："
echo "   ✅ 依赖已安装"
echo "   ✅ 环境变量已配置 (.env.local)"
echo "   ✅ 启动脚本已创建 (start-dev.sh)"
echo "   ✅ 测试脚本已创建 (test-local-api.sh)"
echo ""
echo "🔧 修复状态："
echo "   ✅ Chrome路径配置"
echo "   ✅ 内容尺寸修复 (PosterView.tsx)"
echo "   ✅ MDX依赖配置"
echo ""
echo "💡 开发提示："
echo "   - 开发模式支持热重载"
echo "   - 修改代码会自动生效"
echo "   - 按 Ctrl+C 停止服务器"
