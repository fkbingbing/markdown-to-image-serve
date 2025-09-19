/*
 * @Author: wxingheng
 * @Date: 2024-11-28 14:20:13
 * @LastEditTime: 2025-07-09 17:53:09
 * @LastEditors: wxingheng
 * @Description: 生成海报; 返回海报图片 url
 * @FilePath: /markdown-to-image-serve/src/pages/api/generatePosterImage.ts
 */
import { NextApiRequest, NextApiResponse } from "next";
// import puppeteer from "puppeteer";
import path from "path";
import fs from "fs";
const chromium = require('@sparticuz/chromium-min');
const puppeteer = require('puppeteer-core');

function buildPosterUrl(base: string, params: Record<string, any>) {
  const query = Object.entries(params)
    .filter(([_, v]) => v !== undefined && v !== null && v !== '')
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
  return `${base}${query ? '?' + query : ''}`;
}

// 密码校验函数
function verifyPassword(password: string): boolean {
  const API_PASSWORD = process.env.API_PASSWORD;
  
  // 如果没有设置密码，则跳过验证（向后兼容）
  if (!API_PASSWORD) {
    return true;
  }
  
  return password === API_PASSWORD;
}

// 验证和解析宽度参数
function validateDimensions(width?: any, height?: any): { width: number; height: number } {
  const defaultWidth = 1200;
  const defaultHeight = 800;
  const minWidth = 400;
  const maxWidth = 3840;
  const minHeight = 300; 
  const maxHeight = 2160;

  let validatedWidth = defaultWidth;
  let validatedHeight = defaultHeight;

  // 验证宽度
  if (width !== undefined && width !== null) {
    const parsedWidth = parseInt(width, 10);
    if (!isNaN(parsedWidth) && parsedWidth >= minWidth && parsedWidth <= maxWidth) {
      validatedWidth = parsedWidth;
    }
  }

  // 验证高度
  if (height !== undefined && height !== null) {
    const parsedHeight = parseInt(height, 10);
    if (!isNaN(parsedHeight) && parsedHeight >= minHeight && parsedHeight <= maxHeight) {
      validatedHeight = parsedHeight;
    }
  }

  return { width: validatedWidth, height: validatedHeight };
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "只支持 POST 请求" });
  }

  try {
    const { 
      markdown, 
      header, 
      footer, 
      logo, 
      theme,
      width,
      height,
      password
    } = req.body;

    // 密码校验
    if (!verifyPassword(password)) {
      return res.status(401).json({ 
        error: "认证失败",
        message: "请提供正确的API密码" 
      });
    }

    // 验证输入参数
    if (!markdown) {
      return res.status(400).json({ 
        error: "参数错误",
        message: "markdown 参数是必需的" 
      });
    }

    // 验证和设置尺寸
    const dimensions = validateDimensions(width, height);

    // 启动浏览器
    // const browser = await puppeteer.launch({ headless: true });
    // const browser = await puppeteer.launch({
    //   headless: true,
    //   executablePath: process.env.CHROME_PATH || '/opt/bin/chromium',
    //   args: ['--no-sandbox', '--disable-setuid-sandbox']
    // });
    console.log("===============>", process.env.NODE_ENV, process.env.CHROME_PATH)

    // 修改字体加载部分
    console.time("chromium.font");
    try {
      await chromium.font(path.posix.join(process.cwd(), 'public', 'fonts', 'SimSun.ttf'));
    } catch (error: any) {
      if (error.code !== 'EEXIST') {
        throw error;
      }
    }
    console.timeEnd("chromium.font");

    console.time("puppeteer.launch");
    const browser = await puppeteer.launch({
      // args: [...chromium.args, '--hide-scrollbars', '--disable-web-security', '--no-sandbox', '--disable-setuid-sandbox'],
      // 只有 production 环境才需要 args
      args: process.env.NODE_ENV === 'production' ? [...chromium.args, '--hide-scrollbars', '--disable-web-security', '--no-sandbox', '--disable-setuid-sandbox'] : [],
      defaultViewport: chromium.defaultViewport,
      // executablePath: process.env.NODE_ENV === 'production' ? await chromium.executablePath(
      //   `https://github.com/Sparticuz/chromium/releases/download/v123.0.1/chromium-v123.0.1-pack.tar`
      // ) :  process.env.CHROME_PATH,
      executablePath: process.env.CHROME_PATH,
      headless: chromium.headless,
      ignoreHTTPSErrors: true,
    });
    console.timeEnd("puppeteer.launch");

    console.time("browser.newPage");
    const page = await browser.newPage();
    console.timeEnd("browser.newPage");

    // 设置视口大小 - 使用自定义尺寸
    console.time("setViewport");
    await page.setViewport({ 
      width: Math.max(dimensions.width, 800),  // 确保视口足够大
      height: Math.max(dimensions.height, 600) 
    });
    console.timeEnd("setViewport");

    // 使用新的API方式避免URL过长问题
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";
    
    // 准备海报数据
    const posterData = {
      content: markdown,
      header,
      footer,
      logo,
      theme,
      width: dimensions.width,
      height: dimensions.height,
    };

    let fullUrl: string;
    
    // 检查数据长度，如果可能导致URL过长则使用API存储方式
    const estimatedUrlLength = JSON.stringify(posterData).length * 3; // 估算编码后的长度
    
    if (estimatedUrlLength > 1500) {
      console.log(`数据量较大 (估算${estimatedUrlLength}字符)，使用API存储方式`);
      
      // 将数据存储到API
      const storeResponse = await fetch(`${baseUrl}/api/posterData`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ data: posterData }),
      });
      
      if (!storeResponse.ok) {
        throw new Error(`API存储失败: ${storeResponse.statusText}`);
      }
      
      const { dataId } = await storeResponse.json();
      fullUrl = `${baseUrl}/poster?dataId=${dataId}`;
      console.log("使用API存储，dataId:", dataId);
      
    } else {
      console.log("数据量较小，使用直接URL方式");
      const url = buildPosterUrl('/poster', posterData);
      fullUrl = `${baseUrl}${url}`;
    }
    
    console.log("fullUrl", fullUrl);
    console.time("page.goto");
    await page.goto(fullUrl, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });
    console.timeEnd("page.goto");

    // 调试：截图页面，便于排查元素是否渲染
    // await page.screenshot({ path: 'debug-before-wait.png' });

    try {
      console.time("waitForSelector");
      // 等待海报元素渲染完成
      await page.waitForSelector(".poster-content", { timeout: 10000 });
      console.timeEnd("waitForSelector");
    } catch (e) {
      // 超时时输出页面 HTML 便于排查
      // const html = await page.content();
      // fs.writeFileSync('debug-timeout.html', html);
      // await page.screenshot({ path: 'debug-timeout.png' });
      throw e;
    }
    
    // 等待所有图片加载完成
    console.time("waitImages");
    const imagesLoadTime = await page.evaluate(() => {
      // 只统计未加载完成的图片
      const notLoadedImgs = Array.from(document.images).filter(img => !img.complete);
      const loadPromises = notLoadedImgs.map(img => {
        const start = performance.now();
        return new Promise(resolve => {
          img.onload = img.onerror = () => {
            const end = performance.now();
            resolve({
              src: img.src,
              loadTime: end - start
            });
          };
        });
      });
      // 已经加载完成的图片也返回
      const loadedImgs = Array.from(document.images)
        .filter(img => img.complete)
        .map(img => ({
          src: img.src,
          loadTime: 0
        }));
      return Promise.all(loadPromises).then(results => [...loadedImgs, ...results]);
    });
    imagesLoadTime.forEach(img => {
      console.log(`图片: ${img.src} 加载用时: ${img.loadTime.toFixed(2)} ms`);
    });
    console.timeEnd("waitImages");

    // 获取元素
    console.time("getPosterElement");
    const element = await page.$(".poster-content");
    console.timeEnd("getPosterElement");

    if (!element) {
      throw new Error("Poster element not found");
    }

    // 获取元素的边界框
    console.time("boundingBox");
    const box = await element.boundingBox();
    console.timeEnd("boundingBox");
    if (!box) {
      throw new Error("Could not get element bounds");
    }

    // 生成唯一文件名
    const fileName = `poster-${Date.now()}.png`;
    // 保存路径 (public/uploads/posters/)
    const saveDir = process.env.NODE_ENV === 'production' 
      ? path.join('/tmp', 'uploads', 'posters')
      : path.join(process.cwd(), "public", "uploads", "posters");
    const savePath = path.join(saveDir, fileName);

    // 确保目录存在
    if (!fs.existsSync(saveDir)) {
      fs.mkdirSync(saveDir, { recursive: true });
    }

    // 只截取特定元素
    console.time("screenshot");
    await page.screenshot({
      path: savePath,
      clip: {
        x: box.x,
        y: box.y,
        width: box.width,
        height: box.height,
      },
    });
    console.timeEnd("screenshot");

    console.time("browser.close");
    await browser.close();
    console.timeEnd("browser.close");

    // 返回可访问的URL和详细信息
    const imageUrl = process.env.NODE_ENV === 'production'
      ? `/api/images/${fileName}` // 新的 API 路由来处理图片
      : `/uploads/posters/${fileName}`;
    
    const response = {
      url: `${baseUrl}${imageUrl}`,
      filename: fileName,
      dimensions: {
        width: Math.round(box.width),
        height: Math.round(box.height),
        requested: {
          width: dimensions.width,
          height: dimensions.height
        }
      },
      fileSize: fs.statSync(savePath).size,
      generatedAt: new Date().toISOString(),
      theme: theme || 'SpringGradientWave'
    };
    
    console.log(`✅ 海报生成成功: ${fileName}, 尺寸: ${response.dimensions.width}x${response.dimensions.height}`);
    res.status(200).json(response);
    
  } catch (error: any) {
    console.error("海报生成失败:", error);
    
    // 详细的错误信息
    let errorMessage = "海报生成失败";
    if (error.message?.includes("Poster element not found")) {
      errorMessage = "海报元素未找到，请检查内容格式";
    } else if (error.message?.includes("Could not get element bounds")) {
      errorMessage = "无法获取元素边界，请检查内容长度";
    } else if (error.message?.includes("timeout")) {
      errorMessage = "页面加载超时，请稍后重试";
    }
    
    res.status(500).json({ 
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
}
