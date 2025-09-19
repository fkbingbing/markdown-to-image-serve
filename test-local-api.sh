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
