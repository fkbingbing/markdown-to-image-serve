#!/bin/bash
# 文件: verify-all-fixes-complete.sh
# 描述: 全面检查所有修复是否已集成到源代码中，确保重新编译Docker不会丢失任何修复

echo "🔍 全面验证所有修复已集成到源代码"
echo "=================================="
echo "目的: 确保重新编译Docker镜像时不会丢失任何修复"
echo ""

SERVICE_DIR="/Users/xiangping.liao/Documents/wp/crocodile/markdowntoimage/markdown-to-image-serve"
cd "$SERVICE_DIR"

# 验证结果
TOTAL_CHECKS=0
PASSED_CHECKS=0

check_result() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$1" -eq 0 ]; then
        echo "  ✅ $2"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo "  ❌ $2"
    fi
}

echo "📋 1. MDX依赖修复验证"
echo "===================="
grep -q "@next/mdx" package.json
check_result $? "package.json中包含@next/mdx依赖"

grep -q "@mdx-js/loader" package.json
check_result $? "package.json中包含@mdx-js/loader依赖"

grep -q "@mdx-js/react" package.json
check_result $? "package.json中包含@mdx-js/react依赖"

grep -q "postinstall.*patch-package" package.json
check_result $? "package.json中包含patch-package的postinstall脚本"

echo ""
echo "📋 2. Docker构建修复验证"
echo "======================="
grep -q "NPM_CONFIG_REGISTRY=https://registry.npmjs.org/" Dockerfile
check_result $? "Dockerfile中包含npm官方源配置"

grep -q "YARN_REGISTRY=https://registry.npmjs.org/" Dockerfile
check_result $? "Dockerfile中包含yarn官方源配置"

grep -q "patch-package" Dockerfile
check_result $? "Dockerfile中包含patch-package验证和安装"

grep -q "NODE_OPTIONS.*max-old-space-size" Dockerfile
check_result $? "Dockerfile中包含内存优化配置"

grep -q "yarn install.*production=false" Dockerfile
check_result $? "Dockerfile中安装开发依赖（包含patch-package）"

echo ""
echo "📋 3. Chrome路径修复验证"
echo "====================="
grep -q "CHROME_PATH=/usr/bin/chromium" docker-compose.yml
check_result $? "docker-compose.yml中Chrome路径已修复"

grep -q "CHROME_PATH=/usr/bin/chromium" docker-compose.prod.yml 2>/dev/null
check_result $? "docker-compose.prod.yml中Chrome路径已修复（如果存在）"

echo ""
echo "📋 4. 表格和文本截断修复验证"
echo "========================"
grep -q "max-width: none !important" src/components/PosterView.tsx
check_result $? "PosterView.tsx中包含CSS宽度限制覆盖"

grep -q "table-layout: auto !important" src/components/PosterView.tsx
check_result $? "PosterView.tsx中包含表格样式修复"

grep -q "wordWrap.*break-word" src/components/PosterView.tsx
check_result $? "PosterView.tsx中包含容器文本换行修复"

grep -q "white-space: pre-wrap !important" src/components/PosterView.tsx
check_result $? "PosterView.tsx中包含代码块样式修复"

echo ""
echo "📋 5. API功能修复验证"
echo "=================="
grep -q "verifyPassword" src/pages/api/generatePosterImage.ts
check_result $? "API接口包含密码验证函数"

grep -q "validateDimensions" src/pages/api/generatePosterImage.ts
check_result $? "API接口包含尺寸验证函数"

echo ""
echo "📋 6. Next.js配置优化验证"
echo "======================="
grep -q "output.*standalone" next.config.mjs
check_result $? "next.config.mjs中启用standalone输出模式"

grep -q "optimizeCss.*false" next.config.mjs
check_result $? "next.config.mjs中包含构建优化配置"

echo ""
echo "📋 7. 环境变量和配置验证"
echo "====================="
grep -q "API_PASSWORD" docker-compose.yml
check_result $? "docker-compose.yml中包含API密码配置"

echo ""
echo "🎯 验证结果汇总"
echo "=============="
echo "总检查项: $TOTAL_CHECKS"
echo "通过检查: $PASSED_CHECKS"
echo "失败检查: $((TOTAL_CHECKS - PASSED_CHECKS))"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo ""
    echo "🎉 所有修复已完整集成到源代码中！"
    echo ""
    echo "✅ 可以安全地重新编译Docker镜像，所有修复都会保留："
    echo ""
    echo "🐳 重新编译命令选项:"
    echo "   1. 简单构建:"
    echo "      docker build -t markdown-to-image-serve:latest ."
    echo ""
    echo "   2. 使用构建脚本:"
    echo "      ./build-docker-fixed.sh"
    echo ""
    echo "   3. 使用docker-compose重建:"
    echo "      docker-compose build"
    echo "      docker-compose up -d"
    echo ""
    echo "📋 重新编译后会包含的所有修复:"
    echo "   ✅ MDX依赖自动安装"
    echo "   ✅ npm/yarn官方源配置"
    echo "   ✅ patch-package自动执行"
    echo "   ✅ Chrome路径正确配置"
    echo "   ✅ 表格渲染修复"
    echo "   ✅ 文本截断修复"
    echo "   ✅ API密码验证"
    echo "   ✅ 尺寸自定义功能"
    echo "   ✅ 构建性能优化"
    echo ""
    echo "💡 推荐重新编译流程:"
    echo "   1. 备份当前数据: docker-compose down"
    echo "   2. 重新构建: docker-compose build --no-cache"
    echo "   3. 启动服务: docker-compose up -d"
    echo "   4. 测试功能: ./test-api.sh"
else
    echo ""
    echo "⚠️  发现 $((TOTAL_CHECKS - PASSED_CHECKS)) 个检查未通过"
    echo ""
    echo "建议先修复这些问题，然后再重新编译Docker镜像。"
    echo ""
    echo "或者使用现有的快速修复脚本："
    echo "   ./apply-table-fix-to-docker.sh"
fi

echo ""
echo "📊 详细修复状态报告已保存到: fix-status-report.txt"

# 生成详细报告
{
    echo "Docker镜像重编译修复状态报告"
    echo "生成时间: $(date)"
    echo "=============================="
    echo ""
    echo "检查结果: $PASSED_CHECKS/$TOTAL_CHECKS 通过"
    echo ""
    echo "修复集成状态:"
    echo ""
    
    echo "1. MDX依赖修复:"
    grep -q "@next/mdx" package.json && echo "   ✅ @next/mdx" || echo "   ❌ @next/mdx"
    grep -q "@mdx-js/loader" package.json && echo "   ✅ @mdx-js/loader" || echo "   ❌ @mdx-js/loader"
    grep -q "@mdx-js/react" package.json && echo "   ✅ @mdx-js/react" || echo "   ❌ @mdx-js/react"
    
    echo ""
    echo "2. Docker构建修复:"
    grep -q "NPM_CONFIG_REGISTRY" Dockerfile && echo "   ✅ npm官方源" || echo "   ❌ npm官方源"
    grep -q "YARN_REGISTRY" Dockerfile && echo "   ✅ yarn官方源" || echo "   ❌ yarn官方源"
    grep -q "patch-package" Dockerfile && echo "   ✅ patch-package" || echo "   ❌ patch-package"
    
    echo ""
    echo "3. Chrome路径修复:"
    grep -q "CHROME_PATH=/usr/bin/chromium" docker-compose.yml && echo "   ✅ Chrome路径" || echo "   ❌ Chrome路径"
    
    echo ""
    echo "4. 表格和文本修复:"
    grep -q "max-width: none" src/components/PosterView.tsx && echo "   ✅ CSS覆盖" || echo "   ❌ CSS覆盖"
    grep -q "table-layout: auto" src/components/PosterView.tsx && echo "   ✅ 表格样式" || echo "   ❌ 表格样式"
    grep -q "wordWrap.*break-word" src/components/PosterView.tsx && echo "   ✅ 文本换行" || echo "   ❌ 文本换行"
    
    echo ""
    echo "5. API功能修复:"
    grep -q "verifyPassword" src/pages/api/generatePosterImage.ts && echo "   ✅ 密码验证" || echo "   ❌ 密码验证"
    grep -q "validateDimensions" src/pages/api/generatePosterImage.ts && echo "   ✅ 尺寸验证" || echo "   ❌ 尺寸验证"
    
    echo ""
    if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
        echo "结论: 可以安全重新编译Docker镜像"
        echo ""
        echo "推荐命令:"
        echo "  docker-compose build --no-cache"
        echo "  docker-compose up -d"
    else
        echo "结论: 建议先完成所有修复再重新编译"
    fi
    
} > fix-status-report.txt

echo "✅ 报告完成！"
