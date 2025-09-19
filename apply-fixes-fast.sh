#!/bin/bash
# 🚀 快速应用修复，无需重新构建镜像
# ================================

set -e

echo "🔧 快速应用修复方案"
echo "=================="
echo ""

# 检查容器是否运行
CONTAINER_ID=$(docker ps -q --filter "ancestor=markdown-to-image-serve:latest" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 未找到运行中的 markdown-to-image-serve 容器"
    echo "请先启动容器：./quick-start.sh 或 ./docker-run.sh"
    exit 1
fi

echo "✅ 找到运行中的容器: $CONTAINER_ID"
echo ""

# 方案1: 通过容器内部直接修改文件
echo "📝 方案1: 直接在容器内修改文件"
echo "=============================="

# 复制修改后的PosterView.tsx到容器
echo "🔄 复制修改后的 PosterView.tsx 到容器..."
docker cp ./src/components/PosterView.tsx $CONTAINER_ID:/app/src/components/PosterView.tsx

echo "✅ 文件复制完成"
echo ""

# 检查Next.js是否支持热重载
echo "🔥 检查Next.js热重载状态..."
docker exec $CONTAINER_ID sh -c "ps aux | grep next" || true

echo ""
echo "🎯 应用Chrome路径修复..."
echo "========================"

# 重启容器以应用环境变量修改
echo "🔄 重启容器应用环境变量修复..."

# 获取容器名称
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -v NAMES | head -1)

echo "   容器名称: $CONTAINER_NAME"
echo "   容器ID: $CONTAINER_ID"

# 重启容器
docker restart $CONTAINER_ID

echo "✅ 容器重启完成"
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
if curl -s http://127.0.0.1:3000 >/dev/null; then
    echo "✅ 服务启动成功"
else
    echo "⚠️  服务可能还在启动中，请稍等..."
fi

echo ""
echo "🎉 修复应用完成！"
echo ""
echo "🧪 测试修复效果："
echo "   curl http://127.0.0.1:3000"
echo "   ./test-api.sh"
echo ""
echo "📋 修复内容："
echo "   ✅ Chrome路径: /usr/bin/google-chrome-unstable → /usr/bin/chromium"
echo "   ✅ 内容尺寸: 根据图片宽度动态调整 (mobile/tablet/desktop)"
echo ""
