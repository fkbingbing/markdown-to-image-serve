/*
 * @Author: claude
 * @Date: 2025-09-19
 * @Description: 海报数据临时存储API，解决URL过长问题
 * @FilePath: /markdown-to-image-serve/src/pages/api/posterData.ts
 */
import { NextApiRequest, NextApiResponse } from "next";

// 内存中的临时存储（生产环境建议使用Redis等）
const tempStorage: Record<string, any> = {};

// 清理过期数据（5分钟过期）
const EXPIRY_TIME = 5 * 60 * 1000; // 5分钟

function cleanExpiredData() {
  const now = Date.now();
  Object.keys(tempStorage).forEach(key => {
    if (tempStorage[key].timestamp < now - EXPIRY_TIME) {
      delete tempStorage[key];
    }
  });
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // 清理过期数据
  cleanExpiredData();

  if (req.method === "POST") {
    // 存储数据
    const { data } = req.body;
    if (!data) {
      return res.status(400).json({ error: "缺少data参数" });
    }

    const dataId = `poster_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    tempStorage[dataId] = {
      data,
      timestamp: Date.now()
    };

    return res.status(200).json({ dataId });
    
  } else if (req.method === "GET") {
    // 获取数据
    const { dataId } = req.query;
    if (!dataId || typeof dataId !== "string") {
      return res.status(400).json({ error: "缺少dataId参数" });
    }

    const stored = tempStorage[dataId];
    if (!stored) {
      return res.status(404).json({ error: "数据未找到或已过期" });
    }

    // 返回数据后删除，确保只能使用一次
    delete tempStorage[dataId];
    return res.status(200).json({ data: stored.data });
    
  } else {
    return res.status(405).json({ error: "只支持 GET 和 POST 请求" });
  }
}
