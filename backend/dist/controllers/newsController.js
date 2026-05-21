"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNewsDetail = exports.listNews = void 0;
const db_1 = __importDefault(require("../config/db"));
// [POST] /News/list_news
const listNews = async (req, res) => {
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    try {
        const news = await db_1.default.news.findMany({
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
    }
    catch (error) {
        console.error('listNews error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.listNews = listNews;
// [GET] /News/:id
const getNewsDetail = async (req, res) => {
    const newsId = parseInt(req.params.id);
    if (isNaN(newsId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    try {
        const item = await db_1.default.news.findUnique({
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
    }
    catch (error) {
        console.error('getNewsDetail error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getNewsDetail = getNewsDetail;
