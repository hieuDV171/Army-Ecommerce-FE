import { Response } from 'express';
import prisma from '../config/db';
import { AuthenticatedRequest } from '../middlewares/auth';

export const getUserInfo = async (req: AuthenticatedRequest, res: Response) => {
  const userIdStr = req.body.user_id;
  const userId = userIdStr ? Number(userIdStr) : req.user?.id;

  if (!userId) {
    return res.status(200).json({
      code: '1002',
      message: 'Parameter is not enough',
      data: null,
    });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return res.status(200).json({
        code: '9995',
        message: 'Tài khoản chưa đăng ký hoặc mật khẩu không chính xác',
        data: null,
      });
    }

    return res.status(200).json({
      code: '1000',
      message: 'OK.',
      data: {
        id: user.id,
        phonenumber: user.phone_number,
        username: user.username,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        address: user.address,
        city: user.city,
        avatar: user.avatar,
        cover_image: user.cover_image,
        cover_image_web: user.cover_image_web,
        status: user.status,
        listing: user.listing,
        online: user.online,
        followed: false,
        is_blocked: false,
        active: user.username === user.phone_number ? -1 : 1,
      },
    });
  } catch (error) {
    console.error('getUserInfo error:', error);
    return res.status(200).json({
      code: '9999',
      message: 'Exception occurred',
      data: null,
    });
  }
};

export const setUserInfo = async (req: AuthenticatedRequest, res: Response) => {
  const {
    email,
    username,
    status,
    avatar,
    firstname,
    lastname,
    address,
    cover_image,
    cover_image_web,
  } = req.body;

  if (!req.user) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid.',
      data: null,
    });
  }

  try {
    const updateData: any = {};
    if (email !== undefined) updateData.email = email;
    if (username !== undefined) updateData.username = username;
    if (status !== undefined) updateData.status = status;
    if (avatar !== undefined) updateData.avatar = avatar;
    if (firstname !== undefined) updateData.firstname = firstname;
    if (lastname !== undefined) updateData.lastname = lastname;
    if (address !== undefined) updateData.address = address;
    if (cover_image !== undefined) updateData.cover_image = cover_image;
    if (cover_image_web !== undefined) updateData.cover_image_web = cover_image_web;

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: updateData,
    });

    return res.status(200).json({
      code: '1000',
      message: 'OK.',
      data: {
        id: updatedUser.id,
        phonenumber: updatedUser.phone_number,
        username: updatedUser.username,
        email: updatedUser.email,
        firstname: updatedUser.firstname,
        lastname: updatedUser.lastname,
        address: updatedUser.address,
        city: updatedUser.city,
        avatar: updatedUser.avatar,
        cover_image: updatedUser.cover_image,
        cover_image_web: updatedUser.cover_image_web,
        status: updatedUser.status,
        listing: updatedUser.listing,
        online: updatedUser.online,
        active: updatedUser.username === updatedUser.phone_number ? -1 : 1,
      },
    });
  } catch (error) {
    console.error('setUserInfo error:', error);
    return res.status(200).json({
      code: '9999',
      message: 'Exception occurred',
      data: null,
    });
  }
};
