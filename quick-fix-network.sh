#!/bin/bash
# 🚀 快速修复Puppeteer网络连接问题
set -e

echo "🚀 快速修复Puppeteer网络连接问题"
echo "================================="
echo ""

# 停止当前容器
echo "🛑 停止当前容器..."
docker-compose down 2>/dev/null || true

# 使用修复后的配置启动
echo "🚀 使用修复后的配置启动..."
docker-compose -f docker-compose-with-network-fix.yml up -d

echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
if curl -s http://localhost:3000/api/hello >/dev/null 2>&1; then
    echo "✅ 服务启动成功"
    
    echo ""
    echo "🧪 测试Puppeteer网络连接修复..."
    
    # 测试API
    response=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
      -H "Content-Type: application/json" \
      -d '{
        "markdown": "# 🎉 网络修复测试\n\nPuppeteer网络连接已修复！",
        "header": "网络修复测试",
        "footer": "127.0.0.1:3000连接正常",
        "password": "123456"
      }' || echo "ERROR")
    
    if [[ "$response" != "ERROR" ]] && echo "$response" | grep -q "url"; then
        echo "✅ Puppeteer网络连接修复成功！"
        echo "📋 响应:"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    else
        echo "❌ 测试失败，请检查日志"
        echo "📋 响应: $response"
    fi
    
else
    echo "❌ 服务启动失败"
    echo "📋 查看日志: docker-compose -f docker-compose-with-network-fix.yml logs app"
fi

echo ""
echo "🎉 快速修复完成！"
echo ""
echo "📋 修复内容:"
echo "  ✅ 使用127.0.0.1:3000替代localhost:3000"
echo "  ✅ 挂载修复后的API文件"
echo "  ✅ 设置INTERNAL_BASE_URL环境变量"
echo ""
echo "🌐 服务地址: http://localhost:3000"
echo "🔑 API密码: 123456"
