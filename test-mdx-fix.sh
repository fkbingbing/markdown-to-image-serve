#!/bin/bash
# 快速测试MDX依赖修复
set -e

echo "🧪 快速测试MDX依赖修复"
echo "======================"
echo ""

# 检查Docker镜像
if ! docker images | grep -q "markdown-to-image-serve"; then
    echo "❌ 未找到Docker镜像: markdown-to-image-serve"
    exit 1
fi

echo "✅ Docker镜像存在"
echo ""

# 创建必要目录
mkdir -p public/uploads/posters uploads

echo "🚀 启动容器测试MDX修复..."
echo "⏳ 这将显示详细的修复过程..."
echo ""

# 运行容器并显示修复过程
docker run --rm -it \
    -p 3000:3000 \
    -v "$(pwd)/fix-deps.sh:/app/fix-deps.sh:ro" \
    -e NODE_ENV=production \
    -e API_PASSWORD=123456 \
    markdown-to-image-serve:latest \
    /app/fix-deps.sh yarn start
