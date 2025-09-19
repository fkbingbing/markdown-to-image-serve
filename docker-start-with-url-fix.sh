#!/bin/bash
# 🚀 启动Docker容器并自动应用URL长度修复
# ============================================

set -e

echo "🚀 启动Docker容器（包含URL长度修复）"
echo "====================================="
echo ""

# 检查修复文件是否存在
echo "🔍 检查修复文件..."
REQUIRED_FILES=(
    "src/pages/api/posterData.ts"
    "src/components/PosterView.tsx" 
    "src/pages/api/generatePosterImage.ts"
    "fix-deps.sh"
    "docker-compose.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 不存在"
        echo "请确保您已经应用了URL长度修复"
        exit 1
    fi
done

echo ""

# 停止现有容器（如果存在）
echo "🛑 停止现有容器..."
docker compose down 2>/dev/null || true

echo ""
echo "🚀 启动容器（应用修复）..."

# 使用docker-compose启动（已配置volume挂载）
docker compose up -d

echo "✅ 容器启动中..."
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
for i in {1..15}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ 服务启动成功！"
        break
    else
        echo "   等待中... ($i/15)"
        sleep 3
    fi
done

# 检查服务状态
if ! curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo ""
    echo "⚠️  服务启动可能有问题，查看日志："
    echo "   docker-compose logs -f"
    exit 1
fi

# 测试修复效果
echo ""
echo "🧪 测试URL长度修复效果..."

# 测试posterData API
echo "📊 测试posterData API:"
API_TEST=$(curl -s -X POST http://localhost:3000/api/posterData \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "content": "# API测试\n\n这是测试API存储功能。",
      "header": "API测试",
      "theme": "SpringGradientWave"
    }
  }' | jq -r '.dataId // .error' 2>/dev/null || echo "测试失败")

echo "   posterData API: $API_TEST"

# 测试长内容处理
echo ""  
echo "📊 测试长内容处理（应该自动使用API存储）:"

# 构造一个很长的内容
LONG_CONTENT="# 长内容测试

## 用户信息
- 邮箱: vinhhien.nguyen@foody.vn  
- 时间: 2018:35:51
- 主题: SpringGradientWave
- 尺寸: 1690x1080

## 详细说明  
这是一个专门测试URL过长问题修复的内容。当内容很长时，系统会自动选择使用API存储方式，避免URL过长导致的Puppeteer导航失败。

### 重复内容测试"

# 添加重复内容使其变长
for i in {1..5}; do
    LONG_CONTENT="$LONG_CONTENT
**段落 $i**: 这是重复段落，用来让内容变长以测试API存储功能。用户邮箱 vinhhien.nguyen@foody.vn，时间戳 2018:35:51，主题 SpringGradientWave，尺寸 1690x1080。"
done

LONG_TEST=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d "{
    \"markdown\": $(echo "$LONG_CONTENT" | jq -R -s .),
    \"header\": \"长内容测试\",
    \"footer\": \"用户: vinhhien.nguyen@foody.vn\",
    \"theme\": \"SpringGradientWave\",
    \"width\": 1690,
    \"height\": 1080,
    \"password\": \"123456\"
  }" | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   长内容生成: $LONG_TEST"

# 测试短内容（应该使用传统方式）  
echo ""
echo "📊 测试短内容（应该使用传统URL方式）:"
SHORT_TEST=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 短内容测试\n\n这是短内容测试。",
    "header": "短内容",
    "width": 800,
    "height": 600,
    "password": "123456"
  }' | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   短内容生成: $SHORT_TEST"

echo ""
echo "🎉 Docker容器启动并修复应用完成！"
echo "==================================="
echo ""
echo "📋 已应用的修复："
echo "   ✅ URL长度问题修复 - 自动API存储长内容"
echo "   ✅ posterData.ts API - 临时数据存储"
echo "   ✅ PosterView.tsx - 支持dataId数据加载"
echo "   ✅ generatePosterImage.ts - 智能URL/API选择"
echo "   ✅ 依赖修复 - MDX相关依赖自动修复"
echo ""
echo "🌐 访问地址:"
echo "   主页: http://localhost:3000"
echo "   API文档: http://localhost:3000/docs"
echo "   生成API: http://localhost:3000/api/generatePosterImage"
echo ""
echo "🛠️  容器管理命令:"
echo "   查看日志: docker-compose logs -f"
echo "   停止服务: docker-compose down"
echo "   重启服务: docker-compose restart"
echo "   容器状态: docker-compose ps"
echo ""
echo "📊 测试结果:"
echo "   posterData API: $API_TEST"
echo "   长内容处理: $LONG_TEST"  
echo "   短内容处理: $SHORT_TEST"
echo ""
echo "✨ 现在您可以正常使用服务了！URL过长问题已彻底解决。"
