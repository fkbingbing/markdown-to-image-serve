# 文件：Dockerfile
FROM wxingheng/node-chrome-base:latest

ENV NPM_CONFIG_REGISTRY=https://registry.npmjs.org/
ENV NPM_CONFIG_STRICT_SSL=true
ENV NPM_CONFIG_FETCH_RETRIES=10
ENV NPM_CONFIG_FETCH_RETRY_FACTOR=3
ENV NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=30000
ENV NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=120000
ENV NPM_CONFIG_TIMEOUT=600000
# Yarn 配置优化 - 强制使用官方源
ENV YARN_REGISTRY=https://registry.npmjs.org/
ENV YARN_CACHE_FOLDER=/yarn-cache
ENV YARN_NETWORK_TIMEOUT=300000
ENV NPM_CONFIG_REGISTRY=https://registry.npmjs.org/

# Next.js 构建优化配置
ENV NODE_OPTIONS="--max-old-space-size=6144 --max-semi-space-size=1024"
ENV GENERATE_SOURCEMAP=false
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# 禁用Next.js的一些占用资源的功能
ENV NEXT_DISABLE_BUNDLE_ANALYZER=true
ENV NEXT_DISABLE_PWA=true

# 设置工作目录
WORKDIR /app




# 复制 package.json 和 yarn.lock
COPY package.json yarn.lock ./


# 强力修复：清除配置文件，重置配置，立即安装依赖（在同一RUN命令中）
RUN yarn --version && \
    echo "=== 清除前检查 ===" && \
    ls -la /root/.npmrc /usr/local/share/.yarnrc 2>/dev/null || echo "No config files" && \
    echo "=== 开始清除配置文件 ===" && \
    rm -f /root/.npmrc /usr/local/share/.yarnrc /usr/local/etc/npmrc /usr/local/etc/yarnrc && \
    rm -f /app/.npmrc /app/.yarnrc && \
    echo "=== 重置npm和yarn配置 ===" && \
    npm config set registry https://registry.npmjs.org/ && \
    yarn config set registry https://registry.npmjs.org/ && \
    echo "=== 验证配置 ===" && \
    npm config get registry && \
    yarn config get registry && \
    yarn config list | grep registry && \
    echo "=== 开始安装依赖（包括开发依赖）===" && \
    yarn install --frozen-lockfile --production=false --registry https://registry.npmjs.org/ --verbose && \
    echo "=== 验证 patch-package 可用性 ===" && \
    (yarn list patch-package || echo "patch-package not found, installing globally...") && \
    (command -v patch-package >/dev/null || yarn global add patch-package@8.0.0 --registry https://registry.npmjs.org/) && \
    echo "patch-package version: $(yarn patch-package --version 2>/dev/null || echo 'using global')"

# 复制应用代码
COPY . .

# 添加构建超时和错误处理
RUN timeout 600 yarn build --verbose || \
    (echo "Build timeout or failed, trying with reduced parallelism..." && \
     NODE_OPTIONS="--max-old-space-size=6144" yarn build --verbose)

# 清理不必要的文件并保留生产依赖
RUN rm -rf node_modules/.cache && \
    rm -rf .next/cache && \
    yarn install --production --frozen-lockfile --registry https://registry.npmjs.org/ --verbose

EXPOSE 3000

# 使用Next.js生产启动方式
CMD ["yarn", "start"]