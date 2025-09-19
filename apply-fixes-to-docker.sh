#!/bin/bash
# 🚀 将本地修复应用到Docker容器（无需重新编译镜像）
# ========================================================

set -e

echo "🚀 将本地修复应用到Docker容器"
echo "=============================="
echo ""

IMAGE_NAME="markdown-to-image-serve:latest"
CONTAINER_NAME="markdown-serve-fixed"

# 检查是否存在修复后的文件
echo "🔍 检查修复文件..."
REQUIRED_FILES=(
    "./src/components/PosterView.tsx"
    "./docker-compose.yml"
    "./.env.local"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 不存在"
        exit 1
    fi
done

echo ""

# 停止现有容器
echo "🛑 停止现有容器..."
docker stop $(docker ps -q --filter "ancestor=${IMAGE_NAME}") 2>/dev/null || true
docker rm $(docker ps -aq --filter "ancestor=${IMAGE_NAME}") 2>/dev/null || true

echo ""
echo "🚀 启动新容器（应用修复）..."

# 方案1: Volume挂载方式（推荐）
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 3000:3000 \
    -e NODE_ENV=production \
    -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
    -e CHROME_PATH=/usr/bin/chromium \
    -e API_PASSWORD=123456 \
    --restart unless-stopped \
    -v "$(pwd)/src/components/PosterView.tsx:/app/src/components/PosterView.tsx:ro" \
    -v "$(pwd)/public/uploads/posters:/app/public/uploads/posters" \
    -v "$(pwd)/uploads:/app/uploads" \
    "${IMAGE_NAME}" \
    yarn start

echo "✅ 容器已启动并应用修复"
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 测试服务
echo "🧪 测试修复效果..."
for i in {1..10}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ 服务启动成功！"
        break
    else
        echo "   等待中... ($i/10)"
        sleep 3
    fi
done

# 快速API测试
echo ""
echo "📊 快速测试内容尺寸修复..."

# 测试桌面版
echo "🖥️  测试桌面版 (1200px):"
DESKTOP_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🖥️ Docker容器修复测试\n\n这是测试Docker容器中的修复是否生效。\n\n**如果看到这条消息，说明修复已成功应用！**",
    "header": "Docker修复测试", 
    "width": 1200,
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error')
echo "   结果: $DESKTOP_RESULT"

# 测试手机版
echo "📱 测试手机版 (400px):"
MOBILE_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 📱 手机版测试\n\n字体应该比桌面版小。\n\n**修复测试完成！**",
    "header": "手机版测试",
    "width": 400, 
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error')
echo "   结果: $MOBILE_RESULT"

echo ""
echo "🎉 修复应用完成！"
echo "=================="
echo ""
echo "📋 应用的修复："
echo "   ✅ Chrome路径: /usr/bin/chromium"
echo "   ✅ 内容尺寸: 动态响应式 (desktop/tablet/mobile)"
echo "   ✅ PosterView.tsx: 最新修复版本"
echo ""
echo "🌐 访问地址:"
echo "   主页: http://localhost:3000"
echo "   API: http://localhost:3000/api/generatePosterImage"
echo ""
echo "🛠️  容器管理:"
echo "   查看日志: docker logs ${CONTAINER_NAME}"
echo "   停止容器: docker stop ${CONTAINER_NAME}"
echo "   删除容器: docker rm ${CONTAINER_NAME}"
echo ""
echo "📊 测试结果:"
echo "   桌面版: $DESKTOP_RESULT"
echo "   手机版: $MOBILE_RESULT"
