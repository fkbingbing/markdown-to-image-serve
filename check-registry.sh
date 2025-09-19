#!/bin/bash
# 快速检查当前的Registry配置问题
set -e

echo "🔍 检查 Registry 配置问题"
echo "============================"
echo ""

echo "📋 检查本地环境..."
echo "本地 npm registry: $(npm config get registry 2>/dev/null || echo '未设置')"
echo "本地 yarn registry: $(yarn config get registry 2>/dev/null || echo '未设置')"
echo ""

echo "🐳 检查 Docker 基础镜像配置..."
echo "基础镜像: wxingheng/node-chrome-base:latest"

# 检查基础镜像中的配置
docker run --rm wxingheng/node-chrome-base:latest /bin/bash -c "
echo '=== 基础镜像中的配置文件 ==='
echo '检查 /root/.npmrc:'
if [ -f /root/.npmrc ]; then
    echo '  ✅ 存在'
    cat /root/.npmrc | head -5
else
    echo '  ❌ 不存在'
fi

echo ''
echo '检查 /usr/local/share/.yarnrc:'
if [ -f /usr/local/share/.yarnrc ]; then
    echo '  ✅ 存在'
    cat /usr/local/share/.yarnrc | head -5
else
    echo '  ❌ 不存在'
fi

echo ''
echo '=== 基础镜像中的 Registry 配置 ==='
echo 'npm registry:'
npm config get registry 2>/dev/null || echo '  未配置'

echo 'yarn registry:'
yarn config get registry 2>/dev/null || echo '  未配置'
"

echo ""
echo "🔧 问题诊断..."

# 检查是否存在Docker构建缓存
CACHE_COUNT=$(docker images -f "dangling=true" -q | wc -l)
if [ "$CACHE_COUNT" -gt 0 ]; then
    echo "⚠️  发现 ${CACHE_COUNT} 个 Docker 构建缓存层"
    echo "   建议清理: docker image prune -f"
fi

# 检查相关镜像
if docker images markdown-to-image-serve --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -q markdown-to-image-serve; then
    echo "📦 发现已存在的镜像:"
    docker images markdown-to-image-serve --format "  {{.Repository}}:{{.Tag}} ({{.Size}}, {{.CreatedAt}})"
    echo "   可能使用了缓存构建"
fi

echo ""
echo "🎯 推荐解决方案:"
echo ""
echo "1️⃣  **立即生效方案** (推荐):"
echo "   ./force-rebuild.sh"
echo "   - 清除所有Docker缓存"
echo "   - 强制重新构建"
echo "   - 使用最新的registry修复"
echo ""

echo "2️⃣  **调试验证方案**:"
echo "   ./debug-registry.sh"
echo "   - 详细分析基础镜像配置"
echo "   - 验证修复效果"
echo ""

echo "3️⃣  **手动构建方案**:"
echo "   docker build -f Dockerfile.simple -t markdown-to-image-serve:latest . --no-cache"
echo "   - 跳过缓存重新构建"
echo ""

echo "🔍 识别问题类型:"
if docker run --rm wxingheng/node-chrome-base:latest cat /root/.npmrc 2>/dev/null | grep -q "registry.npmmirror.com"; then
    echo "✅ **确认问题**: 基础镜像包含 npmmirror 配置"
    echo "   - /root/.npmrc 包含 registry.npmmirror.com"
    echo "   - 需要在 Dockerfile 中强制清除"
    echo "   - 使用 ./force-rebuild.sh 重新构建"
else
    echo "❓ **配置检查**: 基础镜像配置正常"
    echo "   - 可能是Docker缓存问题"
    echo "   - 建议清除缓存重新构建"
fi

echo ""
echo "⚡ **快速修复** (最可能解决问题):"
echo "   ./force-rebuild.sh"
echo "   选择 '1' (简单构建)"
echo ""
echo "✅ 修复成功的标志:"
echo "   构建日志中显示: 'Performing GET request to https://registry.npmjs.org/'"
echo "   不再显示: 'registry.npmmirror.com'"
