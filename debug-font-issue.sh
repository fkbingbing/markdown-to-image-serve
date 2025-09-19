#!/bin/bash
# 🔍 调试字体显示问题
# ==================

echo "🔍 调试字体显示问题"
echo "=================="
echo ""

echo "📋 当前修复状态检查..."

# 1. 检查PosterView.tsx修复内容
echo "1. 检查 PosterView.tsx 修复..."
if grep -q "posterSize.*desktop.*tablet.*mobile" src/components/PosterView.tsx; then
    echo "   ✅ 尺寸判断逻辑存在"
else
    echo "   ❌ 尺寸判断逻辑缺失"
fi

if grep -q "size={posterSize" src/components/PosterView.tsx; then
    echo "   ✅ size属性传递存在"
else
    echo "   ❌ size属性传递缺失"
fi

echo ""

# 2. 生成对比测试图片
echo "2. 生成对比测试图片..."

echo "🖥️  生成桌面版测试图片..."
DESKTOP_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🖥️ 桌面版字体测试\n\n**重要**：这段文字在桌面版中应该显示得很大！\n\n如果字体很小，说明修复未生效。\n\n## 测试内容\n- 标题应该很大\n- 正文应该清晰\n- 整体易读性强",
    "header": "桌面版测试",
    "footer": "1200px - 应该是大字体",
    "width": 1200,
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error')

echo "   结果: $DESKTOP_RESULT"

echo "📱 生成手机版测试图片..."
MOBILE_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📱 手机版字体测试\n\n**重要**：这段文字在手机版中应该显示得较小！\n\n如果与桌面版字体大小一样，说明修复未生效。\n\n## 测试内容\n- 标题应该相对较小\n- 正文紧凑\n- 适合手机阅读",
    "header": "手机版测试", 
    "footer": "400px - 应该是小字体",
    "width": 400,
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error')

echo "   结果: $MOBILE_RESULT"

echo ""
echo "🎯 验证方法："
echo "============="
echo ""
echo "请同时打开以下两个图片进行对比："
echo "🖥️  桌面版: $DESKTOP_RESULT"
echo "📱 手机版: $MOBILE_RESULT"
echo ""
echo "✅ 如果修复成功，您应该看到："
echo "   - 桌面版的字体明显比手机版大"
echo "   - 桌面版的标题和内容都更大更清晰"
echo "   - 手机版的字体相对紧凑"
echo ""
echo "❌ 如果修复失败，您会看到："
echo "   - 两个版本的字体大小几乎一样"
echo "   - 桌面版的字体仍然很小"
echo "   - 内容显示不完整或截断"
echo ""

# 3. 检查开发服务器日志
echo "📋 检查最近的开发服务器活动..."
echo "   (请检查另一个终端窗口的开发服务器日志)"
echo ""

echo "🔄 如果修复仍未生效，请尝试："
echo "   1. 重启开发服务器: 在另一个终端按 Ctrl+C，然后重新运行 ./start-dev.sh"
echo "   2. 清除浏览器缓存: 访问 http://localhost:3000 并强制刷新"
echo "   3. 检查控制台错误: 在开发者工具中查看是否有 JavaScript 错误"
