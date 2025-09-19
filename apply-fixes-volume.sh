#!/bin/bash
# 🔗 通过Volume挂载方式应用修复
# ===============================

set -e

echo "📂 通过Volume挂载应用修复"
echo "========================"
echo ""

# 检查是否有运行中的容器
RUNNING_CONTAINER=$(docker ps -q --filter "ancestor=markdown-to-image-serve:latest" | head -1)

if [ -n "$RUNNING_CONTAINER" ]; then
    echo "⚠️  检测到运行中的容器: $RUNNING_CONTAINER"
    echo "正在停止现有容器..."
    docker stop $RUNNING_CONTAINER
    docker rm $RUNNING_CONTAINER
fi

echo "🚀 使用Volume挂载启动新容器..."
echo ""

# 创建修复后的容器，挂载修改的文件
docker run -d \
    --name markdown-serve-fixed \
    -p 3000:3000 \
    -e NODE_ENV=production \
    -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
    -e CHROME_PATH=/usr/bin/chromium \
    -e API_PASSWORD=123456 \
    --restart unless-stopped \
    -v "$(pwd)/src/components/PosterView.tsx:/app/src/components/PosterView.tsx:ro" \
    -v "$(pwd)/fix-deps.sh:/app/fix-deps.sh:ro" \
    -v "$(pwd)/public/uploads/posters:/app/public/uploads/posters" \
    -v "$(pwd)/uploads:/app/uploads" \
    markdown-to-image-serve:latest \
    /app/fix-deps.sh yarn start

echo "✅ 容器启动完成"
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
for i in {1..10}; do
    if curl -s http://127.0.0.1:3000 >/dev/null 2>&1; then
        echo "✅ 服务启动成功！"
        break
    else
        echo "   等待中... ($i/10)"
        sleep 3
    fi
done

echo ""
echo "🎉 修复应用完成！"
echo ""
echo "📋 应用的修复："
echo "   ✅ Chrome路径已更新为 /usr/bin/chromium"
echo "   ✅ PosterView.tsx 已挂载修改版本"
echo "   ✅ 动态内容尺寸已启用"
echo ""
echo "🧪 测试命令："
echo "   curl http://127.0.0.1:3000"
echo "   ./test-api.sh"
echo ""
echo "📝 容器管理："
echo "   查看日志: docker logs markdown-serve-fixed"
echo "   停止容器: docker stop markdown-serve-fixed"
echo "   删除容器: docker rm markdown-serve-fixed"
