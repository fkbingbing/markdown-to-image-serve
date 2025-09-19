#!/bin/bash
# 检查 Docker 版本和兼容性
set -e

echo "🐳 Docker 版本兼容性检查"
echo "========================"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    echo "📋 安装指南: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker 已安装"

# 获取 Docker 版本信息
DOCKER_VERSION=$(docker --version)
echo "📋 版本信息: ${DOCKER_VERSION}"

# 提取版本号
VERSION_NUMBER=$(echo "${DOCKER_VERSION}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
MAJOR_VERSION=$(echo "${VERSION_NUMBER}" | cut -d. -f1)
MINOR_VERSION=$(echo "${VERSION_NUMBER}" | cut -d. -f2)

echo "📊 版本号: ${VERSION_NUMBER} (主版本: ${MAJOR_VERSION}, 次版本: ${MINOR_VERSION})"
echo ""

# 版本兼容性检查
echo "🔍 功能支持检查:"

# 检查 --progress 支持
if docker build --help | grep -q "\--progress"; then
    echo "  ✅ --progress 参数: 支持 (详细构建输出)"
    PROGRESS_SUPPORT=true
else
    echo "  ❌ --progress 参数: 不支持 (使用传统输出)"
    PROGRESS_SUPPORT=false
fi

# 检查 --platform 支持
if docker build --help | grep -q "\--platform"; then
    echo "  ✅ --platform 参数: 支持 (多平台构建)"
    PLATFORM_SUPPORT=true
else
    echo "  ❌ --platform 参数: 不支持 (单平台构建)"
    PLATFORM_SUPPORT=false
fi

# 检查 buildx 支持
if docker buildx version &> /dev/null; then
    echo "  ✅ Docker BuildKit: 可用 (现代构建器)"
    BUILDX_SUPPORT=true
else
    echo "  ❌ Docker BuildKit: 不可用 (传统构建器)"
    BUILDX_SUPPORT=false
fi

echo ""

# 版本分类和建议
echo "📋 兼容性评估:"

if [ "${MAJOR_VERSION}" -ge 20 ] || ([ "${MAJOR_VERSION}" -eq 19 ] && [ "${MINOR_VERSION}" -ge 3 ]); then
    echo "  🟢 **现代版本** - 完全支持所有功能"
    echo "     • 推荐构建方式: ./force-rebuild.sh"
    echo "     • 预期体验: 最佳，包含详细进度和多平台支持"
    COMPATIBILITY_LEVEL="excellent"
elif [ "${MAJOR_VERSION}" -ge 18 ] && [ "${MINOR_VERSION}" -ge 9 ]; then
    echo "  🟡 **兼容版本** - 支持基础现代功能"
    echo "     • 推荐构建方式: ./force-rebuild.sh"
    echo "     • 预期体验: 良好，包含详细进度显示"
    COMPATIBILITY_LEVEL="good"
elif [ "${MAJOR_VERSION}" -ge 17 ]; then
    echo "  🟠 **旧版本** - 仅支持基础功能"
    echo "     • 推荐构建方式: ./force-rebuild.sh"
    echo "     • 预期体验: 正常，使用传统输出"
    COMPATIBILITY_LEVEL="basic"
else
    echo "  🔴 **过旧版本** - 可能存在兼容性问题"
    echo "     • 建议升级 Docker: https://docs.docker.com/get-docker/"
    echo "     • 预期体验: 可能遇到问题"
    COMPATIBILITY_LEVEL="poor"
fi

echo ""

# 测试构建功能
echo "🧪 快速构建测试:"

# 创建简单测试 Dockerfile
cat > Dockerfile.test << 'EOF'
FROM alpine:latest
RUN echo "Docker 构建测试成功"
CMD ["echo", "Hello Docker"]
EOF

echo "  正在测试基础构建功能..."

if timeout 30 docker build -f Dockerfile.test -t docker-test:latest . >/dev/null 2>&1; then
    echo "  ✅ 基础构建: 成功"
    
    # 清理测试镜像
    docker rmi docker-test:latest >/dev/null 2>&1 || true
    
    BUILD_TEST_RESULT="success"
else
    echo "  ❌ 基础构建: 失败"
    BUILD_TEST_RESULT="failed"
fi

# 清理测试文件
rm -f Dockerfile.test

echo ""

# 最终建议
echo "🎯 构建建议:"

if [ "${BUILD_TEST_RESULT}" = "success" ] && [ "${COMPATIBILITY_LEVEL}" != "poor" ]; then
    echo "  🚀 **可以开始构建!**"
    echo ""
    echo "  推荐命令:"
    echo "    ./force-rebuild.sh"
    echo "    # 选择 '1' (简单构建)"
    echo ""
    echo "  预计构建时间:"
    if [ "${COMPATIBILITY_LEVEL}" = "excellent" ]; then
        echo "    • 首次构建: 10-15 分钟 (包含详细进度)"
        echo "    • 缓存构建: 3-5 分钟"
    else
        echo "    • 首次构建: 12-18 分钟 (传统输出)"
        echo "    • 缓存构建: 5-8 分钟"
    fi
else
    echo "  ⚠️  **建议先解决兼容性问题**"
    echo ""
    echo "  解决方案:"
    echo "    1. 升级 Docker: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    echo "    2. 重启 Docker 服务: sudo systemctl restart docker"
    echo "    3. 检查磁盘空间: df -h"
    echo "    4. 清理 Docker: docker system prune -a -f"
    echo ""
    echo "  如果问题持续:"
    echo "    • 查看 DOCKER_COMPATIBILITY_FIX.md"
    echo "    • 尝试手动构建: docker build -f Dockerfile.simple -t test ."
fi

echo ""
echo "📚 相关文档:"
echo "  • Docker 兼容性: DOCKER_COMPATIBILITY_FIX.md"
echo "  • 构建故障排除: DOCKER_TROUBLESHOOTING.md"
echo "  • patch-package 问题: PATCH_PACKAGE_FIX.md"
echo ""

# 输出检查摘要
echo "📊 检查摘要:"
echo "  Docker 版本: ${VERSION_NUMBER}"
echo "  兼容性级别: ${COMPATIBILITY_LEVEL}"
echo "  构建测试: ${BUILD_TEST_RESULT}"
echo "  --progress 支持: $([ "${PROGRESS_SUPPORT}" = true ] && echo "是" || echo "否")"
echo "  --platform 支持: $([ "${PLATFORM_SUPPORT}" = true ] && echo "是" || echo "否")"
echo "  BuildKit 支持: $([ "${BUILDX_SUPPORT}" = true ] && echo "是" || echo "否")"

echo ""
echo "✨ 检查完成！"
