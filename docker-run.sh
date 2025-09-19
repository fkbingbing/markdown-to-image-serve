#!/bin/bash
# 使用本地构建的 Docker 镜像启动服务
set -e

echo "🐳 启动 markdown-to-image-serve 服务"
echo "===================================="
echo ""

# 检查本地镜像是否存在
IMAGE_NAME="markdown-to-image-serve:latest"
if docker images | grep -q "markdown-to-image-serve"; then
    echo "✅ 找到本地镜像:"
    docker images | grep "markdown-to-image-serve" | head -1
    echo ""
else
    echo "❌ 未找到本地镜像: $IMAGE_NAME"
    echo "请先构建镜像: ./force-rebuild.sh"
    exit 1
fi

# 检查端口是否被占用
if lsof -i:3000 &>/dev/null; then
    echo "⚠️  端口 3000 已被占用"
    echo "正在查找占用进程..."
    lsof -i:3000
    echo ""
    read -p "是否要停止现有服务并继续? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ 用户取消操作"
        exit 1
    fi
fi

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p public/uploads/posters
mkdir -p uploads
echo ""

# 启动方式选择
echo "选择启动方式:"
echo "1. 前台运行 (可以看到日志)"
echo "2. 后台运行 (daemon模式)"
echo "3. 使用 docker-compose"
echo ""
read -p "请选择 (1-3, 默认1): " mode
mode=${mode:-1}

case $mode in
    1)
        echo "🚀 前台启动服务（含依赖修复）..."
        echo "💡 按 Ctrl+C 停止服务"
        echo ""
        docker run --rm -it \
            --name markdown-to-image-serve \
            -p 3000:3000 \
            -e NODE_ENV=production \
            -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
            -e CHROME_PATH=/usr/bin/google-chrome-unstable \
            -e API_PASSWORD=123456 \
            -v "$(pwd)/public/uploads/posters:/app/public/uploads/posters" \
            -v "$(pwd)/uploads:/app/uploads" \
            -v "$(pwd)/fix-deps.sh:/app/fix-deps.sh:ro" \
            $IMAGE_NAME \
            /app/fix-deps.sh yarn start
        ;;
    2)
        echo "🚀 后台启动服务（含依赖修复）..."
        CONTAINER_ID=$(docker run -d \
            --name markdown-to-image-serve \
            -p 3000:3000 \
            --restart unless-stopped \
            -e NODE_ENV=production \
            -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
            -e CHROME_PATH=/usr/bin/google-chrome-unstable \
            -e API_PASSWORD=123456 \
            -v "$(pwd)/public/uploads/posters:/app/public/uploads/posters" \
            -v "$(pwd)/uploads:/app/uploads" \
            -v "$(pwd)/fix-deps.sh:/app/fix-deps.sh:ro" \
            $IMAGE_NAME \
            /app/fix-deps.sh yarn start)
        
        echo "✅ 服务已启动"
        echo "🆔 容器ID: $CONTAINER_ID"
        echo ""
        echo "📋 管理命令:"
        echo "  查看日志: docker logs -f $CONTAINER_ID"
        echo "  停止服务: docker stop $CONTAINER_ID"
        echo "  删除容器: docker rm $CONTAINER_ID"
        echo ""
        
        # 等待服务启动并测试
        echo "⏳ 等待服务启动..."
        sleep 10
        
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ 服务启动成功!"
            echo "🌐 访问地址: http://localhost:3000"
        else
            echo "⚠️  服务可能还在启动中，请稍后访问"
            echo "📋 查看启动日志: docker logs $CONTAINER_ID"
        fi
        ;;
    3)
        echo "🚀 使用 docker-compose 启动..."
        if [ ! -f "docker-compose.yml" ]; then
            echo "❌ 未找到 docker-compose.yml 文件"
            exit 1
        fi
        
        echo "停止现有服务..."
        docker-compose down 2>/dev/null || true
        
        echo "启动服务..."
        docker-compose up -d
        
        echo "✅ 服务已启动"
        echo ""
        echo "📋 管理命令:"
        echo "  查看日志: docker-compose logs -f"
        echo "  停止服务: docker-compose down"
        echo "  重启服务: docker-compose restart"
        echo ""
        
        # 等待服务启动
        echo "⏳ 等待服务启动..."
        sleep 10
        
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ 服务启动成功!"
            echo "🌐 访问地址: http://localhost:3000"
        else
            echo "⚠️  服务可能还在启动中"
            echo "📋 查看日志: docker-compose logs"
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🎉 启动脚本执行完成!"
echo ""
echo "📚 API文档:"
echo "  POST /api/generatePosterImage - 生成海报图片"
echo "  参数: {markdown, header, footer, theme, width, height, password}"
echo ""
echo "🔧 故障排除:"
echo "  查看容器状态: docker ps"
echo "  查看镜像信息: docker images | grep markdown-to-image-serve"
echo "  测试API: curl http://localhost:3000/api/hello.js"
