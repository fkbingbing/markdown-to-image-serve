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

# Puppeteer网络连接修复
echo ""
echo "🔧 检查Puppeteer网络连接配置..."

# 检查并修复generatePosterImage.ts中的网络连接问题
fix_puppeteer_network() {
    local need_fix=false
    
    # 检查是否使用localhost:3000
    if grep -q "http://localhost:3000" /app/src/pages/api/generatePosterImage.ts 2>/dev/null; then
        echo "❌ generatePosterImage.ts使用localhost:3000"
        need_fix=true
    fi
    
    if grep -q "http://localhost:3000" /app/src/pages/api/generatePoster.ts 2>/dev/null; then
        echo "❌ generatePoster.ts使用localhost:3000"
        need_fix=true
    fi
    
    if [ "$need_fix" = true ]; then
        echo "🔨 应用Puppeteer网络连接修复..."
        return 0
    else
        echo "✅ Puppeteer网络连接配置正确"
        return 1
    fi
}

if fix_puppeteer_network; then
    echo "📝 修复generatePosterImage.ts网络连接..."
    
    # 修复generatePosterImage.ts
    if [ -f "/app/src/pages/api/generatePosterImage.ts" ]; then
        # 备份原文件
        cp /app/src/pages/api/generatePosterImage.ts /app/src/pages/api/generatePosterImage.ts.backup.$(date +%Y%m%d_%H%M%S)
        
        # 替换localhost:3000为127.0.0.1:3000
        sed -i 's|const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";|const baseUrl = process.env.INTERNAL_BASE_URL || process.env.NEXT_PUBLIC_BASE_URL || "http://127.0.0.1:3000";|' /app/src/pages/api/generatePosterImage.ts
        
        echo "✅ generatePosterImage.ts修复完成"
    fi
    
    # 修复generatePoster.ts
    if [ -f "/app/src/pages/api/generatePoster.ts" ]; then
        # 备份原文件
        cp /app/src/pages/api/generatePoster.ts /app/src/pages/api/generatePoster.ts.backup.$(date +%Y%m%d_%H%M%S)
        
        # 替换localhost:3000为127.0.0.1:3000
        sed -i 's|const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";|const baseUrl = process.env.INTERNAL_BASE_URL || process.env.NEXT_PUBLIC_BASE_URL || "http://127.0.0.1:3000";|' /app/src/pages/api/generatePoster.ts
        
        echo "✅ generatePoster.ts修复完成"
    fi
    
    echo "✅ Puppeteer网络连接修复完成"
    echo "💡 现在Puppeteer将使用127.0.0.1:3000连接内部服务"
fi

# URL长度修复 - 检查并应用必要的文件修复
echo ""
echo "🔧 检查URL长度修复..."

# 检查是否需要应用URL长度修复
apply_url_length_fix() {
    local need_fix=false
    
    # 检查posterData.ts是否存在
    if [ ! -f "/app/src/pages/api/posterData.ts" ]; then
        echo "❌ posterData.ts API缺失"
        need_fix=true
    fi
    
    # 检查PosterView.tsx是否包含dataId处理
    if ! grep -q "dataId" /app/src/components/PosterView.tsx 2>/dev/null; then
        echo "❌ PosterView.tsx缺少dataId处理"
        need_fix=true
    fi
    
    # 检查generatePosterImage.ts是否包含API存储逻辑
    if ! grep -q "posterData" /app/src/pages/api/generatePosterImage.ts 2>/dev/null; then
        echo "❌ generatePosterImage.ts缺少API存储逻辑"
        need_fix=true
    fi
    
    if [ "$need_fix" = true ]; then
        echo "🔨 应用URL长度修复..."
        return 0
    else
        echo "✅ URL长度修复已存在"
        return 1
    fi
}

if apply_url_length_fix; then
    # 创建posterData.ts API
    if [ ! -f "/app/src/pages/api/posterData.ts" ]; then
        echo "📝 创建posterData.ts API..."
        cat > /app/src/pages/api/posterData.ts << 'EOF'
/*
 * @Author: docker-startup-fix
 * @Date: 2025-09-19
 * @Description: 海报数据临时存储API，解决URL过长问题
 * @FilePath: /app/src/pages/api/posterData.ts
 */
import { NextApiRequest, NextApiResponse } from "next";

// 内存中的临时存储（生产环境建议使用Redis等）
const tempStorage: Record<string, any> = {};

// 清理过期数据（5分钟过期）
const EXPIRY_TIME = 5 * 60 * 1000; // 5分钟

function cleanExpiredData() {
  const now = Date.now();
  Object.keys(tempStorage).forEach(key => {
    if (tempStorage[key].timestamp < now - EXPIRY_TIME) {
      delete tempStorage[key];
    }
  });
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // 清理过期数据
  cleanExpiredData();

  if (req.method === "POST") {
    // 存储数据
    const { data } = req.body;
    if (!data) {
      return res.status(400).json({ error: "缺少data参数" });
    }

    const dataId = `poster_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    tempStorage[dataId] = {
      data,
      timestamp: Date.now()
    };

    return res.status(200).json({ dataId });
    
  } else if (req.method === "GET") {
    // 获取数据
    const { dataId } = req.query;
    if (!dataId || typeof dataId !== "string") {
      return res.status(400).json({ error: "缺少dataId参数" });
    }

    const stored = tempStorage[dataId];
    if (!stored) {
      return res.status(404).json({ error: "数据未找到或已过期" });
    }

    // 返回数据后删除，确保只能使用一次
    delete tempStorage[dataId];
    return res.status(200).json({ data: stored.data });
    
  } else {
    return res.status(405).json({ error: "只支持 GET 和 POST 请求" });
  }
}
EOF
    fi
    
    # 应用PosterView.tsx修复 (简化版，只添加关键的dataId处理逻辑)
    if ! grep -q "dataId" /app/src/components/PosterView.tsx 2>/dev/null; then
        echo "📝 更新PosterView.tsx以支持dataId..."
        # 这里我们只做最小化修复，避免完全覆盖文件
        # 实际的修复会在热修复脚本中完成
        echo "   (标记需要热修复)"
    fi
    
    # 应用generatePosterImage.ts修复 (简化版，标记需要修复)
    if ! grep -q "posterData" /app/src/pages/api/generatePosterImage.ts 2>/dev/null; then
        echo "📝 标记generatePosterImage.ts需要修复..."
        echo "   (将在热修复脚本中完成)"
    fi
    
    echo "✅ URL长度修复基础设施已就绪"
    echo "💡 提示：运行 ./hotfix-url-length-issue.sh 完成完整修复"
fi

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
