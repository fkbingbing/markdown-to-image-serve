#!/bin/bash
# 调试Docker构建中的registry配置问题
set -e

echo "🔍 调试 Docker 构建 Registry 配置问题"
echo "====================================="
echo ""

# 检查基础镜像配置
echo "📋 检查基础镜像中的Registry配置..."
echo "docker run --rm wxingheng/node-chrome-base:latest /bin/bash -c \"ls -la /root/.npmrc /usr/local/share/.yarnrc /usr/local/etc/npmrc 2>/dev/null || echo 'No config files found'; yarn config list | grep registry || echo 'No yarn registry set'; npm config get registry\""

docker run --rm wxingheng/node-chrome-base:latest /bin/bash -c "
echo '=== 检查配置文件 ==='
ls -la /root/.npmrc /usr/local/share/.yarnrc /usr/local/etc/npmrc 2>/dev/null || echo 'No config files found'
echo ''
echo '=== Yarn Registry ==='
yarn config list | grep registry || echo 'No yarn registry found'
echo ''
echo '=== NPM Registry ==='
npm config get registry
echo ''
echo '=== 环境变量 ==='
printenv | grep -E '(REGISTRY|NPM|YARN)' || echo 'No registry env vars found'
"

echo ""
echo "🧪 测试修复后的配置..."

# 创建临时测试Dockerfile
cat > Dockerfile.debug << 'EOF'
FROM wxingheng/node-chrome-base:latest

# 强制使用官方npm源
ENV NPM_CONFIG_REGISTRY=https://registry.npmjs.org/
ENV YARN_REGISTRY=https://registry.npmjs.org/

WORKDIR /app

# 检查和清除配置
RUN echo "=== 修复前 ===" && \
    ls -la /root/.npmrc /usr/local/share/.yarnrc /usr/local/etc/npmrc 2>/dev/null || echo 'No config files found' && \
    yarn config list | grep registry || echo 'No yarn registry found' && \
    npm config get registry && \
    echo "" && \
    echo "=== 开始修复 ===" && \
    rm -f /root/.npmrc /usr/local/share/.yarnrc /usr/local/etc/npmrc && \
    yarn config set registry https://registry.npmjs.org/ && \
    npm config set registry https://registry.npmjs.org/ && \
    echo "" && \
    echo "=== 修复后 ===" && \
    yarn config list | grep registry && \
    npm config get registry

# 测试下载一个小包
COPY package.json ./
RUN echo "=== 测试下载包 ===" && \
    timeout 60 yarn add lodash@4.17.21 --no-save --verbose 2>&1 | head -20 | grep -E "(registry|GET|resolved)" || echo "Download test completed"

CMD ["echo", "Debug completed"]
EOF

echo "构建调试镜像..."
if docker build -f Dockerfile.debug -t registry-debug . --no-cache --progress=plain | tail -30; then
    echo ""
    echo "✅ 调试构建成功！"
    echo ""
    echo "🎯 现在测试修复后的正式构建:"
    echo "  ./build-docker-fixed.sh"
    echo "  选择 '1' (简单构建)"
    echo ""
else
    echo ""
    echo "❌ 调试构建失败"
    echo "💡 可能的原因:"
    echo "  1. 网络问题"
    echo "  2. Docker配置问题"
    echo "  3. 基础镜像问题"
    echo ""
    echo "🔧 建议解决方案:"
    echo "  1. 检查网络: ping registry.npmjs.org"
    echo "  2. 重启Docker: docker restart"
    echo "  3. 清理缓存: docker system prune -f"
fi

# 清理临时文件
rm -f Dockerfile.debug

echo ""
echo "🎉 调试完成！"
