#!/bin/bash
# 测试Docker镜像检查逻辑

echo "🧪 测试Docker镜像检查逻辑"
echo "========================="
echo ""

echo "📋 当前Docker镜像列表:"
if command -v docker >/dev/null 2>&1; then
    docker images | head -5
    echo ""
    
    echo "🔍 检查markdown-to-image-serve镜像:"
    if docker images | grep -q "markdown-to-image-serve"; then
        echo "✅ 找到镜像!"
        echo "详细信息:"
        docker images | grep "markdown-to-image-serve"
    else
        echo "❌ 未找到镜像"
    fi
else
    echo "❌ Docker 未安装或不可用"
fi

echo ""
echo "🎯 测试完成"
