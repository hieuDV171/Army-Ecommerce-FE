"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setRates = exports.getRates = exports.reportProduct = exports.sendComment = exports.getComments = exports.likeProduct = exports.getSavedSearches = exports.saveSearch = exports.searchProducts = exports.updateProduct = exports.getUserListings = exports.getProducts = exports.getListProducts = exports.getListBrands = exports.getCategories = exports.deleteProduct = exports.addProduct = void 0;
const db_1 = __importDefault(require("../config/db"));
const addProduct = async (req, res) => {
    const { title, price, description, image_urls, brand_id, variants, category_id, ship_from_id, videos, } = req.body;
    // 1. Kiểm tra thiếu tham số (code 1002)
    if (!title ||
        price === undefined ||
        !description ||
        brand_id === undefined ||
        !variants ||
        category_id === undefined ||
        ship_from_id === undefined ||
        !videos) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    // 2. Kiểm tra kiểu dữ liệu (code 1003)
    if (typeof title !== 'string' ||
        typeof price !== 'number' ||
        typeof description !== 'string' ||
        typeof brand_id !== 'number' ||
        typeof category_id !== 'number' ||
        typeof ship_from_id !== 'number' ||
        !Array.isArray(variants) ||
        !Array.isArray(videos) ||
        (image_urls && !Array.isArray(image_urls))) {
        return res.status(200).json({
            code: '1003',
            message: 'Parameter type is invalid.',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        // 3. Kiểm tra tính hợp lệ của kho hàng, thương hiệu, danh mục (code 1004)
        const brand = await db_1.default.brand.findUnique({ where: { id: brand_id } });
        const category = await db_1.default.category.findUnique({ where: { id: category_id } });
        const warehouse = await db_1.default.orderAddress.findUnique({
            where: { id: ship_from_id },
        });
        if (!brand || !category || !warehouse) {
            return res.status(200).json({
                code: '1004',
                message: 'Parameter value is invalid. Brand, Category, or Warehouse not found.',
                data: null,
            });
        }
        // 4. Tạo sản phẩm qua transaction
        const imageUrlsString = JSON.stringify(image_urls || []);
        const product = await db_1.default.$transaction(async (tx) => {
            const p = await tx.product.create({
                data: {
                    title,
                    price: Number(price),
                    description,
                    image_urls: imageUrlsString,
                    brand_id,
                    category_id,
                    ship_from_id,
                    seller_id: req.user.id,
                },
            });
            // Tạo các variants
            for (const v of variants) {
                await tx.productVariant.create({
                    data: {
                        product_id: p.id,
                        size: v.size,
                        stock: Number(v.stock),
                        color: v.color,
                        weight: Number(v.weight),
                    },
                });
            }
            // Tạo các videos
            for (const video of videos) {
                await tx.productVideo.create({
                    data: {
                        product_id: p.id,
                        url: video.url,
                    },
                });
            }
            return p;
        });
        // Tăng số lượng listing của user
        await db_1.default.user.update({
            where: { id: req.user.id },
            data: { listing: { increment: 1 } },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: product.id,
            },
        });
    }
    catch (error) {
        console.error('addProduct error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.addProduct = addProduct;
const deleteProduct = async (req, res) => {
    const productId = Number(req.params.id);
    if (isNaN(productId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const product = await db_1.default.product.findUnique({
            where: { id: productId },
        });
        if (!product) {
            return res.status(200).json({
                code: '9992',
                message: 'Product is not existed',
                data: null,
            });
        }
        if (product.seller_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(200).json({
                code: '1009',
                message: 'Not access',
                data: null,
            });
        }
        await db_1.default.product.delete({
            where: { id: productId },
        });
        // Giảm số lượng listing của user
        await db_1.default.user.update({
            where: { id: product.seller_id },
            data: { listing: { decrement: 1 } },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: null,
        });
    }
    catch (error) {
        console.error('deleteProduct error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.deleteProduct = deleteProduct;
const getCategories = async (req, res) => {
    const { parent_id } = req.body;
    try {
        const categories = await db_1.default.category.findMany({
            where: parent_id !== undefined ? { parent_id: Number(parent_id) } : {},
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: categories,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getCategories = getCategories;
const getListBrands = async (req, res) => {
    const { category_id, index, count } = req.body;
    const idx = index !== undefined ? Number(index) : 0;
    const cnt = count !== undefined ? Number(count) : 20;
    try {
        const brands = await db_1.default.brand.findMany({
            where: category_id && Number(category_id) !== 0 ? { category_id: Number(category_id) } : {},
            skip: idx,
            take: cnt,
        });
        if (brands.length === 0) {
            return res.status(200).json({
                code: '9994',
                message: 'No Data or end of list data',
                data: [],
            });
        }
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: brands,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getListBrands = getListBrands;
const getListProducts = async (req, res) => {
    const { category_id, keyword, brand_id, price_min, price_max, order, index, count, } = req.body;
    if (index === undefined || count === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    const idx = Number(index);
    const cnt = Number(count);
    try {
        // Xây dựng bộ lọc WHERE cho Prisma
        const where = {};
        if (category_id && Number(category_id) !== 0) {
            where.category_id = Number(category_id);
        }
        if (brand_id && Number(brand_id) !== 0) {
            where.brand_id = Number(brand_id);
        }
        if (keyword) {
            where.OR = [
                { title: { contains: String(keyword) } },
                { description: { contains: String(keyword) } },
            ];
        }
        if (price_min !== undefined) {
            where.price = { ...where.price, gte: Number(price_min) };
        }
        if (price_max !== undefined) {
            where.price = { ...where.price, lte: Number(price_max) };
        }
        // Xắp xếp ORDER
        let orderBy = { created_at: 'desc' };
        if (order === 'price_asc') {
            orderBy = { price: 'asc' };
        }
        else if (order === 'price_desc') {
            orderBy = { price: 'desc' };
        }
        else if (order === 'created_desc') {
            orderBy = { created_at: 'desc' };
        }
        const products = await db_1.default.product.findMany({
            where,
            orderBy,
            skip: idx,
            take: cnt,
            include: {
                seller: true,
                brand: true,
                category: true,
                variants: true,
                videos: true,
            },
        });
        if (products.length === 0) {
            return res.status(200).json({
                code: '9994',
                message: 'No Data or end of list data',
                data: [],
            });
        }
        // Parse image_urls từ JSON string sang Array cho frontend
        const mappedProducts = products.map((p) => {
            let parsedImages = [];
            try {
                parsedImages = JSON.parse(p.image_urls);
            }
            catch (e) {
                parsedImages = p.image_urls ? [p.image_urls] : [];
            }
            return {
                id: p.id,
                title: p.title,
                price: p.price,
                description: p.description,
                image_urls: parsedImages,
                brand: {
                    id: p.brand.id,
                    name: p.brand.name,
                },
                category: {
                    id: p.category.id,
                    name: p.category.name,
                },
                ship_from_id: p.ship_from_id,
                seller: {
                    id: p.seller.id,
                    username: p.seller.username,
                    avatar: p.seller.avatar,
                },
                variants: p.variants,
                videos: p.videos,
                created_at: p.created_at,
                status: p.status,
            };
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: mappedProducts,
        });
    }
    catch (error) {
        console.error('getListProducts error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getListProducts = getListProducts;
const getProducts = async (req, res) => {
    const { id } = req.body;
    if (!id) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const product = await db_1.default.product.findUnique({
            where: { id: Number(id) },
            include: {
                seller: true,
                brand: true,
                category: true,
                variants: true,
                videos: true,
            },
        });
        if (!product) {
            return res.status(200).json({
                code: '9992',
                message: 'Product is not existed',
                data: null,
            });
        }
        let parsedImages = [];
        try {
            parsedImages = JSON.parse(product.image_urls);
        }
        catch (e) {
            parsedImages = product.image_urls ? [product.image_urls] : [];
        }
        const data = {
            id: product.id,
            title: product.title,
            price: product.price,
            description: product.description,
            image_urls: parsedImages,
            brand: {
                id: product.brand.id,
                name: product.brand.name,
            },
            category: {
                id: product.category.id,
                name: product.category.name,
            },
            ship_from_id: product.ship_from_id,
            seller: {
                id: product.seller.id,
                username: product.seller.username,
                avatar: product.seller.avatar,
            },
            variants: product.variants,
            videos: product.videos,
            created_at: product.created_at,
            status: product.status,
        };
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: data,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getProducts = getProducts;
const getUserListings = async (req, res) => {
    const { index, count, user_id } = req.body;
    if (index === undefined || count === undefined || user_id === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const products = await db_1.default.product.findMany({
            where: { seller_id: Number(user_id) },
            skip: Number(index),
            take: Number(count),
            include: {
                seller: true,
                brand: true,
                category: true,
                variants: true,
                videos: true,
            },
        });
        const mappedProducts = products.map((p) => {
            let parsedImages = [];
            try {
                parsedImages = JSON.parse(p.image_urls);
            }
            catch (e) {
                parsedImages = p.image_urls ? [p.image_urls] : [];
            }
            return {
                id: p.id,
                title: p.title,
                price: p.price,
                description: p.description,
                image_urls: parsedImages,
                brand: {
                    id: p.brand.id,
                    name: p.brand.name,
                },
                category: {
                    id: p.category.id,
                    name: p.category.name,
                },
                ship_from_id: p.ship_from_id,
                seller: {
                    id: p.seller.id,
                    username: p.seller.username,
                    avatar: p.seller.avatar,
                },
                variants: p.variants,
                videos: p.videos,
                created_at: p.created_at,
                status: p.status,
            };
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: mappedProducts,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getUserListings = getUserListings;
const updateProduct = async (req, res) => {
    const productId = parseInt(req.params.id);
    if (isNaN(productId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const { title, price, description, image_urls, brand_id, variants, category_id, ship_from_id, videos, image_urls_del, } = req.body;
    try {
        const product = await db_1.default.product.findUnique({
            where: { id: productId },
        });
        if (!product) {
            return res.status(200).json({
                code: '9992',
                message: 'Product is not existed',
                data: null,
            });
        }
        if (product.seller_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(200).json({
                code: '1009',
                message: 'Not access',
                data: null,
            });
        }
        // Xử lý các ảnh
        let currentImages = [];
        try {
            currentImages = JSON.parse(product.image_urls);
        }
        catch (e) {
            currentImages = product.image_urls ? [product.image_urls] : [];
        }
        if (image_urls_del && Array.isArray(image_urls_del)) {
            currentImages = currentImages.filter((img) => !image_urls_del.includes(img));
        }
        if (image_urls && Array.isArray(image_urls)) {
            currentImages = [...currentImages, ...image_urls];
        }
        // Thực hiện cập nhật qua transaction
        await db_1.default.$transaction(async (tx) => {
            await tx.product.update({
                where: { id: productId },
                data: {
                    title: title !== undefined ? title : undefined,
                    price: price !== undefined ? Number(price) : undefined,
                    description: description !== undefined ? description : undefined,
                    brand_id: brand_id !== undefined ? Number(brand_id) : undefined,
                    category_id: category_id !== undefined ? Number(category_id) : undefined,
                    ship_from_id: ship_from_id !== undefined ? Number(ship_from_id) : undefined,
                    image_urls: JSON.stringify(currentImages),
                },
            });
            // Nếu truyền variants, xóa cũ thêm mới
            if (variants && Array.isArray(variants)) {
                await tx.productVariant.deleteMany({ where: { product_id: productId } });
                for (const v of variants) {
                    await tx.productVariant.create({
                        data: {
                            product_id: productId,
                            size: v.size,
                            stock: Number(v.stock),
                            color: v.color,
                            weight: Number(v.weight),
                        },
                    });
                }
            }
            // Nếu truyền videos, xóa cũ thêm mới
            if (videos && Array.isArray(videos)) {
                await tx.productVideo.deleteMany({ where: { product_id: productId } });
                for (const video of videos) {
                    await tx.productVideo.create({
                        data: {
                            product_id: productId,
                            url: video.url,
                        },
                    });
                }
            }
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                id: productId,
            },
        });
    }
    catch (error) {
        console.error('updateProduct error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.updateProduct = updateProduct;
const searchProducts = async (req, res) => {
    return (0, exports.getListProducts)(req, res);
};
exports.searchProducts = searchProducts;
const saveSearch = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const { keyword } = req.body;
    if (!keyword) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const saved = await db_1.default.savedSearch.create({
            data: {
                user_id: userId,
                keyword,
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                id: saved.id,
                keyword: saved.keyword,
            },
        });
    }
    catch (error) {
        console.error('saveSearch error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.saveSearch = saveSearch;
const getSavedSearches = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    try {
        const list = await db_1.default.savedSearch.findMany({
            where: { user_id: userId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        // Map sang dạng MarketplaceItem
        const formatted = list.map((item) => ({
            id: item.id.toString(),
            title: item.keyword,
            description: item.keyword,
            created_at: item.created_at,
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getSavedSearches error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getSavedSearches = getSavedSearches;
const likeProduct = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const productId = parseInt(req.body.product_id);
    if (isNaN(productId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    try {
        const existingLike = await db_1.default.productLike.findUnique({
            where: {
                user_id_product_id: {
                    user_id: userId,
                    product_id: productId,
                },
            },
        });
        if (existingLike) {
            await db_1.default.productLike.delete({
                where: { id: existingLike.id },
            });
            return res.status(200).json({
                code: '1000',
                message: 'OK',
                data: { liked: false },
            });
        }
        else {
            await db_1.default.productLike.create({
                data: {
                    user_id: userId,
                    product_id: productId,
                },
            });
            return res.status(200).json({
                code: '1000',
                message: 'OK',
                data: { liked: true },
            });
        }
    }
    catch (error) {
        console.error('likeProduct error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.likeProduct = likeProduct;
const getComments = async (req, res) => {
    const productId = parseInt(req.body.product_id);
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    if (isNaN(productId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    try {
        const comments = await db_1.default.comment.findMany({
            where: { product_id: productId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
            include: {
                user: true,
            },
        });
        const formatted = comments.map((c) => ({
            id: c.id.toString(),
            comment_id: c.id.toString(),
            content: c.content,
            created_at: c.created_at.toISOString(),
            createdAt: c.created_at.toISOString(),
            author: c.user.username,
            username: c.user.username,
            user_name: c.user.username,
            poster: {
                id: c.user.id.toString(),
                name: c.user.username,
                avatar: c.user.avatar || '',
            },
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getComments error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getComments = getComments;
const sendComment = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const productId = parseInt(req.body.product_id);
    const { content } = req.body;
    if (isNaN(productId) || !content) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough or invalid',
            data: null,
        });
    }
    try {
        const comment = await db_1.default.comment.create({
            data: {
                product_id: productId,
                user_id: userId,
                content,
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                id: comment.id.toString(),
                content: comment.content,
            },
        });
    }
    catch (error) {
        console.error('sendComment error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.sendComment = sendComment;
const reportProduct = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const productId = parseInt(req.body.product_id);
    const { subject, details } = req.body;
    if (isNaN(productId) || !subject || !details) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        console.log(`User ${userId} báo cáo sản phẩm ${productId}. Subject: ${subject}. Details: ${details}`);
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: 'Report received successfully',
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.reportProduct = reportProduct;
const getRates = async (req, res) => {
    const { user_id, level, index, count } = req.body;
    const idx = index !== undefined ? Number(index) : 0;
    const cnt = count !== undefined ? Number(count) : 20;
    try {
        const where = {};
        if (user_id !== undefined) {
            where.product = {
                seller_id: Number(user_id),
            };
        }
        if (level !== undefined) {
            where.level = Number(level);
        }
        const rates = await db_1.default.rate.findMany({
            where,
            skip: idx,
            take: cnt,
            orderBy: { created_at: 'desc' },
            include: {
                user: {
                    select: {
                        id: true,
                        username: true,
                        avatar: true,
                    },
                },
            },
        });
        const formatted = rates.map((r) => ({
            id: r.id,
            user: r.user,
            level: r.level,
            content: r.content,
            product_id: r.product_id,
            purchase_id: r.purchase_id,
            created_at: r.created_at,
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getRates error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getRates = getRates;
const setRates = async (req, res) => {
    const buyerId = req.user?.id;
    if (!buyerId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const { level, content, product_id, purchase_id } = req.body;
    if (level === undefined || !content) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const rate = await db_1.default.rate.create({
            data: {
                user_id: buyerId,
                level: Number(level),
                content: content,
                product_id: product_id !== undefined ? Number(product_id) : null,
                purchase_id: purchase_id !== undefined ? purchase_id.toString() : null,
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: rate,
        });
    }
    catch (error) {
        console.error('setRates error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.setRates = setRates;
