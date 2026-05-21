"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.markNotificationRead = exports.getNotifications = void 0;
const db_1 = __importDefault(require("../config/db"));
// [POST] /notification/get_notification
const getNotifications = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    const group = parseInt(req.body.group) || 0; // Nhóm thông báo (0 = tất cả)
    try {
        const queryConditions = { user_id: userId };
        if (group !== 0) {
            queryConditions.group = group;
        }
        const notifications = await db_1.default.notification.findMany({
            where: queryConditions,
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        const formatted = notifications.map((n) => ({
            id: n.id.toString(),
            notification_id: n.id.toString(),
            title: n.title,
            type: n.type,
            message: n.content,
            content: n.content,
            created_at: n.created_at.toISOString(),
            createdAt: n.created_at.toISOString(),
            read: n.is_read,
            is_read: n.is_read,
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getNotifications error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getNotifications = getNotifications;
// [POST] /notification/set_read_notification
const markNotificationRead = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    const notificationIdInput = req.body.notification_id;
    if (!notificationIdInput) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    const notificationId = parseInt(notificationIdInput);
    if (isNaN(notificationId)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    try {
        const notification = await db_1.default.notification.findUnique({
            where: { id: notificationId },
        });
        if (!notification || notification.user_id !== userId) {
            return res.status(200).json({
                code: '1004',
                message: 'Notification not found or access denied',
                data: null,
            });
        }
        await db_1.default.notification.update({
            where: { id: notificationId },
            data: { is_read: true },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: null,
        });
    }
    catch (error) {
        console.error('markNotificationRead error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.markNotificationRead = markNotificationRead;
