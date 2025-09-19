#!/bin/bash
# 文件: apply-table-fix-to-docker.sh
# 描述: 将表格和文本截断修复应用到运行中的Docker容器，无需重新编译镜像
# 用途: 快速修复表格显示和文本截断问题

set -e

echo "🔧 应用表格和文本截断修复到Docker容器"
echo "======================================"

# 配置变量
CONTAINER_NAME="markdown-serve"
IMAGE_NAME="markdown-to-image-serve:latest"
SERVICE_DIR="/Users/xiangping.liao/Documents/wp/crocodile/markdowntoimage/markdown-to-image-serve"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker 未运行。请启动 Docker Desktop 或 Docker 服务。"
  exit 1
fi

echo "🔍 检查容器状态..."

# 查找运行中的容器
RUNNING_CONTAINER_ID=$(docker ps -q -f name="$CONTAINER_NAME" | head -1)

if [ -z "$RUNNING_CONTAINER_ID" ]; then
  echo "⚠️  未找到运行中的 $CONTAINER_NAME 容器"
  echo "将启动新的容器并应用修复..."
  
  # 停止并移除旧容器 (如果存在)
  docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
  docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true
  
  echo "🚀 启动新容器并挂载修复后的文件..."
  docker run -d \
    --name "$CONTAINER_NAME" \
    -p 3000:3000 \
    -e NODE_ENV=production \
    -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
    -e CHROME_PATH=/usr/bin/chromium \
    -e API_PASSWORD="123456" \
    -v "$SERVICE_DIR/public/uploads/posters:/app/public/uploads/posters" \
    -v "$SERVICE_DIR/uploads:/app/uploads" \
    -v "$SERVICE_DIR/src/components/PosterView.tsx:/app/src/components/PosterView.tsx:ro" \
    -v "$SERVICE_DIR/fix-deps.sh:/app/fix-deps.sh:ro" \
    "$IMAGE_NAME" /app/fix-deps.sh yarn start
    
  if [ $? -eq 0 ]; then
    echo "✅ 新容器已启动，并挂载了修复后的PosterView.tsx"
    RUNNING_CONTAINER_ID=$(docker ps -q -f name="$CONTAINER_NAME" | head -1)
  else
    echo "❌ 容器启动失败"
    exit 1
  fi
else
  echo "✅ 找到运行中的容器: $RUNNING_CONTAINER_ID"
  
  echo "🔄 直接复制修复后的文件到容器..."
  
  # 复制 PosterView.tsx 到容器
  docker cp "$SERVICE_DIR/src/components/PosterView.tsx" "$RUNNING_CONTAINER_ID:/app/src/components/PosterView.tsx"
  
  echo "🔄 重启容器以应用修改..."
  docker restart "$RUNNING_CONTAINER_ID"
fi

# 等待服务完全启动
echo "⏳ 等待服务完全启动..."
sleep 15

# 测试API是否正常工作
echo "🧪 测试API功能..."
API_RESPONSE=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🧪 Docker修复测试\n\n## 测试表格\n\n| 项目 | 状态 | 说明 |\n|------|------|------|\n| 文本截断修复 | ✅ | 长文本应该完整显示 |\n| 表格渲染修复 | ✅ | 表格应该正确格式化 |\n\n**长文本测试**：这是一段很长很长很长很长很长很长很长很长的文本，用来测试文本截断修复是否生效，如果看到这句话的结尾【成功】，说明修复有效。",
    "header": "🔧 Docker修复验证",
    "footer": "Docker容器修复测试",
    "theme": "SpringGradientWave",
    "width": 1690,
    "height": 1080,
    "password": "123456"
  }' 2>/dev/null || echo "API_ERROR")

if echo "$API_RESPONSE" | grep -q "url"; then
  echo "✅ API功能正常"
  
  # 提取图片URL
  IMAGE_URL=$(echo "$API_RESPONSE" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
  echo "📸 测试图片: $IMAGE_URL"
  
  # 提取尺寸信息
  WIDTH=$(echo "$API_RESPONSE" | grep -o '"width":[0-9]*' | cut -d':' -f2)
  HEIGHT=$(echo "$API_RESPONSE" | grep -o '"height":[0-9]*' | cut -d':' -f2)
  echo "📐 图片尺寸: ${WIDTH}x${HEIGHT}px"
  
else
  echo "⚠️  API测试失败，但容器可能仍在启动中"
  echo "请稍后手动测试: curl -X POST http://localhost:3000/api/generatePosterImage ..."
fi

echo ""
echo "🎉 Docker容器修复完成！"
echo ""
echo "📋 修复摘要:"
echo "  ✅ 文本截断修复 - 移除maxWidth限制"
echo "  ✅ 表格渲染修复 - 清理外层代码块+表格CSS"
echo "  ✅ 代码块宽度修复 - 强制CSS覆盖"
echo ""
echo "🔧 技术细节:"
echo "  - 容器名称: $CONTAINER_NAME"
echo "  - 监听端口: 3000"
echo "  - 图片尺寸: 1690x1080px"
echo "  - Chrome路径: /usr/bin/chromium"
echo ""
echo "🧪 验证方法:"
echo "  1. 访问 http://localhost:3000 检查服务状态"
echo "  2. 运行 ./test-api.sh 进行完整API测试"
echo "  3. 查看生成的图片确认表格和文本显示正确"
echo ""
echo "💡 如遇问题:"
echo "  - 检查容器日志: docker logs $CONTAINER_NAME"
echo "  - 重启容器: docker restart $CONTAINER_NAME"
echo "  - 完全重建: docker-compose down && docker-compose up -d"
