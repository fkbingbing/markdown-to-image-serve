# 🚀 Docker容器修复指南（无需重新编译镜像）

## 📋 可用的修复方案

我为你准备了3种不同的方案来应用修复，选择最适合你的情况：

---

## 🎯 **方案1: 重启容器应用修复（推荐）**

**文件**: `apply-fixes-to-docker.sh`

**适用场景**: 
- ✅ 可以接受短暂服务中断（约30秒）
- ✅ 需要确保修复完全生效
- ✅ 第一次应用修复

**优势**: 
- 🔒 最稳定可靠
- 🧪 包含自动测试验证
- 📊 提供详细状态报告

**使用方法**:
```bash
cd /path/to/markdown-to-image-serve
./apply-fixes-to-docker.sh
```

---

## 🔥 **方案2: 热修复运行中容器（零停机）**

**文件**: `hotfix-running-container.sh`

**适用场景**:
- ✅ 不能停止正在运行的服务
- ✅ 需要零停机时间
- ✅ 快速应用紧急修复

**优势**:
- ⚡ 零停机时间
- 🔄 支持热重载
- 💾 自动备份原文件

**使用方法**:
```bash
cd /path/to/markdown-to-image-serve  
./hotfix-running-container.sh
```

---

## 📦 **方案3: Docker Compose管理（长期运行）**

**文件**: `docker-compose-with-fixes.yml`

**适用场景**:
- ✅ 需要长期稳定运行
- ✅ 希望配置化管理
- ✅ 团队环境或生产环境

**优势**:
- 🛠️ 配置化管理
- 🔄 容易重启和更新
- 📂 完整的文件挂载

**使用方法**:
```bash
cd /path/to/markdown-to-image-serve
docker-compose -f docker-compose-with-fixes.yml up -d
```

---

## 🔧 **修复内容说明**

所有方案都包含以下关键修复：

### ✅ **PosterView.tsx内容尺寸修复**
```typescript
// 根据宽度动态设置尺寸
const posterSize = posterWidth >= 1000 ? 'desktop' : posterWidth >= 700 ? 'tablet' : 'mobile';
<Md2Poster theme={theme as IThemeType} size={posterSize as any}>
```

### ✅ **Chrome路径修复**
```bash
CHROME_PATH=/usr/bin/chromium  # 从 /usr/bin/google-chrome-unstable 修复
```

### ✅ **环境变量优化**
```bash
NODE_ENV=production
API_PASSWORD=123456
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

---

## 🚀 **快速开始推荐流程**

### 如果你是第一次应用修复：
```bash
cd /Users/xiangping.liao/Documents/wp/crocodile/markdowntoimage/markdown-to-image-serve
./apply-fixes-to-docker.sh
```

### 如果容器已在运行且不能停止：
```bash
./hotfix-running-container.sh
```

### 如果需要长期稳定运行：
```bash
docker-compose -f docker-compose-with-fixes.yml up -d
```

---

## 🧪 **验证修复效果**

修复应用后，可以通过以下方式验证：

### 1. 访问服务
```bash
curl http://localhost:3000
```

### 2. 测试API
```bash
curl -X POST http://localhost:3000/api/generatePosterImage \
  -H "Content-Type: application/json" \
  -d '{
    "markdown": "# 🖥️ 桌面版测试\n\n字体应该较大",
    "width": 1200, "height": 800, "password": "123456"
  }'
```

### 3. 对比测试
生成400px(手机版)和1200px(桌面版)的图片，对比字体大小差异

---

## 📊 **预期效果**

修复成功后，你应该看到：

| 设备类型 | 图片宽度 | PosterView尺寸 | 字体效果 |
|---------|----------|--------------|----------|
| 🖥️ 桌面版 | ≥1000px | `desktop` | 字体最大 |
| 📊 平板版 | 700-999px | `tablet` | 字体中等 |
| 📱 手机版 | <700px | `mobile` | 字体最小 |

---

## 🆘 **故障排除**

如果修复未生效：

1. **检查容器状态**: `docker ps`
2. **查看容器日志**: `docker logs <container_id>`
3. **重启容器**: `docker restart <container_id>`
4. **恢复备份**: 脚本会提供恢复命令

---

## 💡 **选择建议**

- **🏃‍♂️ 快速修复**: 选择方案1 (`apply-fixes-to-docker.sh`)
- **🔥 零停机**: 选择方案2 (`hotfix-running-container.sh`) 
- **🏢 生产环境**: 选择方案3 (Docker Compose)

**所有方案都无需重新编译镜像，几分钟内即可完成！**
