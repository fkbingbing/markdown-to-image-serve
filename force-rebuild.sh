#!/bin/bash
# 强制重新构建 - 清除所有缓存
set -e

echo "🔥 强制重新构建 Docker 镜像（清除所有缓存）"
echo "=============================================="
echo ""

# 设置镜像信息
IMAGE_NAME="markdown-to-image-serve"
VERSION="latest"
FULL_TAG="${IMAGE_NAME}:${VERSION}"

echo "🏷️  镜像标签: ${FULL_TAG}"
echo ""

# 选择构建方式
echo "请选择构建方式:"
echo "1. 简单构建 (推荐, 最稳定)"
echo "2. 标准构建"
echo ""
read -p "请输入选择 (1-2, 默认1): " choice
choice=${choice:-1}

case $choice in
    1)
        echo "🔨 使用简单构建方式 (强制重建)..."
        DOCKERFILE="Dockerfile.simple"
        ;;
    2)
        echo "🔨 使用标准构建方式 (强制重建)..."
        DOCKERFILE="Dockerfile"
        ;;
    *)
        echo "❌ 无效选择，使用默认选项 (简单构建)"
        DOCKERFILE="Dockerfile.simple"
        ;;
esac

echo ""
echo "⚠️  这将会:"
echo "  - 清除所有Docker构建缓存"
echo "  - 删除相关的Docker镜像"
echo "  - 强制重新下载所有依赖"
echo "  - 构建时间会比较长 (8-15分钟)"
echo ""

read -p "确定要继续吗? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ 用户取消操作"
    exit 1
fi

echo ""
echo "🧹 第1步: 清除Docker缓存和相关镜像..."

# 删除相关镜像
echo "删除相关镜像..."
docker rmi ${FULL_TAG} 2>/dev/null || echo "  - 镜像 ${FULL_TAG} 不存在，跳过"
docker rmi ${IMAGE_NAME}:dev 2>/dev/null || echo "  - 镜像 ${IMAGE_NAME}:dev 不存在，跳过"

# 清理构建缓存
echo "清理构建缓存..."
docker builder prune -f >/dev/null 2>&1 || true

# 清理系统缓存
echo "清理系统缓存..."
docker system prune -f >/dev/null 2>&1 || true

echo "✅ 缓存清理完成"
echo ""

echo "🔨 第2步: 强制重新构建镜像..."
echo "📋 构建信息:"
echo "  - Dockerfile: ${DOCKERFILE}"
echo "  - 镜像名称: ${FULL_TAG}"
echo "  - 缓存策略: 完全禁用 (--no-cache)"
echo "  - 进度显示: 详细模式 (--progress=plain)"
echo ""

# 开始构建
echo "⏰ 构建开始时间: $(date)"
START_TIME=$(date +%s)

if docker build \
    -f ${DOCKERFILE} \
    -t ${FULL_TAG} \
    --no-cache \
    --progress=plain \
    --build-arg BUILDKIT_INLINE_CACHE=0 \
    . ; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo ""
    echo "🎉 构建成功！"
    echo "⏰ 构建结束时间: $(date)"
    echo "⏱️  总耗时: ${MINUTES}分${SECONDS}秒"
    echo ""
    
    # 验证镜像
    echo "🔍 验证构建的镜像..."
    IMAGE_SIZE=$(docker images ${FULL_TAG} --format "{{.Size}}")
    echo "  📦 镜像大小: ${IMAGE_SIZE}"
    
    # 测试运行
    echo ""
    echo "🧪 测试镜像启动..."
    if timeout 30 docker run --rm -d --name test-container -p 3001:3000 ${FULL_TAG} >/dev/null 2>&1; then
        sleep 5
        if curl -s http://localhost:3001 >/dev/null 2>&1; then
            echo "✅ 镜像可以正常启动和响应"
            docker stop test-container >/dev/null 2>&1 || true
        else
            echo "⚠️  镜像启动了但无法访问，可能需要检查配置"
            docker stop test-container >/dev/null 2>&1 || true
        fi
    else
        echo "⚠️  镜像启动测试跳过（可能端口被占用）"
    fi
    
    echo ""
    echo "🚀 下一步操作:"
    echo "  1. 启动服务: docker run -d -p 3000:3000 ${FULL_TAG}"
    echo "  2. 查看日志: docker logs <container-id>"
    echo "  3. 访问服务: http://localhost:3000"
    echo ""
    echo "📋 Registry修复验证:"
    echo "  - 如果构建过程中看到 'registry.npmjs.org'，说明修复成功"
    echo "  - 如果仍看到 'registry.npmmirror.com'，请查看构建日志排查"
    
else
    echo ""
    echo "❌ 构建失败！"
    echo ""
    echo "🔍 故障排除建议:"
    echo "  1. 检查网络连接到 registry.npmjs.org"
    echo "  2. 确保Docker有足够磁盘空间 (推荐10GB+)"
    echo "  3. 查看完整构建日志分析具体错误"
    echo "  4. 尝试重启Docker服务"
    echo "  5. 参考故障排除指南: DOCKER_TROUBLESHOOTING.md"
    echo ""
    exit 1
fi

echo "🎯 强制重建完成！"
