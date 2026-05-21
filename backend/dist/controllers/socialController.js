"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserFollow = exports.getListFollowing = exports.getListFollowed = exports.setUserBlock = exports.getListBlocks = void 0;
const db_1 = __importDefault(require("../config/db"));
// [POST] /get_list_blocks
const getListBlocks = async (req, res) => {
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
    try {
        const blocks = await db_1.default.userBlock.findMany({
            where: { user_id: userId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        const blockedIds = blocks.map((b) => b.blocked_id);
        const users = await db_1.default.user.findMany({
            where: { id: { in: blockedIds } },
            select: {
                id: true,
                username: true,
                avatar: true,
            },
        });
        const formatted = users.map((u) => ({
            id: u.id.toString(),
            username: u.username,
            avatar: u.avatar,
        }));
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getListBlocks error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getListBlocks = getListBlocks;
// [POST] /set_user_block
const setUserBlock = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    const targetUserId = parseInt(req.body.user_id);
    const type = parseInt(req.body.type); // 1 = block, 0 = unblock
    if (isNaN(targetUserId) || isNaN(type)) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough or invalid',
            data: null,
        });
    }
    if (userId === targetUserId) {
        return res.status(200).json({
            code: '1004',
            message: 'Cannot block yourself',
            data: null,
        });
    }
    try {
        const targetUser = await db_1.default.user.findUnique({ where: { id: targetUserId } });
        if (!targetUser) {
            return res.status(200).json({
                code: '1004',
                message: 'Target user not found',
                data: null,
            });
        }
        if (type === 1) {
            // Thực hiện Block
            await db_1.default.userBlock.upsert({
                where: {
                    user_id_blocked_id: {
                        user_id: userId,
                        blocked_id: targetUserId,
                    },
                },
                update: {},
                create: {
                    user_id: userId,
                    blocked_id: targetUserId,
                },
            });
        }
        else {
            // Thực hiện Unblock
            await db_1.default.userBlock.deleteMany({
                where: {
                    user_id: userId,
                    blocked_id: targetUserId,
                },
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: null,
        });
    }
    catch (error) {
        console.error('setUserBlock error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.setUserBlock = setUserBlock;
// [POST] /get_list_followed
const getListFollowed = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    // user_id mục tiêu (người có những người theo dõi mình)
    const targetUserId = parseInt(req.body.user_id) || userId;
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    try {
        // Lấy danh sách những người đang follow targetUserId
        const follows = await db_1.default.userFollow.findMany({
            where: { following_id: targetUserId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        const followerIds = follows.map((f) => f.follower_id);
        const users = await db_1.default.user.findMany({
            where: { id: { in: followerIds } },
            select: {
                id: true,
                username: true,
                avatar: true,
            },
        });
        const formatted = [];
        for (const u of users) {
            // Kiểm tra xem user hiện tại (userId) có đang follow user này (u.id) không
            const isFollowing = await db_1.default.userFollow.findUnique({
                where: {
                    follower_id_following_id: {
                        follower_id: userId,
                        following_id: u.id,
                    },
                },
            });
            formatted.push({
                id: u.id.toString(),
                username: u.username,
                avatar: u.avatar,
                followed: isFollowing !== null, // Trạng thái follow của user hiện tại với u
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getListFollowed error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getListFollowed = getListFollowed;
// [POST] /get_list_following
const getListFollowing = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    const targetUserId = parseInt(req.body.user_id) || userId;
    const index = parseInt(req.body.index) || 0;
    const count = parseInt(req.body.count) || 20;
    try {
        // Lấy danh sách những người mà targetUserId đang follow
        const follows = await db_1.default.userFollow.findMany({
            where: { follower_id: targetUserId },
            skip: index,
            take: count,
            orderBy: { created_at: 'desc' },
        });
        const followingIds = follows.map((f) => f.following_id);
        const users = await db_1.default.user.findMany({
            where: { id: { in: followingIds } },
            select: {
                id: true,
                username: true,
                avatar: true,
            },
        });
        const formatted = [];
        for (const u of users) {
            // Kiểm tra xem user hiện tại (userId) có đang follow user này (u.id) không
            const isFollowing = await db_1.default.userFollow.findUnique({
                where: {
                    follower_id_following_id: {
                        follower_id: userId,
                        following_id: u.id,
                    },
                },
            });
            formatted.push({
                id: u.id.toString(),
                username: u.username,
                avatar: u.avatar,
                followed: isFollowing !== null,
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: formatted,
        });
    }
    catch (error) {
        console.error('getListFollowing error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.getListFollowing = getListFollowing;
// [POST] /set_user_follow
const setUserFollow = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid',
            data: null,
        });
    }
    const followeeId = parseInt(req.body.followee_id);
    const action = req.body.action; // 'follow' hoặc 'unfollow'
    if (isNaN(followeeId) || !action) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough or invalid',
            data: null,
        });
    }
    if (userId === followeeId) {
        return res.status(200).json({
            code: '1004',
            message: 'Cannot follow yourself',
            data: null,
        });
    }
    try {
        const followee = await db_1.default.user.findUnique({ where: { id: followeeId } });
        if (!followee) {
            return res.status(200).json({
                code: '1004',
                message: 'User to follow not found',
                data: null,
            });
        }
        if (action === 'follow') {
            await db_1.default.userFollow.upsert({
                where: {
                    follower_id_following_id: {
                        follower_id: userId,
                        following_id: followeeId,
                    },
                },
                update: {},
                create: {
                    follower_id: userId,
                    following_id: followeeId,
                },
            });
        }
        else {
            await db_1.default.userFollow.deleteMany({
                where: {
                    follower_id: userId,
                    following_id: followeeId,
                },
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: null,
        });
    }
    catch (error) {
        console.error('setUserFollow error:', error);
        return res.status(200).json({
            code: '1005',
            message: 'Database error',
            data: null,
        });
    }
};
exports.setUserFollow = setUserFollow;
