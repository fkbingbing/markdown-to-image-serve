#!/bin/bash
# 🔄 重新构建本机Docker镜像，应用所有修复
# =============================================

set -e

IMAGE_NAME="markdown-to-image-serve:latest"
BUILD_TIME=$(date +"%Y%m%d_%H%M%S")

echo "🔄 重新构建本机Docker镜像..."
echo "📋 镜像名称: ${IMAGE_NAME}"
echo "🕐 构建时间: ${BUILD_TIME}"
echo ""

# 检查当前目录
if [ ! -f "Dockerfile" ]; then
    echo "❌ 未找到Dockerfile，请在markdown-to-image-serve目录中运行此脚本"
    exit 1
fi

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装或不可用"
    exit 1
fi

echo "🏗️  开始构建Docker镜像..."
echo "   使用简化版Dockerfile进行构建"
echo ""

# 使用简化版Dockerfile构建
if [ -f "Dockerfile.simple" ]; then
    echo "📄 使用 Dockerfile.simple 构建..."
    docker build -f Dockerfile.simple -t ${IMAGE_NAME} . --no-cache
elif [ -f "Dockerfile" ]; then
    echo "📄 使用 Dockerfile 构建..."
    docker build -f Dockerfile -t ${IMAGE_NAME} . --no-cache
else
    echo "❌ 没有找到可用的Dockerfile"
    exit 1
fi

echo ""
echo "✅ Docker镜像构建完成！"
echo ""

# 显示镜像信息
echo "📊 镜像信息:"
docker images | head -1  # 表头
docker images | grep markdown-to-image-serve | head -3

echo ""
echo "🎉 修复已应用到本机镜像！"
echo ""
echo "🚀 重启服务命令:"
echo "   cd /path/to/markdown-to-image-serve"
echo "   ./quick-start.sh"
echo ""
echo "🧪 测试API命令:"
echo "   ./test-api.sh"
echo ""

# 可选：自动重启服务
read -p "🤔 是否立即重启服务？[y/N]: " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 重启服务中..."
    
    # 停止现有容器
    docker stop $(docker ps -q --filter "ancestor=${IMAGE_NAME}") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "ancestor=${IMAGE_NAME}") 2>/dev/null || true
    
    # 启动新容器
    if [ -f "quick-start.sh" ]; then
        ./quick-start.sh
    elif [ -f "docker-run.sh" ]; then
        ./docker-run.sh
    else
        echo "⚠️  请手动启动服务"
    fi
    
    echo "✅ 服务重启完成"
else
    echo "ℹ️  请手动重启服务以应用修复"
fi
