'use client';
import React from 'react'
import { Md2PosterContent, Md2Poster, Md2PosterHeader, Md2PosterFooter } from 'markdown-to-poster'
import { useSearchParams } from 'next/navigation';
import Image from 'next/image'

type IThemeType = 'blue' | 'pink' | 'purple' | 'green' | 'yellow' | 'gray' | 'red' | 'indigo' | 'SpringGradientWave';


const defaultContentMd = `# AI的发展


人工智能(AI)正在以前所未有的速度发展，深刻改变着我们的生活方式。从ChatGPT到DALL-E，从自动驾驶到智能医疗，AI技术正在各个领域展现其强大潜力。

## 主要突破
1. **大语言模型**: GPT系列模型带来了自然语言处理的重大突破
2. **计算机视觉**: 在图像识别和生成领域取得显著进展
3. **智能决策**: 在游戏和复杂决策系统中超越人类表现

## 未来展望
- 更强大的多模态模型
- AI与各行业深度融合
- 负责任的AI发展和伦理规范

![AI发展](https://images.unsplash.com/photo-1677442136019-21780ecad995)
`

export default function PosterView() {
  // 需要根据url参数，作为mdString 的默认值
  const searchParams = useSearchParams()

  function safeDecodeURIComponent(val: string | null | undefined, fallback: string) {
    if (typeof val !== 'string') return fallback;
    try {
      // 防止重复 decode
      return decodeURIComponent(val);
    } catch {
      return val;
    }
  }

  const mdString = safeDecodeURIComponent(searchParams?.get('content'), defaultContentMd);
  const headerString = safeDecodeURIComponent(searchParams?.get('header'), '');
  const footerString = safeDecodeURIComponent(searchParams?.get('footer'), 'Powered by markdown-to-image-serve.jcommon.top')
  const logo = ('/logo.png')
  const logoString = safeDecodeURIComponent(searchParams?.get('logo'), logo);
  const theme = safeDecodeURIComponent(searchParams?.get('theme'), 'SpringGradientWave');
  
  // 获取自定义宽度和高度参数
  const customWidth = searchParams?.get('width');
  const customHeight = searchParams?.get('height');
  
  // 解析和验证尺寸参数
  function parseDimension(value: string | null | undefined, defaultValue: number, min: number, max: number): number {
    if (!value) return defaultValue;
    const parsed = parseInt(value, 10);
    if (isNaN(parsed)) return defaultValue;
    return Math.max(min, Math.min(max, parsed));
  }
  
  const posterWidth = parseDimension(customWidth, 800, 400, 2000);
  const posterHeight = parseDimension(customHeight, 600, 300, 1500);
  
  // 根据宽度判断应该使用的尺寸
  const posterSize = posterWidth >= 1000 ? 'desktop' : posterWidth >= 700 ? 'tablet' : 'mobile';
  
  // 动态计算样式
  const containerStyle = {
    display: "inline-block" as const,
    width: posterWidth + 'px',
    minHeight: posterHeight + 'px',
    position: 'relative' as const,
    // 移除maxWidth限制，避免文本截断
    wordWrap: 'break-word' as const,
    overflowWrap: 'break-word' as const,
  };

  return (
    <div className="poster-content" style={containerStyle}>
      {/* 强制覆盖 Md2Poster 组件的宽度限制 */}
      <style dangerouslySetInnerHTML={{
        __html: `
          .poster-content .md2-poster,
          .poster-content .md2-poster > div,
          .poster-content .md2-poster-content,
          .poster-content [class*="poster"] {
            max-width: none !important;
            width: ${posterWidth}px !important;
            box-sizing: border-box !important;
          }
          .poster-content .md2-poster-content > div,
          .poster-content .md2-poster-content * {
            max-width: none !important;
            word-wrap: break-word !important;
            overflow-wrap: break-word !important;
          }
          /* 修复代码块宽度限制 - 这是关键修复 */
          .poster-content pre,
          .poster-content code,
          .poster-content .hljs,
          .poster-content [class*="code"],
          .poster-content [class*="highlight"] {
            max-width: none !important;
            width: 100% !important;
            white-space: pre-wrap !important;
            word-wrap: break-word !important;
            overflow-wrap: break-word !important;
            overflow-x: visible !important;
          }
          /* 修复表格宽度和样式 */
          .poster-content table {
            width: 100% !important;
            max-width: none !important;
            table-layout: auto !important;
            border-collapse: collapse !important;
          }
          .poster-content th,
          .poster-content td {
            max-width: none !important;
            word-wrap: break-word !important;
            overflow-wrap: break-word !important;
            white-space: normal !important;
            padding: 8px !important;
            border: 1px solid #ddd !important;
          }
        `
      }} />
          {/* Preview */}
            <Md2Poster theme={theme as IThemeType} size={posterSize as any}>
              <Md2PosterHeader  className="flex justify-center items-center px-4 font-medium text-lg">
                <span>{headerString || new Date().toISOString().slice(0, 10)} </span>
              </Md2PosterHeader>
              <Md2PosterContent>{mdString}</Md2PosterContent>
              <Md2PosterFooter className='text-center'>
                <Image src={logoString} alt="logo" width={20} height={20} className='inline-block mr-2' />
                {footerString}
              </Md2PosterFooter>
            </Md2Poster>
    </div>
  )
}
