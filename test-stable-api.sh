#!/bin/bash
# 🎯 稳定测试长内容API
set -e

echo "🎯 稳定测试长内容API"
echo "===================="
echo ""

# 测试简化版本
echo "📝 测试1: 简化版本..."
response1=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
        "markdown": "# 🎯 性能分析报告\n\n## 用户: vinhhien.nguyen@foody.vn\n\n### 关键指标\n- 内存峰值: 775MB\n- CPU峰值: 11.76%\n- 文件大小: 10MB~32MB\n- 处理时间: 最长191秒\n\n### 主要问题\n1. 内存多次超过500MB\n2. 大文件处理耗时过长\n3. 需要优化处理流程\n\n**建议**: 优化大文件处理，关注内存释放",
         "header": "🔍 性能分析报告",
         "footer": "简化版本测试",
         "theme": "SpringGradientWave",
        "width": 1000,
        "height": 700,
         "password": "123456"
       }')

if echo "$response1" | grep -q "url"; then
    echo "✅ 简化版本测试成功"
    echo "📋 响应: $(echo "$response1" | python3 -c 'import sys,json; print(json.load(sys.stdin)["url"])' 2>/dev/null)"
else
    echo "❌ 简化版本测试失败"
    echo "📋 响应: $response1"
fi

echo ""

# 测试中等长度版本
echo "📝 测试2: 中等长度版本..."
response2=$(curl -s -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
        "markdown": "# 用户 vinhhien.nguyen@foody.vn 过去24小时性能分析\n\n---\n\n## 1. 汇总分析问题原因\n\n- **内存与CPU使用情况**：用户主程序内存多次超过500MB，最高达到775MB，CPU峰值约11.76%，大部分时间CPU低于20%，但偶有高峰。\n- **大文件提取与解压**：存在多次大文件提取和解压操作，部分操作耗时超过100秒，单次最大提取时间达191秒，涉及文件均为较大Excel文件（10MB~32MB）。\n- **文件操作行为**：未发现文件行为数据量异常（未超过10万条），文件操作行为未对性能造成显著影响。\n\n---\n\n## 2. 内存和CPU详细数据\n\n| 时间                | 版本      | 主程序内存(MB) | 主程序CPU(%) |\n|:--------------------|:----------|:--------------|:-------------|\n| 2025-09-19 15:22:15 | 1.12.61   | 775           | 0.86         |\n| 2025-09-19 15:21:55 | 1.12.61   | 773           | 1.33         |\n| 2025-09-19 15:21:35 | 1.12.61   | 736           | 0.96         |\n| 2025-09-19 15:21:15 | 1.12.61   | 738           | 0.76         |\n| 2025-09-19 15:20:55 | 1.12.61   | 742           | 1.10         |\n\n---\n\n## 3. 结论与建议\n\n- 用户近期多次进行大文件（10MB~32MB）提取操作，单次提取时间长达190秒，导致主程序内存多次超过500MB，最高达775MB。\n- CPU整体负载较低，未见明显异常，但大文件操作时偶有瞬时高峰。\n- 建议优化大文件处理流程，关注内存释放，避免长时间高内存占用。",
         "header": "🔍 性能分析报告",
         "footer": "报告生成时间: 2025-09-19 18:35:51 | 用户: vinhhien.nguyen@foody.vn",
         "theme": "SpringGradientWave",
        "width": 1200,
        "height": 800,
         "password": "123456"
       }')

if echo "$response2" | grep -q "url"; then
    echo "✅ 中等长度版本测试成功"
    echo "📋 响应: $(echo "$response2" | python3 -c 'import sys,json; print(json.load(sys.stdin)["url"])' 2>/dev/null)"
else
    echo "❌ 中等长度版本测试失败"
    echo "📋 响应: $response2"
fi

echo ""
echo "🎉 稳定测试完成！"
echo ""
echo "💡 建议:"
echo "  - 对于超长内容，建议分段处理"
echo "  - 使用合理的图片尺寸 (1000x700 或 1200x800)"
echo "  - 避免过大的表格和复杂格式"
