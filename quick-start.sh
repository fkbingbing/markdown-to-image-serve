#!/bin/bash
# 快速启动修复后的服务
set -e

echo "🚀 快速启动 markdown-to-image-serve"
echo "================================="
echo ""

# 检查必要文件
echo "📋 检查必要文件..."
REQUIRED_FILES=("fix-deps.sh" "package.json" "docker-compose.yml")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 缺少文件: $file"
        exit 1
    else
        echo "✅ $file"
    fi
done

# 检查Docker镜像
echo ""
echo "🐳 检查Docker镜像..."
if docker images | grep -q "markdown-to-image-serve"; then
    echo "✅ 找到本地镜像:"
    docker images | grep "markdown-to-image-serve" | head -1
else
    echo "❌ 未找到镜像: markdown-to-image-serve:latest"
    echo "请先构建镜像: ./force-rebuild.sh"
    exit 1
fi

# 停止现有服务
echo ""
echo "🛑 停止现有服务（如果有）..."
docker-compose down 2>/dev/null || true
docker stop markdown-to-image-serve 2>/dev/null || true
docker rm markdown-to-image-serve 2>/dev/null || true

# 创建必要目录
echo ""
echo "📁 创建必要目录..."
mkdir -p public/uploads/posters
mkdir -p uploads

# 启动服务
echo ""
echo "🚀 启动服务（含动态依赖修复）..."
echo "⏳ 预计启动时间: 20-40秒（首次）"
echo ""

docker-compose up -d

# 等待启动
echo "⌛ 等待服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo ""
        echo "✅ 服务启动成功！"
        break
    fi
    
    if [ $i -eq 60 ]; then
        echo ""
        echo "⚠️  服务启动超时，请检查日志"
        echo "📋 查看日志: docker-compose logs app"
        exit 1
    fi
    
    echo -n "."
    sleep 1
done

echo ""
echo "🎉 启动完成！"
echo ""
echo "📋 服务信息:"
echo "  🌐 访问地址: http://localhost:3000"
echo "  🔑 API密码: 123456"
echo "  📁 图片目录: ./public/uploads/posters/"
echo ""
echo "📚 API测试:"
echo '  curl -X POST http://localhost:3000/api/generatePosterImage \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"markdown":"# 测试标题\n\n这是测试内容","header":"测试海报","password":"123456"}'"'"
echo ""
echo "🔧 管理命令:"
echo "  查看日志: docker-compose logs -f app"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart app"
echo ""
echo "🎯 故障排除:"
echo "  - 如果启动失败，查看日志: docker-compose logs app"
echo "  - 如果端口冲突，停止占用进程或修改 docker-compose.yml"
echo "  - 详细文档: DYNAMIC_FIX.md"
