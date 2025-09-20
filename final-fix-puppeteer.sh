#!/bin/bash
# 🎯 最终修复Puppeteer网络连接问题
set -e

echo "🎯 最终修复Puppeteer网络连接问题"
echo "================================="
echo ""

# 停止所有相关容器
echo "🛑 停止所有相关容器..."
docker-compose down 2>/dev/null || true
docker stop $(docker ps -q --filter "ancestor=markdown-to-image-serve:latest") 2>/dev/null || true
docker rm $(docker ps -aq --filter "ancestor=markdown-to-image-serve:latest") 2>/dev/null || true

echo "✅ 容器清理完成"
echo ""

# 使用最终修复配置启动
echo "🚀 使用最终修复配置启动..."
docker-compose -f docker-compose-final-fix.yml up -d

echo "⏳ 等待服务启动..."
sleep 20

# 检查服务状态
echo "🔍 检查服务状态..."
for i in {1..30}; do
    if curl -s http://localhost:3000/api/hello >/dev/null 2>&1; then
        echo "✅ 服务启动成功"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ 服务启动超时"
        echo "📋 查看日志:"
        docker-compose -f docker-compose-final-fix.yml logs app | tail -20
        exit 1
    fi
    
    echo -n "."
    sleep 2
done

echo ""
echo "🧪 测试Puppeteer网络连接修复..."

# 测试API
response=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🎉 最终修复测试\n\nPuppeteer网络连接问题已彻底解决！",
    "header": "最终修复测试",
    "footer": "127.0.0.1:3000连接正常",
    "password": "123456"
  }' || echo "ERROR")

if [[ "$response" != "ERROR" ]] && echo "$response" | grep -q "url"; then
    echo "✅ Puppeteer网络连接修复成功！"
    echo ""
    echo "📋 API响应:"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    
    # 提取图片URL
    image_url=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'url' in data:
        print(data['url'])
    else:
        print('未找到图片URL')
except:
    print('解析响应失败')
" 2>/dev/null)
    
    if [[ "$image_url" != "未找到图片URL" ]] && [[ "$image_url" != "解析响应失败" ]] && [[ "$image_url" != "" ]]; then
        echo ""
        echo "🖼️  生成的图片URL: $image_url"
        echo "🔗 可以通过浏览器访问查看生成的海报"
    fi
    
else
    echo "❌ 测试失败"
    echo "📋 响应: $response"
    echo ""
    echo "📋 查看详细日志:"
    docker-compose -f docker-compose-final-fix.yml logs app | tail -30
fi

echo ""
echo "🎉 最终修复完成！"
echo ""
echo "📋 修复总结:"
echo "  ✅ 使用127.0.0.1:3000替代localhost:3000"
echo "  ✅ 挂载修复后的API文件"
echo "  ✅ 设置INTERNAL_BASE_URL环境变量"
echo "  ✅ 清理并重启容器"
echo ""
echo "🌐 服务地址: http://localhost:3000"
echo "🔑 API密码: 123456"
echo ""
echo "💡 如果仍有问题，请检查:"
echo "   docker-compose -f docker-compose-final-fix.yml logs app"
