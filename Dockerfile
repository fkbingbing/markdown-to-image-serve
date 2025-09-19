# 文件：Dockerfile
FROM wxingheng/node-chrome-base:latest


# Yarn 配置优化
ENV YARN_REGISTRY=https://registry.npmjs.org/
ENV YARN_CACHE_FOLDER=/yarn-cache
ENV YARN_NETWORK_TIMEOUT=300000

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


# 安装 yarn 包管理器
RUN npm install -g yarn


# 创建yarn缓存目录并安装依赖
RUN mkdir -p $YARN_CACHE_FOLDER && \
    yarn config set cache-folder $YARN_CACHE_FOLDER && \
    yarn install --frozen-lockfile --silent --non-interactive

# 复制应用代码
COPY . .

# 添加构建超时和错误处理
RUN timeout 600 yarn build || \
    (echo "Build timeout or failed, trying with reduced parallelism..." && \
     NODE_OPTIONS="--max-old-space-size=6144" yarn build --verbose)

# 清理不必要的文件并保留生产依赖
RUN rm -rf node_modules/.cache && \
    rm -rf .next/cache && \
    yarn install --production --frozen-lockfile --silent

EXPOSE 3000

# 使用Next.js生产启动方式
CMD ["yarn", "start"]