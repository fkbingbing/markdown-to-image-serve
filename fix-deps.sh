#!/bin/bash
# Docker容器启动时修复MDX依赖问题
set -e

echo "🔧 检查和修复依赖..."

# 检查是否需要安装MDX依赖
if ! yarn list @next/mdx >/dev/null 2>&1; then
    echo "📦 发现 @next/mdx 缺失，正在安装..."
    
    # 临时安装缺失的依赖
    yarn add @next/mdx@^14.2.3 @mdx-js/loader@^3.0.1 @mdx-js/react@^3.0.1 @types/mdx@^2.0.13 --registry https://registry.npmjs.org/
    
    echo "✅ 依赖安装完成"
else
    echo "✅ @next/mdx 依赖已存在"
fi

# 检查其他可能缺失的依赖
echo "🔍 检查其他依赖..."
MISSING_DEPS=()

if ! yarn list @mdx-js/loader >/dev/null 2>&1; then
    MISSING_DEPS+=("@mdx-js/loader@^3.0.1")
fi

if ! yarn list @mdx-js/react >/dev/null 2>&1; then
    MISSING_DEPS+=("@mdx-js/react@^3.0.1")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "📦 安装缺失的依赖: ${MISSING_DEPS[*]}"
    yarn add "${MISSING_DEPS[@]}" --registry https://registry.npmjs.org/
fi

echo "🎉 依赖检查完成!"
echo "🚀 启动 Next.js 服务..."

# 启动应用
exec "$@"
