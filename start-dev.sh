#!/bin/bash
# 🚀 启动开发服务器

echo "🚀 启动开发服务器..."
echo "========================"
echo ""

# 设置开发模式环境变量
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1

# 检查端口是否被占用
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  端口3000已被占用"
    echo "正在终止占用端口的进程..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

echo "🏃‍♂️ 启动Next.js开发服务器..."
echo "访问地址: http://localhost:3000"
echo "API测试: http://localhost:3000/api/generatePosterImage"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

yarn dev
