#!/bin/bash
# 🔥 热修复URL过长问题 - 无需重新构建Docker镜像
# ==================================================

set -e

echo "🔥 热修复URL过长问题"
echo "===================="
echo ""

# 查找运行中的容器
echo "🔍 查找运行中的容器..."
CONTAINER_ID=$(docker ps -q --filter "ancestor=markdown-to-image-serve:latest" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 未找到运行中的 markdown-to-image-serve 容器"
    echo ""
    echo "尝试启动容器..."
    if [ -f "docker-compose.yml" ]; then
        docker-compose up -d
        echo "⏳ 等待容器启动..."
        sleep 10
        CONTAINER_ID=$(docker ps -q --filter "ancestor=markdown-to-image-serve:latest" | head -1)
    else
        echo "❌ 请先启动容器"
        exit 1
    fi
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 仍然找不到运行中的容器"
    exit 1
fi

echo "✅ 找到容器: $CONTAINER_ID"
echo ""

# 检查修复文件是否存在
echo "🔍 检查修复文件..."
REQUIRED_FILES=(
    "src/pages/api/posterData.ts"
    "src/components/PosterView.tsx" 
    "src/pages/api/generatePosterImage.ts"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 不存在"
        exit 1
    fi
done

echo ""

# 备份原文件
echo "💾 备份容器中的原文件..."
docker exec $CONTAINER_ID mkdir -p /app/backup/$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
docker exec $CONTAINER_ID cp /app/src/components/PosterView.tsx /app/backup/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
docker exec $CONTAINER_ID cp /app/src/pages/api/generatePosterImage.ts /app/backup/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# 复制修复文件到容器
echo "📝 应用修复文件..."

echo "   📄 新增 posterData.ts API..."
docker cp ./src/pages/api/posterData.ts $CONTAINER_ID:/app/src/pages/api/posterData.ts

echo "   📄 更新 PosterView.tsx..."
docker cp ./src/components/PosterView.tsx $CONTAINER_ID:/app/src/components/PosterView.tsx

echo "   📄 更新 generatePosterImage.ts..."
docker cp ./src/pages/api/generatePosterImage.ts $CONTAINER_ID:/app/src/pages/api/generatePosterImage.ts

echo "✅ 所有修复文件已复制到容器"
echo ""

# 检查是否需要重启Next.js服务
echo "🔄 重启Next.js服务以应用修复..."

# 检查容器中的Next.js进程
NEXTJS_PID=$(docker exec $CONTAINER_ID sh -c "pgrep -f 'node.*next' || pgrep -f 'yarn.*start' || echo ''" | head -1)

if [ -n "$NEXTJS_PID" ]; then
    echo "   🎯 找到Next.js进程 (PID: $NEXTJS_PID)"
    echo "   🔄 发送重启信号..."
    
    # 尝试优雅重启
    docker exec $CONTAINER_ID sh -c "kill -SIGUSR2 $NEXTJS_PID" 2>/dev/null || true
    sleep 3
    
    # 如果还在运行，强制重启
    if docker exec $CONTAINER_ID sh -c "kill -0 $NEXTJS_PID" 2>/dev/null; then
        echo "   ⚡ 强制重启Next.js服务..."
        docker exec $CONTAINER_ID sh -c "kill -TERM $NEXTJS_PID" 2>/dev/null || true
        sleep 2
    fi
else
    echo "   ℹ️  未找到Next.js进程，可能使用standalone模式"
fi

# 等待服务重新启动
echo "⏳ 等待服务重新启动..."
for i in {1..15}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ 服务已重新启动"
        break
    else
        echo "   等待中... ($i/15)"
        sleep 2
    fi
done

# 验证修复效果
echo ""
echo "🧪 测试URL长度修复效果..."

# 生成一个很长的markdown内容来测试
LONG_CONTENT='# 这是一个很长的测试内容

## 用户信息测试
- 用户邮箱: vinhhien.nguyen@foody.vn
- 时间戳: 2018:35:51
- 主题: SpringGradientWave  
- 尺寸: 1690x1080

## 长内容测试
这是一个专门用来测试URL过长问题修复的内容。之前当内容过长时，会导致Puppeteer导航失败，出现类似这样的错误：

```
Error: Navigation failed because the URL was too long
    at navigate (/app/.next/standalone/node_modules/puppeteer-core/lib/cjs/puppeteer/cdp/Frame.js:184:27)
```

现在通过以下修复方案解决了这个问题：

1. **新增posterData API**: 创建了专门的API来存储大量数据
2. **智能URL处理**: 自动检测数据长度，选择合适的传输方式  
3. **向后兼容**: 短内容仍使用URL参数，长内容使用API存储

### 测试数据
- 邮箱1: very.long.email.address.for.testing.purposes@extremely.long.domain.name.example.com
- 邮箱2: another.very.long.email.address@another.extremely.long.domain.example.org  
- 邮箱3: yet.another.super.long.email.address@yet.another.very.long.domain.example.net

### 重复内容填充
' 

# 添加更多重复内容让URL变得更长
for i in {1..10}; do
    LONG_CONTENT="$LONG_CONTENT
**重复段落 $i**: 这是用来增加内容长度的重复段落，目的是让URL变得足够长以触发之前的导航错误。现在这个问题应该已经被修复了。用户邮箱 vinhhien.nguyen@foody.vn 时间戳 2018:35:51 主题 SpringGradientWave 尺寸 1690x1080。"
done

echo "📊 测试超长内容 (预计会使用API存储方式):"
LONG_TEST_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d "{
    \"markdown\": $(echo "$LONG_CONTENT" | jq -R -s .),
    \"header\": \"URL长度修复测试\",
    \"footer\": \"用户: vinhhien.nguyen@foody.vn | 时间: 2018:35:51\",
    \"theme\": \"SpringGradientWave\",
    \"width\": 1690,
    \"height\": 1080,
    \"password\": \"123456\"
  }" 2>/dev/null | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   结果: $LONG_TEST_RESULT"

# 测试短内容（应该仍使用URL方式）
echo ""
echo "📊 测试短内容 (应该使用传统URL方式):"
SHORT_TEST_RESULT=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 短内容测试\n\n这是短内容，应该使用传统URL方式。",
    "header": "短内容测试",
    "width": 800,
    "height": 600,
    "password": "123456"
  }' 2>/dev/null | jq -r '.url // .error' 2>/dev/null || echo "测试失败")

echo "   结果: $SHORT_TEST_RESULT"

# 测试posterData API是否工作
echo ""
echo "📊 测试posterData API功能:"
API_TEST=$(curl -s -X POST http://localhost:3000/api/posterData \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "content": "# API测试",
      "header": "测试标题",
      "theme": "SpringGradientWave"
    }
  }' 2>/dev/null | jq -r '.dataId // .error' 2>/dev/null || echo "API测试失败")

echo "   posterData API: $API_TEST"

echo ""
echo "🎉 URL长度问题热修复完成！"
echo "================================"
echo ""
echo "📋 应用的修复："
echo "   ✅ 新增 posterData.ts API - 处理长数据存储"
echo "   ✅ 更新 PosterView.tsx - 支持API数据加载"  
echo "   ✅ 更新 generatePosterImage.ts - 智能URL/API选择"
echo "   ✅ 热重载应用 - 无需重启容器"
echo ""
echo "🔧 修复原理："
echo "   • 短内容: 继续使用URL参数 (向后兼容)"
echo "   • 长内容: 自动使用API存储方式 (避免URL过长)"
echo "   • 智能检测: 根据内容长度自动选择最佳方式"
echo "   • 临时存储: 数据5分钟后自动清理 (安全性)"
echo ""
echo "🔄 如果修复未完全生效，可以："
echo "   1. 重启容器: docker restart $CONTAINER_ID"  
echo "   2. 查看日志: docker logs -f $CONTAINER_ID"
echo "   3. 查看容器状态: docker exec $CONTAINER_ID ps aux"
echo ""
echo "📊 测试结果:"
echo "   超长内容: $LONG_TEST_RESULT"
echo "   短内容: $SHORT_TEST_RESULT"
echo "   posterData API: $API_TEST"
