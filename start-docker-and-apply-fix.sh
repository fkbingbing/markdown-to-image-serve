#!/bin/bash
# 文件: start-docker-and-apply-fix.sh
# 描述: 启动Docker并应用表格修复的完整方案

echo "🐳 启动Docker并应用表格修复"
echo "============================="

# 检查是否是macOS并尝试启动Docker Desktop
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 检测到macOS系统"
    
    # 检查Docker Desktop是否已安装
    if [ -d "/Applications/Docker.app" ]; then
        echo "📱 发现Docker Desktop应用"
        
        # 检查Docker是否已经运行
        if ! docker info > /dev/null 2>&1; then
            echo "🚀 正在启动Docker Desktop..."
            open -a Docker
            
            echo "⏳ 等待Docker Desktop启动..."
            # 等待Docker启动（最多等待60秒）
            for i in {1..12}; do
                if docker info > /dev/null 2>&1; then
                    echo "✅ Docker已启动"
                    break
                fi
                echo "   等待中... ($i/12)"
                sleep 5
            done
            
            # 最后检查一次
            if ! docker info > /dev/null 2>&1; then
                echo "❌ Docker启动超时或失败"
                echo "请手动启动Docker Desktop，然后运行:"
                echo "   ./apply-table-fix-to-docker.sh"
                exit 1
            fi
        else
            echo "✅ Docker已运行"
        fi
    else
        echo "❌ 未找到Docker Desktop应用"
        echo "请先安装Docker Desktop:"
        echo "   https://www.docker.com/products/docker-desktop"
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 检测到Linux系统"
    
    # 尝试启动Docker服务
    if command -v systemctl >/dev/null 2>&1; then
        echo "🔧 尝试启动Docker服务..."
        sudo systemctl start docker
        sleep 3
    elif command -v service >/dev/null 2>&1; then
        echo "🔧 尝试启动Docker服务..."
        sudo service docker start
        sleep 3
    fi
    
    # 检查是否成功
    if ! docker info > /dev/null 2>&1; then
        echo "❌ 无法启动Docker服务"
        echo "请手动启动Docker，然后运行:"
        echo "   ./apply-table-fix-to-docker.sh"
        exit 1
    fi
else
    echo "❓ 未知系统类型: $OSTYPE"
    echo "请手动启动Docker，然后运行:"
    echo "   ./apply-table-fix-to-docker.sh"
    exit 1
fi

echo ""
echo "🎯 Docker已准备就绪，开始应用修复..."
echo ""

# 运行修复脚本
./apply-table-fix-to-docker.sh
