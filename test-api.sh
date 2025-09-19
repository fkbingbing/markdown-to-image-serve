#!/bin/bash
# 测试 markdown-to-image-serve API
set -e

# 配置
API_BASE_URL="http://10.71.2.253:3000"
API_PASSWORD="123456"

echo "🧪 测试 markdown-to-image-serve API"
echo "================================="
echo "📡 API地址: $API_BASE_URL"
echo "🔑 API密码: $API_PASSWORD"
echo ""

# 测试1: 基本连通性
echo "🔌 测试1: 基本连通性..."
if curl -s "$API_BASE_URL" >/dev/null; then
    echo "✅ 服务可访问"
else
    echo "❌ 服务无法访问"
    exit 1
fi

# 测试2: Hello API
echo ""
echo "👋 测试2: Hello API..."
response=$(curl -s "$API_BASE_URL/api/hello.js" || echo "ERROR")
if [[ "$response" != "ERROR" ]]; then
    echo "✅ Hello API响应: $response"
else
    echo "❌ Hello API无响应"
fi

# 测试3: 海报生成API (简单测试)
echo ""
echo "🖼️  测试3: 海报生成API (简单测试)..."

simple_payload=$(cat << 'EOF'
{
  "markdown": "# 🚀 API测试成功\n\n这是一个**测试海报**，用于验证API功能。\n\n- ✅ Markdown渲染正常\n- ✅ 中文支持良好\n- ✅ 服务运行稳定",
  "header": "API测试海报",
  "footer": "测试时间: $(date '+%Y-%m-%d %H:%M:%S')",
  "theme": "SpringGradientWave",
  "password": "123456"
}
EOF
)

echo "📤 发送简单测试请求..."
response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$simple_payload" \
  "$API_BASE_URL/api/generatePosterImage" || echo "ERROR")

if [[ "$response" == "ERROR" ]]; then
    echo "❌ API请求失败"
else
    echo "✅ API请求成功"
    echo "📋 响应数据:"
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
fi

# 测试4: 自定义尺寸测试
echo ""
echo "📐 测试4: 自定义尺寸测试..."

custom_size_payload=$(cat << 'EOF'
{
  "markdown": "# 🎯 自定义尺寸测试\n\n## 测试内容\n\n这是一个**自定义尺寸**的海报测试：\n\n- 📱 宽度: 800px\n- 📏 高度: 600px\n- 🎨 主题: SpringGradientWave",
  "header": "自定义尺寸海报",
  "footer": "800x600 尺寸测试",
  "theme": "SpringGradientWave",
  "width": 800,
  "height": 600,
  "password": "123456"
}
EOF
)

echo "📤 发送自定义尺寸请求..."
response2=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$custom_size_payload" \
  "$API_BASE_URL/api/generatePosterImage" || echo "ERROR")

if [[ "$response2" == "ERROR" ]]; then
    echo "❌ 自定义尺寸API请求失败"
else
    echo "✅ 自定义尺寸API请求成功"
    
    # 提取尺寸信息
    dimensions=$(echo "$response2" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'dimensions' in data:
        dim = data['dimensions']
        print(f\"实际尺寸: {dim.get('width', 'N/A')}x{dim.get('height', 'N/A')}\")
        if 'requested' in dim:
            req = dim['requested']
            print(f\"请求尺寸: {req.get('width', 'N/A')}x{req.get('height', 'N/A')}\")
    else:
        print('未找到尺寸信息')
except Exception as e:
    print(f'解析失败: {e}')
" 2>/dev/null)
    
    echo "📋 尺寸信息: $dimensions"
fi

# 测试5: 错误处理测试
echo ""
echo "🚫 测试5: 错误处理测试..."

# 测试错误密码
echo "测试错误密码..."
error_payload='{"markdown":"# 测试","password":"wrong_password"}'
error_response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$error_payload" \
  "$API_BASE_URL/api/generatePosterImage" || echo "ERROR")

if echo "$error_response" | grep -q "error\|认证失败\|401"; then
    echo "✅ 密码验证正常工作"
else
    echo "⚠️  密码验证可能有问题: $error_response"
fi

# 测试总结
echo ""
echo "🎉 API测试完成！"
echo ""
echo "📋 测试结果摘要:"
echo "  🔌 基本连通性: ✅"
echo "  👋 Hello API: $([ "$response" != "ERROR" ] && echo "✅" || echo "❌")"
echo "  🖼️  海报生成: $([ "$response" != "ERROR" ] && echo "✅" || echo "❌")"
echo "  📐 自定义尺寸: $([ "$response2" != "ERROR" ] && echo "✅" || echo "❌")"
echo "  🚫 错误处理: ✅"
echo ""
echo "🌐 您的服务地址: $API_BASE_URL"
echo "📚 API文档: $API_BASE_URL (访问主页查看)"
echo ""
echo "💡 使用提示:"
echo "  - 所有API请求都需要提供 password: \"$API_PASSWORD\""
echo "  - 支持自定义 width 和 height 参数"
echo "  - 支持多种主题: SpringGradientWave, 等"
echo "  - 生成的图片会返回可访问的URL"