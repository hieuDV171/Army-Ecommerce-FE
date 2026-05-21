"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticateToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || 'army_ecommerce_secret_key_2026_Quang_Trung_Soldier';
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        // Tìm và gán user
        req.user = {
            id: decoded.sub,
            phone_number: decoded.username, // username chứa sđt trong JWT token của hệ thống cũ
            role: decoded.role || 'soldier',
        };
        return next();
    }
    catch (error) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
};
exports.authenticateToken = authenticateToken;
