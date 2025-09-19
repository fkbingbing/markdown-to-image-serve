# Docker 构建故障排除指南

## 🚨 常见构建问题及解决方案

### 问题1: `npm ci` 失败
```
The command '/bin/sh -c npm ci --silent' returned a non-zero exit code: 1
```

**原因**: 项目使用 yarn 而不是 npm，缺少 package-lock.json 文件

**解决方案**:
```bash
# 使用修复版本的 Dockerfile
./build-docker-fixed.sh

# 或者手动使用 yarn 版本的 Dockerfile
docker build -f Dockerfile -t your-image:tag .
```

### 问题2: Next.js 构建卡死
```
Creating an optimized production build ... 卡住不动
```

**原因**: 
- 内存不足
- Next.js 缓存问题
- 网络连接问题

**解决方案**:
```bash
# 方案1: 增加Docker内存限制
docker build --memory 4g -t your-image:tag .

# 方案2: 使用多阶段构建
docker build -f Dockerfile.optimized -t your-image:tag .

# 方案3: 清理Docker缓存
docker system prune -f
docker build --no-cache -t your-image:tag .
```

### 问题3: 内存不足 (OOM)
```
JavaScript heap out of memory
```

**解决方案**:
- 已在 Dockerfile 中增加内存配置: `NODE_OPTIONS="--max-old-space-size=6144"`
- 如果仍然不足，可以进一步增加到 8192

### 问题4: 网络超时
```
Error: connect ETIMEDOUT
```

**解决方案**:
```bash
# 设置镜像源
docker build --build-arg YARN_REGISTRY=https://registry.npmmirror.com -t your-image:tag .

# 或者在 Dockerfile 中添加：
ENV YARN_REGISTRY=https://registry.npmmirror.com
```

## 🛠️ 构建选项对比

### 标准构建 (`Dockerfile`)
- **优点**: 稳定可靠，支持所有功能
- **缺点**: 镜像较大 (~1.5GB)
- **适用**: 生产环境推荐

### 多阶段构建 (`Dockerfile.optimized`)
- **优点**: 镜像小 (~500MB)，生产优化
- **缺点**: 构建时间长，复杂度高
- **适用**: 对镜像大小敏感的环境

### 简单构建 (脚本生成)
- **优点**: 兼容性最好，构建快
- **缺点**: 未优化，镜像大
- **适用**: 开发测试环境

## 🔧 构建命令参考

### 基础构建
```bash
# 使用标准 Dockerfile
docker build -t markdown-to-image-serve:latest .

# 使用优化版本
docker build -f Dockerfile.optimized -t markdown-to-image-serve:optimized .

# 使用构建脚本 (推荐)
./build-docker-fixed.sh
```

### 高级构建选项
```bash
# 无缓存构建
docker build --no-cache -t your-image:tag .

# 指定平台
docker build --platform linux/amd64 -t your-image:tag .

# 设置内存限制
docker build --memory 4g -t your-image:tag .

# 构建时设置变量
docker build --build-arg API_PASSWORD=secret -t your-image:tag .
```

## 🏃‍♂️ 快速启动

### 运行容器
```bash
# 基础运行
docker run -d -p 3000:3000 \
  -e API_PASSWORD=your_password \
  markdown-to-image-serve:latest

# 完整配置
docker run -d -p 3000:3000 \
  -e API_PASSWORD=your_secure_password \
  -e NEXT_PUBLIC_BASE_URL=http://localhost:3000 \
  -e CHROME_PATH=/usr/bin/google-chrome-unstable \
  --name markdown-service \
  markdown-to-image-serve:latest
```

### 使用 Docker Compose
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    image: markdown-to-image-serve:latest
    ports:
      - "3000:3000"
    environment:
      - API_PASSWORD=your_secure_password
      - NODE_ENV=production
    volumes:
      - ./uploads:/app/public/uploads
```

## 🔍 调试技巧

### 查看构建过程
```bash
# 详细构建日志
docker build --progress=plain -t your-image:tag .

# 构建特定阶段 (多阶段构建)
docker build --target=builder -t debug-image:tag .
```

### 进入容器调试
```bash
# 进入运行中的容器
docker exec -it <container_id> /bin/bash

# 运行临时容器进行调试
docker run -it --rm markdown-to-image-serve:latest /bin/bash
```

### 查看日志
```bash
# 查看容器日志
docker logs <container_id>

# 实时跟踪日志
docker logs -f <container_id>

# 查看构建历史
docker history markdown-to-image-serve:latest
```

## 📊 性能优化建议

### 构建优化
1. **使用多阶段构建** - 减少最终镜像大小
2. **合理设置缓存** - 加速重复构建
3. **并行构建** - 使用 BuildKit 引擎

### 运行时优化
1. **内存限制** - 设置合适的内存限制
2. **健康检查** - 添加容器健康检查
3. **日志管理** - 配置日志轮转

### 生产部署
```bash
# 生产环境运行配置
docker run -d \
  --name markdown-service \
  --restart unless-stopped \
  --memory 2g \
  --cpus 2 \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e API_PASSWORD="${API_PASSWORD}" \
  --health-cmd="curl -f http://localhost:3000/api/hello || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  markdown-to-image-serve:latest
```

## 🆘 获取帮助

如果遇到其他问题：

1. **检查系统要求**
   - Docker 版本 >= 20.10
   - 可用内存 >= 4GB
   - 可用磁盘空间 >= 5GB

2. **查看详细日志**
   ```bash
   docker build --progress=plain --no-cache . 2>&1 | tee build.log
   ```

3. **清理环境重试**
   ```bash
   docker system prune -a -f
   docker volume prune -f
   ./build-docker-fixed.sh
   ```

4. **社区支持**
   - GitHub Issues
   - 项目文档
   - Docker 社区论坛
