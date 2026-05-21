import { Response } from 'express';
import prisma from '../config/db';
import { AuthenticatedRequest } from '../middlewares/auth';

// [POST] /notification/get_notification
export const getNotifications = async (req: AuthenticatedRequest, res: Response) => {
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
  const group = parseInt(req.body.group as string) || 0; // Nhóm thông báo (0 = tất cả)

  try {
    const queryConditions: any = { user_id: userId };
    if (group !== 0) {
      queryConditions.group = group;
    }

    const notifications = await prisma.notification.findMany({
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
  } catch (error) {
    console.error('getNotifications error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /notification/set_read_notification
export const markNotificationRead = async (req: AuthenticatedRequest, res: Response) => {
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

  const notificationId = parseInt(notificationIdInput as string);

  if (isNaN(notificationId)) {
    return res.status(200).json({
      code: '1004',
      message: 'Parameter value is invalid',
      data: null,
    });
  }

  try {
    const notification = await prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification || notification.user_id !== userId) {
      return res.status(200).json({
        code: '1004',
        message: 'Notification not found or access denied',
        data: null,
      });
    }

    await prisma.notification.update({
      where: { id: notificationId },
      data: { is_read: true },
    });

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: null,
    });
  } catch (error) {
    console.error('markNotificationRead error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};
