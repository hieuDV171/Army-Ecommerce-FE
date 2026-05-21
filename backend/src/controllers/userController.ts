import { Response } from 'express';
import prisma from '../config/db';
import { AuthenticatedRequest } from '../middlewares/auth';

export const getUserInfo = async (req: AuthenticatedRequest, res: Response) => {
  const { user_id } = req.body;

  if (!user_id) {
    return res.status(200).json({
      code: '1002',
      message: 'Parameter is not enough',
      data: null,
    });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: Number(user_id) },
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

  // check parameterNotEnough
  if (!email || !username || !status || !avatar || !firstname || !lastname || !address || !cover_image || !cover_image_web) {
    return res.status(200).json({
      code: '1002',
      message: 'Parameter is not enough',
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
    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        email,
        username,
        status,
        avatar,
        firstname,
        lastname,
        address,
        cover_image,
        cover_image_web,
      },
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
