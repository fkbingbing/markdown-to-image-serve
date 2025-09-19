#!/bin/bash
# 🔥 热修复运行中的Docker容器（无需重启）
# ===========================================

set -e

echo "🔥 热修复运行中的Docker容器"
echo "=========================="
echo ""

# 查找运行中的容器
echo "🔍 查找运行中的容器..."
CONTAINER_ID=$(docker ps -q --filter "ancestor=markdown-to-image-serve:latest" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 未找到运行中的 markdown-to-image-serve 容器"
    echo "请先启动容器，或使用 ./apply-fixes-to-docker.sh"
    exit 1
fi

echo "✅ 找到容器: $CONTAINER_ID"
echo ""

# 检查修复文件
echo "🔍 检查修复文件..."
if [ ! -f "src/components/PosterView.tsx" ]; then
    echo "❌ PosterView.tsx 修复文件不存在"
    exit 1
fi

echo "✅ PosterView.tsx 修复文件存在"
echo ""

# 备份原文件
echo "💾 备份容器中的原文件..."
docker exec $CONTAINER_ID cp /app/src/components/PosterView.tsx /app/src/components/PosterView.tsx.backup 2>/dev/null || true

# 复制修复文件到容器
echo "📝 应用修复文件..."
docker cp ./src/components/PosterView.tsx $CONTAINER_ID:/app/src/components/PosterView.tsx

echo "✅ 修复文件已复制到容器"
echo ""

# 检查Next.js是否支持热重载
echo "🔥 触发热重载..."
docker exec $CONTAINER_ID touch /app/src/components/PosterView.tsx

echo "⏳ 等待热重载生效..."
sleep 5

# 测试修复效果
echo ""
echo "🧪 测试修复效果..."

# 等待服务响应
for i in {1..5}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ 服务正常响应"
        break
    else
        echo "   等待服务响应... ($i/5)"
        sleep 2
    fi
done

# 快速测试
echo "📊 快速测试内容尺寸修复..."

echo "🖥️  测试桌面版:"
DESKTOP_TEST=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🔥 热修复测试\n\n这是热修复后的测试。\n\n**如果显示正常，说明热修复成功！**",
    "header": "热修复测试",
    "width": 1200,
    "height": 600, 
    "password": "123456"
  }' 2>/dev/null | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   结果: $DESKTOP_TEST"

echo "📱 测试手机版:"
MOBILE_TEST=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📱 手机版热修复\n\n字体应该更小。",
    "header": "手机版热修复",
    "width": 400,
    "height": 600,
    "password": "123456"
  }' 2>/dev/null | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   结果: $MOBILE_TEST"

echo ""
echo "🎉 热修复完成！"
echo "================"
echo ""
echo "📋 应用的修复："
echo "   ✅ PosterView.tsx: 内容尺寸动态修复"
echo "   ✅ 热重载: 无需重启容器"
echo "   ✅ 保持数据: 不影响现有数据"
echo ""
echo "🔄 如果修复未生效，可以："
echo "   1. 重启容器: docker restart $CONTAINER_ID"
echo "   2. 查看日志: docker logs $CONTAINER_ID"
echo "   3. 恢复备份: docker exec $CONTAINER_ID cp /app/src/components/PosterView.tsx.backup /app/src/components/PosterView.tsx"
echo ""
echo "📊 测试结果:"
echo "   桌面版: $DESKTOP_TEST"
echo "   手机版: $MOBILE_TEST"
