#!/bin/bash
# 快速测试Docker构建
set -e

echo "🧪 快速构建测试"
echo "================"
echo ""

# 清理之前的构建
echo "🧹 清理环境..."
docker system prune -f >/dev/null 2>&1 || true

# 测试简单构建
echo "🔨 测试简单构建 (推荐)..."
if docker build -f Dockerfile.simple -t test-simple:latest . >/dev/null 2>&1; then
    echo "✅ 简单构建: 成功"
    SIMPLE_SUCCESS=true
else
    echo "❌ 简单构建: 失败"
    SIMPLE_SUCCESS=false
fi

# 测试标准构建
echo "🔨 测试标准构建..."
if docker build -f Dockerfile -t test-standard:latest . >/dev/null 2>&1; then
    echo "✅ 标准构建: 成功"
    STANDARD_SUCCESS=true
else
    echo "❌ 标准构建: 失败"
    STANDARD_SUCCESS=false
fi

# 结果汇总
echo ""
echo "📋 测试结果:"
if [ "$SIMPLE_SUCCESS" = true ]; then
    echo "  ✅ 简单构建 (推荐) - 可用"
else
    echo "  ❌ 简单构建 - 失败"
fi

if [ "$STANDARD_SUCCESS" = true ]; then
    echo "  ✅ 标准构建 - 可用"
else
    echo "  ❌ 标准构建 - 失败"
fi

echo ""
if [ "$SIMPLE_SUCCESS" = true ] || [ "$STANDARD_SUCCESS" = true ]; then
    echo "🎉 至少有一种构建方式成功！"
    echo "💡 推荐使用: ./build-docker-fixed.sh"
    
    # 清理测试镜像
    docker rmi test-simple:latest test-standard:latest >/dev/null 2>&1 || true
else
    echo "❌ 所有构建方式都失败了"
    echo ""
    echo "🔍 故障排除建议:"
    echo "  1. 检查网络连接"
    echo "  2. 确保Docker有足够空间 (5GB+)"
    echo "  3. 查看详细错误: docker build -f Dockerfile.simple ."
    echo "  4. 参考故障排除指南: DOCKER_TROUBLESHOOTING.md"
fi

echo ""
echo "🎯 下一步:"
echo "  - 成功: 使用 ./build-docker-fixed.sh 完整构建"
echo "  - 失败: 查看 DOCKER_TROUBLESHOOTING.md"
