#!/bin/bash
# 🔧 热修复Puppeteer网络连接问题
# 解决Docker容器内localhost:3000连接被拒绝的问题

set -e

echo "🔧 热修复Puppeteer网络连接问题"
echo "================================="
echo ""

# 检查Docker容器是否运行
if ! docker ps | grep -q "markdown-to-image-serve"; then
    echo "❌ 未找到运行中的markdown-to-image-serve容器"
    echo "请先启动容器: docker-compose up -d"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep "markdown-to-image-serve" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 无法确定容器名称"
    exit 1
fi

echo "📦 找到容器: $CONTAINER_NAME"
echo ""

# 备份原文件
echo "💾 备份原文件..."
docker exec "$CONTAINER_NAME" cp /app/src/pages/api/generatePosterImage.ts /app/src/pages/api/generatePosterImage.ts.backup.$(date +%Y%m%d_%H%M%S)
docker exec "$CONTAINER_NAME" cp /app/src/pages/api/generatePoster.ts /app/src/pages/api/generatePoster.ts.backup.$(date +%Y%m%d_%H%M%S)

echo "✅ 备份完成"
echo ""

# 应用修复
echo "🔨 应用网络连接修复..."

# 修复generatePosterImage.ts
docker exec "$CONTAINER_NAME" sed -i 's|const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";|const baseUrl = process.env.INTERNAL_BASE_URL || process.env.NEXT_PUBLIC_BASE_URL || "http://127.0.0.1:3000";|' /app/src/pages/api/generatePosterImage.ts

# 修复generatePoster.ts
docker exec "$CONTAINER_NAME" sed -i 's|const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";|const baseUrl = process.env.INTERNAL_BASE_URL || process.env.NEXT_PUBLIC_BASE_URL || "http://127.0.0.1:3000";|' /app/src/pages/api/generatePoster.ts

echo "✅ 代码修复完成"
echo ""

# 设置环境变量
echo "🌍 设置内部网络环境变量..."
docker exec "$CONTAINER_NAME" sh -c 'export INTERNAL_BASE_URL=http://127.0.0.1:3000'

echo "✅ 环境变量设置完成"
echo ""

# 重启容器以应用更改
echo "🔄 重启容器以应用更改..."
docker restart "$CONTAINER_NAME"

echo "⏳ 等待容器重启..."
sleep 10

# 检查容器状态
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✅ 容器重启成功"
else
    echo "❌ 容器重启失败"
    exit 1
fi

echo ""
echo "🧪 测试修复效果..."

# 等待服务启动
echo "⏳ 等待服务启动..."
for i in {1..30}; do
    if curl -s http://localhost:3000/api/hello >/dev/null 2>&1; then
        echo "✅ 服务启动成功"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ 服务启动超时"
        exit 1
    fi
    
    echo -n "."
    sleep 2
done

echo ""
echo "🎉 Puppeteer网络连接修复完成！"
echo ""
echo "📋 修复内容:"
echo "  ✅ 修改baseUrl使用127.0.0.1:3000"
echo "  ✅ 添加INTERNAL_BASE_URL环境变量"
echo "  ✅ 重启容器应用更改"
echo ""
echo "🧪 测试API:"
echo 'curl -X POST http://localhost:3000/api/generatePosterImage \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"markdown":"# 测试\n\n修复后的连接","password":"123456"}'"'"
echo ""
echo "💡 如果仍有问题，请检查容器日志:"
echo "   docker logs $CONTAINER_NAME"
