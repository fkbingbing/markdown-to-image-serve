#!/bin/bash
# Docker容器启动时修复MDX依赖问题
set -e

echo "🔧 检查和修复依赖..."

# 更准确的依赖检查方法 - 直接检查node_modules目录
check_dep() {
    local dep_name="$1"
    if [ -d "/app/node_modules/$dep_name" ] && [ -f "/app/node_modules/$dep_name/package.json" ]; then
        return 0
    else
        return 1
    fi
}

# 必需的MDX依赖列表
REQUIRED_DEPS=(
    "@next/mdx@^14.2.3"
    "@mdx-js/loader@^3.0.1" 
    "@mdx-js/react@^3.0.1"
    "@types/mdx@^2.0.13"
)

MISSING_DEPS=()

# 检查每个依赖
for dep_spec in "${REQUIRED_DEPS[@]}"; do
    dep_name=$(echo "$dep_spec" | cut -d'@' -f1-2)  # 处理@scope/package的情况
    if ! check_dep "$dep_name"; then
        echo "❌ 缺失依赖: $dep_name"
        MISSING_DEPS+=("$dep_spec")
    else
        echo "✅ 依赖存在: $dep_name"
    fi
done

# 如果有缺失的依赖，安装它们
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo "📦 安装缺失的依赖: ${MISSING_DEPS[*]}"
    echo "🌐 使用官方npm源: https://registry.npmjs.org/"
    
    # 确保使用官方源并安装依赖
    yarn config set registry https://registry.npmjs.org/
    yarn add "${MISSING_DEPS[@]}" --no-lockfile --ignore-engines
    
    echo "✅ 依赖安装完成"
else
    echo "✅ 所有MDX依赖都已存在"
fi

# 最终验证 - 尝试require关键依赖
echo ""
echo "🔍 最终验证依赖可用性..."
if node -e "require('@next/mdx')" 2>/dev/null; then
    echo "✅ @next/mdx 可以正常加载"
else
    echo "⚠️  @next/mdx 加载测试失败，尝试强制重新安装..."
    yarn add @next/mdx@^14.2.3 --force --no-lockfile --ignore-engines --registry https://registry.npmjs.org/
fi

echo ""
echo "🎉 依赖检查和修复完成!"

# 智能启动模式检测
echo "🔍 检测启动模式..."

# 检查是否存在 standalone 构建
if [ -f "/app/.next/standalone/server.js" ]; then
    echo "✅ 发现 standalone 构建，使用生产模式启动"
    echo "🚀 启动 Next.js 服务 (standalone 模式)..."
    # 复制静态资源到 standalone 目录
    if [ -d "/app/.next/static" ] && [ ! -d "/app/.next/standalone/.next/static" ]; then
        echo "📁 复制静态资源..."
        cp -r /app/.next/static /app/.next/standalone/.next/
    fi
    if [ -d "/app/public" ] && [ ! -d "/app/.next/standalone/public" ]; then
        echo "📁 复制公共资源..."
        cp -r /app/public /app/.next/standalone/
    fi
    cd /app/.next/standalone
    exec node server.js
elif [ "$1" = "npm" ] || [ "$1" = "yarn" ] || [ "$1" = "node" ]; then
    echo "🚀 使用传入的命令启动: $@"
    exec "$@"
else
    echo "⚠️  未找到 standalone 构建，使用开发模式"
    echo "🚀 启动 Next.js 服务 (开发模式)..."
    exec npm run dev
fi
