#!/bin/bash
# 文件: verify-fixes-without-docker.sh
# 描述: 不使用Docker的情况下验证修复内容

echo "🔍 验证表格和文本截断修复内容（无Docker模式）"
echo "==========================================="

SERVICE_DIR="/Users/xiangping.liao/Documents/wp/crocodile/markdowntoimage/markdown-to-image-serve"

echo "📋 检查修复文件内容..."
echo ""

# 检查 PosterView.tsx 文件的关键修复内容
POSTER_VIEW_FILE="$SERVICE_DIR/src/components/PosterView.tsx"

if [ -f "$POSTER_VIEW_FILE" ]; then
    echo "✅ PosterView.tsx 文件存在"
    
    # 检查关键修复内容
    echo "🔍 检查关键修复内容:"
    
    if grep -q "max-width: none !important" "$POSTER_VIEW_FILE"; then
        echo "  ✅ CSS覆盖样式: max-width修复已存在"
    else
        echo "  ❌ CSS覆盖样式: max-width修复缺失"
    fi
    
    if grep -q "table-layout: auto !important" "$POSTER_VIEW_FILE"; then
        echo "  ✅ 表格样式: table-layout修复已存在"
    else
        echo "  ❌ 表格样式: table-layout修复缺失"
    fi
    
    if grep -q "white-space: pre-wrap !important" "$POSTER_VIEW_FILE"; then
        echo "  ✅ 代码块样式: white-space修复已存在"
    else
        echo "  ❌ 代码块样式: white-space修复缺失"
    fi
    
    if grep -q "wordWrap: 'break-word'" "$POSTER_VIEW_FILE"; then
        echo "  ✅ 容器样式: wordWrap修复已存在"
    else
        echo "  ❌ 容器样式: wordWrap修复缺失"
    fi
    
else
    echo "❌ PosterView.tsx 文件不存在: $POSTER_VIEW_FILE"
fi

echo ""
echo "📋 关键修复代码预览:"
echo ""

# 显示关键修复代码段
echo "🎨 CSS覆盖样式修复:"
echo "------------------------"
grep -A 10 -B 2 "max-width: none !important" "$POSTER_VIEW_FILE" || echo "未找到CSS覆盖修复"

echo ""
echo "📊 表格样式修复:"
echo "------------------------"
grep -A 5 -B 2 "table-layout: auto" "$POSTER_VIEW_FILE" || echo "未找到表格样式修复"

echo ""
echo "📝 容器样式修复:"
echo "------------------------"
grep -A 3 -B 2 "wordWrap.*break-word" "$POSTER_VIEW_FILE" || echo "未找到容器样式修复"

echo ""
echo "🎯 修复文件完整性检查:"
echo "====================="

# 统计修复相关的行数
TOTAL_LINES=$(wc -l < "$POSTER_VIEW_FILE")
CSS_FIXES=$(grep -c "!important" "$POSTER_VIEW_FILE" 2>/dev/null || echo "0")
WORD_WRAP_FIXES=$(grep -c "word-wrap\|wordWrap\|overflowWrap" "$POSTER_VIEW_FILE" 2>/dev/null || echo "0")

echo "📄 总行数: $TOTAL_LINES"
echo "🎨 CSS修复数量: $CSS_FIXES 个 !important 规则"
echo "📝 文本换行修复: $WORD_WRAP_FIXES 个换行设置"

if [ "$CSS_FIXES" -gt 10 ] && [ "$WORD_WRAP_FIXES" -gt 3 ]; then
    echo "✅ 修复内容完整，可以应用到Docker"
else
    echo "⚠️  修复内容可能不完整，请检查文件"
fi

echo ""
echo "🐳 Docker应用选项:"
echo "=================="
echo "1. 启动Docker并应用修复:"
echo "   ./start-docker-and-apply-fix.sh"
echo ""
echo "2. 手动应用修复到运行中的Docker:"
echo "   ./apply-table-fix-to-docker.sh"
echo ""
echo "3. 使用docker-compose重建服务:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""

# 生成修复确认报告
REPORT_FILE="$SERVICE_DIR/fix-verification-report.txt"
echo "📊 生成修复验证报告: $REPORT_FILE"

{
    echo "表格和文本截断修复验证报告"
    echo "生成时间: $(date)"
    echo "=============================="
    echo ""
    echo "文件路径: $POSTER_VIEW_FILE"
    echo "文件大小: $(stat -f%z "$POSTER_VIEW_FILE" 2>/dev/null || stat -c%s "$POSTER_VIEW_FILE" 2>/dev/null) 字节"
    echo "总行数: $TOTAL_LINES"
    echo "CSS修复数量: $CSS_FIXES"
    echo "文本换行修复: $WORD_WRAP_FIXES"
    echo ""
    echo "修复检查结果:"
    if grep -q "max-width: none !important" "$POSTER_VIEW_FILE"; then
        echo "✅ CSS覆盖样式修复"
    else
        echo "❌ CSS覆盖样式修复缺失"
    fi
    
    if grep -q "table-layout: auto !important" "$POSTER_VIEW_FILE"; then
        echo "✅ 表格样式修复"
    else
        echo "❌ 表格样式修复缺失"
    fi
    
    if grep -q "wordWrap: 'break-word'" "$POSTER_VIEW_FILE"; then
        echo "✅ 容器样式修复"
    else
        echo "❌ 容器样式修复缺失"
    fi
    
    echo ""
    echo "建议的下一步操作:"
    echo "1. 启动Docker: ./start-docker-and-apply-fix.sh"
    echo "2. 测试API: ./test-api.sh"
    echo "3. 验证表格显示效果"
} > "$REPORT_FILE"

echo "✅ 报告已保存到: $REPORT_FILE"
