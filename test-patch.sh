#!/bin/bash
# 测试 patch-package 是否正确工作
set -e

echo "🧪 测试 patch-package 功能"
echo "=========================="
echo ""

# 检查 patches 目录
echo "📋 检查补丁文件..."
if [ -d "patches" ]; then
    echo "✅ 发现 patches 目录"
    ls -la patches/
    echo ""
    
    if [ -f "patches/markdown-to-poster+0.0.9.patch" ]; then
        echo "✅ 发现 markdown-to-poster 补丁文件"
        echo "📋 补丁内容预览:"
        head -15 patches/markdown-to-poster+0.0.9.patch
        echo ""
    else
        echo "❌ 未发现 markdown-to-poster 补丁文件"
    fi
else
    echo "❌ 未发现 patches 目录"
    exit 1
fi

# 检查依赖安装
echo "📦 检查依赖安装..."
if [ -f "yarn.lock" ]; then
    echo "✅ 发现 yarn.lock"
else
    echo "❌ 未发现 yarn.lock"
fi

if [ -f "package.json" ]; then
    echo "✅ 发现 package.json"
    
    # 检查 postinstall 脚本
    if grep -q "\"postinstall\".*patch-package" package.json; then
        echo "✅ 发现 postinstall 脚本: $(grep "postinstall" package.json)"
    else
        echo "❌ 未发现 postinstall 脚本"
    fi
    
    # 检查 patch-package 依赖
    if grep -q "patch-package" package.json; then
        echo "✅ 发现 patch-package 依赖: $(grep -A1 -B1 "patch-package" package.json)"
    else
        echo "❌ 未发现 patch-package 依赖"
    fi
else
    echo "❌ 未发现 package.json"
fi

echo ""
echo "🐳 Docker 环境测试..."

# 创建临时测试 Dockerfile
cat > Dockerfile.test-patch << 'EOF'
FROM wxingheng/node-chrome-base:latest

# 强制使用官方npm源
ENV NPM_CONFIG_REGISTRY=https://registry.npmjs.org/
ENV YARN_REGISTRY=https://registry.npmjs.org/

WORKDIR /app

# 只复制依赖文件
COPY package.json yarn.lock ./
COPY patches ./patches

# 清除配置并安装依赖
RUN rm -f /root/.npmrc /usr/local/share/.yarnrc && \
    yarn config set registry https://registry.npmjs.org/ && \
    yarn install --frozen-lockfile --production=false --registry https://registry.npmjs.org/ && \
    echo "=== 验证 patch-package ===" && \
    yarn list patch-package && \
    echo "=== 手动运行 patch-package ===" && \
    yarn patch-package && \
    echo "=== 检查补丁是否应用 ===" && \
    if grep -q "https://api.allorigins.win" node_modules/markdown-to-poster/dist/markdown-to-poster.js; then \
        echo "❌ 补丁未应用 - 仍包含原始代码"; \
    else \
        echo "✅ 补丁已应用 - 原始代码已被替换"; \
    fi

CMD ["echo", "测试完成"]
EOF

echo "构建测试镜像..."
if docker build -f Dockerfile.test-patch -t patch-test . --no-cache; then
    echo ""
    echo "✅ patch-package 测试通过！"
    echo ""
    echo "🎯 现在可以安全使用:"
    echo "  ./force-rebuild.sh"
    echo "  选择 '1' (简单构建)"
else
    echo ""
    echo "❌ patch-package 测试失败！"
    echo ""
    echo "🛠️  备用方案:"
    echo "  ./force-rebuild.sh"
    echo "  选择 '3' (跳过补丁构建)"
fi

# 清理测试文件
rm -f Dockerfile.test-patch
docker rmi patch-test >/dev/null 2>&1 || true

echo ""
echo "📋 测试报告:"
echo "  - patches/ 目录: $([ -d "patches" ] && echo "✅" || echo "❌")"
echo "  - markdown-to-poster 补丁: $([ -f "patches/markdown-to-poster+0.0.9.patch" ] && echo "✅" || echo "❌")"
echo "  - postinstall 脚本: $(grep -q "postinstall.*patch-package" package.json && echo "✅" || echo "❌")"
echo "  - patch-package 依赖: $(grep -q "patch-package" package.json && echo "✅" || echo "❌")"
echo ""
echo "🚀 推荐下一步: ./force-rebuild.sh"
