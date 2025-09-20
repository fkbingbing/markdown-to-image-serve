/*
 * @Author: wxingheng
 * @Date: 2024-11-28 14:20:13
 * @LastEditTime: 2024-12-20 13:23:10
 * @LastEditors: wxingheng
 * @Description: 生成海报; 返回 base64 格式的海报
 * @FilePath: /markdown-to-image-serve/src/pages/api/generatePoster.ts
 */
import { NextApiRequest, NextApiResponse } from "next";
import path from "path";
const chromium = require("@sparticuz/chromium-min");
const puppeteer = require("puppeteer-core");
const fs = require("fs");


export const maxDuration = 60;

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "只支持 POST 请求" });
  }

  try {
    const { markdown, header = "", footer = "" } = req.body;

    // 修改字体加载部分
    try {
      await chromium.font(path.posix.join(process.cwd(), 'public', 'fonts', 'SimSun.ttf'));
    } catch (error: any) {
      if (error.code !== 'EEXIST') {
        throw error;
      }
    }

    const browser = await puppeteer.launch({
      args: [
        ...(process.env.NODE_ENV === "production" ? chromium.args : []),
        "--disable-gpu",
        "--disable-dev-shm-usage",
        "--no-first-run",
        "--no-sandbox",
        "--disable-web-security",
        "--ignore-certificate-errors",
        "--disable-font-subpixel-positioning",
        "--font-render-hinting=none",
        // "--hide-scrollbars",
        // "--disable-web-security",
        // "--no-sandbox",
        // "--disable-setuid-sandbox",
        // "--font-render-hinting=none",
        // "--force-color-profile=srgb",
        // "--allow-file-access-from-files",
      ],
      defaultViewport: chromium.defaultViewport,
      // executablePath: process.env.CHROME_PATH,
      executablePath:
        process.env.NODE_ENV === "production"
          ? await chromium.executablePath(
              `https://github.com/Sparticuz/chromium/releases/download/v123.0.1/chromium-v123.0.1-pack.tar`
            )
          : process.env.CHROME_PATH,
      headless: chromium.headless,
      ignoreHTTPSErrors: true,
    });

    const page = await browser.newPage();

    // 设置字体和编码
    await page.setExtraHTTPHeaders({
      "Accept-Language": "zh-CN,zh;q=0.9",
    });

    await page.evaluateOnNewDocument(() => {
      document.documentElement.lang = "zh-CN";
      const meta = document.createElement("meta");
      meta.setAttribute("charset", "UTF-8");
      document.head.insertBefore(meta, document.head.firstChild);
    });

    // 修改字体注入方式
    await page.evaluateOnNewDocument(() => {
      const style = document.createElement("style");
      style.textContent = `
        @font-face {
          font-family: 'Noto Sans SC';
          font-style: normal;
          font-weight: 400;
          src: url('https://fonts.gstatic.com/s/notosanssc/v36/k3kXo84MPvpLmixcA63oeALhLOCT-xWNm8Hqd37g1OkDRZe7lR4sg1IzSy-MNbE9VH8V.103.woff2') format('woff2');
          unicode-range: U+4E00-9FFF;
        }
        * {
         font-family: 'SimSun', sans-serif !important;
        }
        body {
         font-family: 'SimSun' !important;
        }
      `;
      document.head.appendChild(style);
    });

    // 设置视口大小
    await page.setViewport({ width: 1200, height: 1600 });
    // 加载中文字体
    await page.addStyleTag({
      content: `
      @font-face {
        font-family: 'SimSun';
        src: url('/fonts/SimSun.ttf') format('truetype');
      }
      body {
        font-family: 'SimSun', sans-serif;
      }
    `,
    });

    // 在Docker容器内使用127.0.0.1而不是localhost
    const baseUrl = process.env.INTERNAL_BASE_URL || process.env.NEXT_PUBLIC_BASE_URL || "http://127.0.0.1:3000";
    const url = `/poster?content=${encodeURIComponent(
      markdown
    )}&header=${encodeURIComponent(header)}&footer=${encodeURIComponent(
      footer
    )}`;
    const fullUrl = `${baseUrl}${url}`;
    console.log("fullUrl==========>", fullUrl);

    // 设置页面编码和等待时间
    await page.goto(fullUrl, {
      waitUntil: "networkidle0",
      timeout: 30000,
    });

    // 在截图前确保字体已加载
    await page.waitForFunction(() => document.fonts.ready);
    await new Promise((resolve) => setTimeout(resolve, 1000)); // 额外等待以确保字体完全加载

    // 等待海报元素渲染完成
    await page.waitForSelector(".poster-content", { timeout: 10000 });

    // 等待所有图片加载完成
    // await page.evaluate(() => {
    //   return Promise.all(
    //     Array.from(document.images)
    //       .filter((img) => !img.complete)
    //       .map(
    //         (img) =>
    //           new Promise((resolve) => {
    //             img.onload = img.onerror = resolve;
    //           })
    //       )
    //   );
    // });
    // 获取元素
    const element = await page.$(".poster-content");

    if (!element) {
      throw new Error("Poster element not found");
    }

    // 获取元素的边界框
    const box = await element.boundingBox();
    if (!box) {
      throw new Error("Could not get element bounds");
    }

    let imageUrl = "";

    // if (process.env.NODE_ENV === "development") {
    //   // 生成唯一文件名
    //   const fileName = `poster-${Date.now()}.png`;
    //   // 保存路径 (public/uploads/posters/)
    //   const saveDir = path.join(process.cwd(), "public", "uploads", "posters");
    //   const savePath = path.join(saveDir, fileName);
    //   // 确保目录存在
    //   if (!fs.existsSync(saveDir)) {
    //     fs.mkdirSync(saveDir, { recursive: true });
    //   }

    //   // 只截取特定元素
    //   await page.screenshot({
    //     path: savePath,
    //     clip: {
    //       x: box.x,
    //       y: box.y,
    //       width: box.width,
    //       height: box.height,
    //     },
    //   });

    //   imageUrl = `/uploads/posters/${fileName}`;
    // }

    // 直接获取 base64 格式的截图
    const posterBuffer = await page.screenshot({
      clip: {
        x: box.x,
        y: box.y,
        width: box.width,
        height: box.height,
      },
      // encoding: "base64",
      type: "png",
      omitBackground: false,
    });

    await browser.close();

    res.setHeader("Content-Type", "image/png");
    res.send(posterBuffer);
    // res.status(200).json({ fullUrl });
    // res.status(200).json({ base64: `data:image/png;base64,${base64Image}`, url:  `${baseUrl}${imageUrl}` });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to generate poster" });
  }
}
