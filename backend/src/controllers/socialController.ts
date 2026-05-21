import { Response } from 'express';
import prisma from '../config/db';
import { AuthenticatedRequest } from '../middlewares/auth';

// [POST] /get_list_blocks
export const getListBlocks = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  try {
    const blocks = await prisma.userBlock.findMany({
      where: { user_id: userId },
      skip: index,
      take: count,
      orderBy: { created_at: 'desc' },
    });

    const blockedIds = blocks.map((b) => b.blocked_id);

    const users = await prisma.user.findMany({
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
  } catch (error) {
    console.error('getListBlocks error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /set_user_block
export const setUserBlock = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const targetUserId = parseInt(req.body.user_id as string);
  const type = parseInt(req.body.type as string); // 1 = block, 0 = unblock

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
    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) {
      return res.status(200).json({
        code: '1004',
        message: 'Target user not found',
        data: null,
      });
    }

    if (type === 1) {
      // Thực hiện Block
      await prisma.userBlock.upsert({
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
    } else {
      // Thực hiện Unblock
      await prisma.userBlock.deleteMany({
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
  } catch (error) {
    console.error('setUserBlock error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /get_list_followed
export const getListFollowed = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  // user_id mục tiêu (người có những người theo dõi mình)
  const targetUserId = parseInt(req.body.user_id as string) || userId;
  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  try {
    // Lấy danh sách những người đang follow targetUserId
    const follows = await prisma.userFollow.findMany({
      where: { following_id: targetUserId },
      skip: index,
      take: count,
      orderBy: { created_at: 'desc' },
    });

    const followerIds = follows.map((f) => f.follower_id);

    const users = await prisma.user.findMany({
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
      const isFollowing = await prisma.userFollow.findUnique({
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
  } catch (error) {
    console.error('getListFollowed error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /get_list_following
export const getListFollowing = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const targetUserId = parseInt(req.body.user_id as string) || userId;
  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  try {
    // Lấy danh sách những người mà targetUserId đang follow
    const follows = await prisma.userFollow.findMany({
      where: { follower_id: targetUserId },
      skip: index,
      take: count,
      orderBy: { created_at: 'desc' },
    });

    const followingIds = follows.map((f) => f.following_id);

    const users = await prisma.user.findMany({
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
      const isFollowing = await prisma.userFollow.findUnique({
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
  } catch (error) {
    console.error('getListFollowing error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /set_user_follow
export const setUserFollow = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const followeeId = parseInt(req.body.followee_id as string);
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
    const followee = await prisma.user.findUnique({ where: { id: followeeId } });
    if (!followee) {
      return res.status(200).json({
        code: '1004',
        message: 'User to follow not found',
        data: null,
      });
    }

    if (action === 'follow') {
      await prisma.userFollow.upsert({
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
    } else {
      await prisma.userFollow.deleteMany({
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
  } catch (error) {
    console.error('setUserFollow error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};
