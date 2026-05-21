"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBalanceHistory = exports.getCurrentBalance = void 0;
const db_1 = __importDefault(require("../config/db"));
// [GET_CURRENT_BALANCE]
const getCurrentBalance = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            return res.status(200).json({
                code: '1004',
                message: 'User not found',
                data: null,
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                available_balance: user.available_balance,
                pending_balance: user.pending_balance,
            },
        });
    }
    catch (error) {
        console.error('getCurrentBalance error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getCurrentBalance = getCurrentBalance;
// [GET_BALANCE_HISTORY]
const getBalanceHistory = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    // FE có thể truyền index, count dưới dạng chuỗi hoặc số
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    try {
        const transactions = await db_1.default.walletTransaction.findMany({
            where: { user_id: userId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        const formattedHistory = transactions.map((t) => ({
            id: t.id.toString(),
            history_id: t.id.toString(),
            title: t.description,
            amount: t.amount,
            value: t.amount,
            created_at: t.created_at.toISOString(),
            createdAt: t.created_at.toISOString(),
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formattedHistory,
        });
    }
    catch (error) {
        console.error('getBalanceHistory error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getBalanceHistory = getBalanceHistory;
