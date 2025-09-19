#!/bin/bash
# Docker 构建脚本 - 修复版本
# 解决 npm ci 失败和构建卡死问题

set -e

echo "🐳 Docker 构建脚本 - 修复版本"
echo "================================"
echo ""

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未找到，请先安装Docker"
    exit 1
fi

# 版本和标签
VERSION=${1:-"fixed-$(date +%Y%m%d)"}
IMAGE_NAME="markdown-to-image-serve"
FULL_TAG="${IMAGE_NAME}:${VERSION}"

echo "🏷️  镜像标签: ${FULL_TAG}"
echo ""

# 选择构建方式
echo "请选择构建方式:"
echo "1. 简单构建 (推荐, 最稳定)"
echo "2. 标准构建 (功能完整)" 
echo "3. 多阶段构建 (最小镜像)"
echo "4. 🔥 强制重建 (清除缓存, 解决Registry问题)"
echo ""
read -p "请输入选择 (1-4, 默认1): " choice
choice=${choice:-1}

case $choice in
    1)
        echo "🔨 使用简单构建方式 (推荐)..."
        DOCKERFILE="Dockerfile.simple"
        ;;
    2)
        echo "🔨 使用标准构建方式..."
        DOCKERFILE="Dockerfile"
        ;;
    3)
        echo "🔨 使用多阶段构建方式..."
        DOCKERFILE="Dockerfile.optimized"
        ;;
    4)
        echo "🔥 转到强制重建模式..."
        echo "   - 这将清除所有Docker缓存"
        echo "   - 强制重新下载依赖"
        echo "   - 解决Registry配置问题"
        echo ""
        exec ./force-rebuild.sh
        exit 0
        ;;
    *)
        echo "❌ 无效选择，使用默认选项 (简单构建)"
        DOCKERFILE="Dockerfile.simple"
        ;;
esac

echo ""
echo "📋 构建信息:"
echo "  - Dockerfile: ${DOCKERFILE}"
echo "  - 镜像名称: ${FULL_TAG}"
echo "  - 构建时间: $(date)"
echo ""

# 构建镜像
echo "🔨 开始构建Docker镜像..."
echo "⏱️  预计需要5-10分钟，请耐心等待..."
echo ""

# 使用--no-cache确保获取最新代码
docker build \
    --no-cache \
    --platform linux/amd64 \
    --progress=plain \
    -f "${DOCKERFILE}" \
    -t "${FULL_TAG}" \
    -t "${IMAGE_NAME}:latest" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功!"
    echo ""
    echo "📋 使用方法:"
    echo "  # 运行容器"
    echo "  docker run -d -p 3000:3000 \\"
    echo "    -e API_PASSWORD=your_password \\"
    echo "    ${FULL_TAG}"
    echo ""
    echo "  # 访问服务"
    echo "  curl http://localhost:3000"
    echo ""
    echo "🔧 容器管理:"
    echo "  docker images | grep ${IMAGE_NAME}     # 查看镜像"
    echo "  docker ps | grep ${IMAGE_NAME}         # 查看运行容器"
    echo "  docker logs <container_id>             # 查看日志"
    echo ""
    echo "📦 导出镜像:"
    echo "  docker save ${FULL_TAG} | gzip > ${IMAGE_NAME}-${VERSION}.tar.gz"
    echo ""
else
    echo ""
    echo "❌ 构建失败!"
    echo ""
    echo "🔍 故障排除建议:"
    echo "  1. 检查网络连接是否正常"
    echo "  2. 确保有足够的磁盘空间 (至少2GB)"
    echo "  3. 尝试清理Docker缓存: docker system prune -f"
    echo "  4. 尝试其他构建方式"
    echo ""
    exit 1
fi

# 清理完成 (Dockerfile.simple 是永久文件，不删除)

echo "🎉 脚本执行完成!"
