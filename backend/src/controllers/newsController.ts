import { Request, Response } from 'express';
import prisma from '../config/db';

// [POST] /News/list_news
export const listNews = async (req: Request, res: Response) => {
  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  try {
    const news = await prisma.news.findMany({
      skip: index,
      take: count,
      orderBy: { created_at: 'desc' },
    });

    const formattedNews = news.map((item) => ({
      id: item.id.toString(),
      title: item.title,
      content: item.content,
      subtitle: item.content, // Để FE parse dễ
      image_url: item.image_url,
      created_at: item.created_at.toISOString(),
      trailing: item.created_at.toISOString(),
    }));

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: formattedNews,
    });
  } catch (error) {
    console.error('listNews error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [GET] /News/:id
export const getNewsDetail = async (req: Request, res: Response) => {
  const newsId = parseInt(req.params.id);

  if (isNaN(newsId)) {
    return res.status(200).json({
      code: '1004',
      message: 'Parameter value is invalid',
      data: null,
    });
  }

  try {
    const item = await prisma.news.findUnique({
      where: { id: newsId },
    });

    if (!item) {
      return res.status(200).json({
        code: '1004',
        message: 'News not found',
        data: null,
      });
    }

    const formatted = {
      id: item.id.toString(),
      title: item.title,
      content: item.content,
      subtitle: item.content,
      image_url: item.image_url,
      created_at: item.created_at.toISOString(),
      trailing: item.created_at.toISOString(),
    };

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: formatted,
    });
  } catch (error) {
    console.error('getNewsDetail error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};
