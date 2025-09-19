#!/bin/bash
# 详细调试API问题
set -e

API_BASE_URL="http://10.71.2.253:3000"
API_PASSWORD="123456"

echo "🔍 详细调试 API 问题"
echo "==================="
echo ""

# 测试更简单的请求
echo "🧪 测试1: 最简单的海报请求..."
simple_test='{"markdown":"# Hello","password":"123456"}'

echo "📤 发送最简请求: $simple_test"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST \
  -H "Content-Type: application/json" \
  -d "$simple_test" \
  "$API_BASE_URL/api/generatePosterImage")

echo "📥 完整响应:"
echo "$response"
echo ""

# 检查响应状态码
http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
echo "🔢 HTTP状态码: $http_code"

if [ "$http_code" = "200" ]; then
    echo "✅ HTTP状态正常"
else
    echo "❌ HTTP状态异常"
fi

# 提取JSON响应
json_response=$(echo "$response" | grep -v "HTTP_CODE:")
echo ""
echo "📋 JSON响应内容:"
echo "$json_response" | python3 -m json.tool 2>/dev/null || echo "$json_response"

# 检查错误详情
if echo "$json_response" | grep -q "error"; then
    echo ""
    echo "🔍 发现错误，尝试获取更多信息..."
    
    # 检查是否有详细错误信息
    details=$(echo "$json_response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'details' in data:
        print(f\"错误详情: {data['details']}\")
    elif 'message' in data:
        print(f\"错误消息: {data['message']}\")
    else:
        print(f\"错误类型: {data.get('error', '未知')}\")
except:
    print('无法解析错误信息')
" 2>/dev/null)
    echo "$details"
fi

echo ""
echo "🧪 测试2: 检查服务器日志端点..."

# 尝试访问一些调试端点
debug_endpoints=("/api/hello" "/api/generatePoster" "/health" "/status")

for endpoint in "${debug_endpoints[@]}"; do
    echo "🔗 测试端点: $endpoint"
    test_response=$(curl -s -w "HTTP:%{http_code}" "$API_BASE_URL$endpoint" || echo "FAILED")
    echo "  响应: $test_response"
done

echo ""
echo "🧪 测试3: 检查依赖和环境..."

# 创建一个测试脚本来检查容器内部状态
echo "💡 建议的排查步骤："
echo ""
echo "1. 查看服务器日志:"
echo "   docker logs <container-name>"
echo "   或 docker-compose logs app"
echo ""
echo "2. 进入容器检查依赖:"
echo "   docker exec -it <container-name> /bin/bash"
echo "   然后运行:"
echo "   node -e \"console.log(require('@next/mdx'))\""
echo "   puppeteer --version"
echo ""
echo "3. 检查Chrome/Puppeteer:"
echo "   which google-chrome-unstable"
echo "   google-chrome-unstable --version"
echo ""
echo "4. 手动测试生成功能:"
echo "   cd /app"
echo "   node -e \"require('./src/pages/api/generatePosterImage')\""
echo ""

# 创建容器内诊断脚本
cat > container-debug.sh << 'EOF'
#!/bin/bash
# 容器内诊断脚本
echo "🔍 容器内环境检查"
echo "================="

echo "📋 Node.js版本:"
node --version

echo "📋 NPM/Yarn版本:"
npm --version
yarn --version

echo "📋 关键依赖检查:"
echo "- Next.js:"
node -e "console.log(require('next/package.json').version)" 2>/dev/null || echo "❌ Next.js 不可用"

echo "- @next/mdx:"
node -e "console.log('✅ @next/mdx 可用')" 2>/dev/null || echo "❌ @next/mdx 不可用"

echo "- Puppeteer:"
node -e "console.log(require('puppeteer-core/package.json').version)" 2>/dev/null || echo "❌ Puppeteer 不可用"

echo "📋 Chrome检查:"
if command -v google-chrome-unstable >/dev/null 2>&1; then
    echo "✅ Chrome可执行文件存在"
    google-chrome-unstable --version 2>/dev/null || echo "❌ Chrome无法运行"
else
    echo "❌ Chrome可执行文件不存在"
fi

echo "📋 文件系统权限:"
ls -la /app/ | head -5

echo "📋 临时目录权限:"
ls -la /tmp/ | head -3

echo "📋 环境变量:"
env | grep -E "(NODE|CHROME|API|NEXT)" | sort

echo "🎯 诊断完成"
EOF

chmod +x container-debug.sh

echo ""
echo "📁 已创建容器诊断脚本: container-debug.sh"
echo ""
echo "🚀 运行容器诊断："
echo "   docker cp container-debug.sh <container-name>:/tmp/"
echo "   docker exec <container-name> /tmp/container-debug.sh"
echo ""
echo "🎯 或者直接运行完整诊断："
echo "   docker exec <container-name> /bin/bash -c '"
echo "     echo '=== 依赖检查 ===';"
echo "     node -e \"try{require('@next/mdx'); console.log('✅ @next/mdx OK')}catch(e){console.log('❌ @next/mdx:', e.message)}\";"
echo "     echo '=== Chrome检查 ===';"
echo "     google-chrome-unstable --version;"
echo "     echo '=== 权限检查 ===';"
echo "     ls -la /app/public/uploads/ || mkdir -p /app/public/uploads/;"
echo "   '"

echo ""
echo "🎉 调试脚本执行完成"
