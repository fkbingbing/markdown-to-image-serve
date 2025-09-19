# 只读文件系统错误修复

## 🚨 问题描述

```
error Error: EROFS: read-only file system, open '/app/package.json'
```

**问题原因**: 挂载的 `package.json` 文件设置为只读 (`:ro`)，但 `yarn add` 需要修改这个文件。

## 🔧 修复方案

### 已修复的配置

1. **docker-compose.yml** ✅ - 移除了 package.json 只读挂载
2. **docker-run.sh** ✅ - 移除了 package.json 挂载
3. **test-mdx-fix.sh** ✅ - 移除了 package.json 挂载

### 修复逻辑

```yaml
# ❌ 修复前 - 导致只读错误
volumes:
  - ./package.json:/app/package.json:ro

# ✅ 修复后 - 不挂载，使用容器内的文件
volumes:
  # package.json 挂载已移除
```

## 🎯 新的工作流程

### 1. 容器启动流程
1. **使用容器内置的 package.json**
2. **运行依赖检查脚本** (`fix-deps.sh`)
3. **自动安装缺失的 MDX 依赖**
4. **正常启动 Next.js 服务**

### 2. 依赖修复过程
```bash
🔧 检查和修复依赖...
❌ 缺失依赖: @next/mdx
❌ 缺失依赖: @mdx-js/loader
❌ 缺失依赖: @mdx-js/react
❌ 缺失依赖: @types/mdx

📦 安装缺失的依赖...
🌐 使用官方npm源: https://registry.npmjs.org/
✅ 依赖安装完成

🔍 最终验证依赖可用性...
✅ @next/mdx 可以正常加载

🚀 启动 Next.js 服务...
```

## 🚀 立即使用

### 重新启动服务

#### 方式1: docker-compose
```bash
# 停止当前服务
docker-compose down

# 重新启动 (使用修复后的配置)
docker-compose up -d

# 查看修复过程
docker-compose logs -f app
```

#### 方式2: 启动脚本
```bash
# 停止当前容器 (Ctrl+C)
# 重新运行
./docker-run.sh
# 选择 "1" 前台启动
```

#### 方式3: 测试脚本
```bash
# 快速测试修复效果
./test-mdx-fix.sh
```

## 📋 预期结果

### ✅ 成功启动
```bash
🔧 检查和修复依赖...
❌ 缺失依赖: @next/mdx
📦 安装缺失的依赖: @next/mdx@^14.2.3 @mdx-js/loader@^3.0.1 @mdx-js/react@^3.0.1 @types/mdx@^2.0.13
🌐 使用官方npm源: https://registry.npmjs.org/
✅ 依赖安装完成
🔍 最终验证依赖可用性...
✅ @next/mdx 可以正常加载
🚀 启动 Next.js 服务...

  ▲ Next.js 14.2.3
  - Local:        http://localhost:3000
  ✓ Ready in 2134ms
```

### ❌ 如果仍有问题
如果仍然遇到问题，请检查：

1. **文件权限**
   ```bash
   # 确保脚本可执行
   chmod +x fix-deps.sh
   ```

2. **容器权限**
   ```bash
   # 检查容器是否有写权限
   docker run --rm markdown-to-image-serve:latest ls -la /app
   ```

3. **手动验证**
   ```bash
   # 手动进入容器测试
   docker run --rm -it markdown-to-image-serve:latest /bin/bash
   cd /app
   yarn add @next/mdx@^14.2.3
   ```

## 🎉 优势

✅ **不再有只读文件系统错误**  
✅ **依赖可以正常安装**  
✅ **不需要修改主机上的 package.json**  
✅ **容器内的修改不会影响主机**  
✅ **每次启动都确保依赖完整**  

## 📊 总结

| 问题 | 修复前 | 修复后 |
|------|-------|-------|
| **文件权限** | ❌ 只读挂载 | ✅ 容器内可写 |
| **依赖安装** | ❌ EROFS 错误 | ✅ 正常安装 |
| **服务启动** | ❌ 失败 | ✅ 成功 |
| **配置复杂度** | ❌ 需要挂载 | ✅ 自动处理 |

**现在重新启动服务应该完全正常了！** 🚀
