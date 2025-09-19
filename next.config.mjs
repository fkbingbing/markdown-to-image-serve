/** @type {import('next').NextConfig} */
import createMDX from '@next/mdx'

const nextConfig = {
  // Configure `pageExtensions` to include markdown and MDX files
  pageExtensions: ['js', 'jsx', 'md', 'mdx', 'ts', 'tsx'],
  
  // 启用 standalone 输出模式以支持多阶段Docker构建
  output: 'standalone',
  
  // 实验性功能配置
  experimental: {
    // 优化构建性能
    optimizeCss: false,
    // 减少内存使用
    workerThreads: false,
  },
  
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: '**',
      },
    ],
  },
  
  // 构建优化
  typescript: {
    // 在构建时忽略 TypeScript 错误（可选）
    ignoreBuildErrors: false,
  },
  
  // Webpack 配置优化
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    // 优化内存使用
    if (!dev) {
      config.optimization.minimize = true;
      config.optimization.sideEffects = false;
    }
    
    return config;
  },
};

const withMDX = createMDX({
  // Add markdown plugins here, as desired
  extension: /\.mdx?$/,
  options: {
    remarkPlugins: [],
    rehypePlugins: [],
  },
})

export default withMDX(nextConfig)
