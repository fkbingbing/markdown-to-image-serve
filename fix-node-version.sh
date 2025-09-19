#!/bin/bash
# 🔧 Node.js版本修复脚本
# =======================

echo "🔧 Node.js版本修复"
echo "=================="
echo ""

CURRENT_NODE=$(node --version)
echo "📋 当前Node.js版本: $CURRENT_NODE"
echo "✅ 需要版本: >=18.17.0"
echo ""

# 检查是否安装了nvm
if command -v nvm &> /dev/null; then
    echo "✅ 检测到nvm，准备安装Node.js 18"
    
    # 安装和使用Node.js 18
    nvm install 18
    nvm use 18
    
    echo "✅ Node.js已升级到: $(node --version)"
    echo ""
    
elif command -v brew &> /dev/null; then
    echo "✅ 检测到Homebrew，准备安装Node.js 18"
    
    # 使用Homebrew安装Node.js 18
    brew install node@18
    brew link --overwrite node@18
    
    echo "✅ Node.js已升级到: $(node --version)"
    echo ""
    
else
    echo "❌ 未检测到nvm或Homebrew"
    echo ""
    echo "请选择以下方案之一："
    echo ""
    echo "🚀 方案1: 安装nvm（推荐）"
    echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo "   source ~/.bashrc  # 或 source ~/.zshrc"
    echo "   nvm install 18"
    echo "   nvm use 18"
    echo ""
    echo "🍺 方案2: 使用Homebrew"
    echo "   brew install node@18"
    echo "   brew link --overwrite node@18"
    echo ""
    echo "🌐 方案3: 官网下载"
    echo "   访问: https://nodejs.org/"
    echo "   下载并安装Node.js 18.x LTS版本"
    echo ""
    echo "🐳 方案4: 使用Docker（无需升级Node.js）"
    echo "   ./setup-docker-dev.sh"
    
    exit 1
fi

# 验证版本
NEW_VERSION=$(node --version)
MAJOR_VERSION=$(echo $NEW_VERSION | cut -d'.' -f1 | sed 's/v//')

if [ "$MAJOR_VERSION" -ge 18 ]; then
    echo "🎉 Node.js版本验证通过: $NEW_VERSION"
    echo ""
    echo "现在可以继续设置开发环境："
    echo "   ./setup-local-dev.sh"
else
    echo "❌ 版本升级失败，请手动升级Node.js"
    exit 1
fi
