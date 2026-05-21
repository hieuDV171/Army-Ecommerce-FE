import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'army_ecommerce_secret_key_2026_Quang_Trung_Soldier';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: number;
    phone_number: string;
    role: string;
  };
}

export const authenticateToken = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): any => {
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
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    
    // Tìm và gán user
    req.user = {
      id: decoded.sub,
      phone_number: decoded.username, // username chứa sđt trong JWT token của hệ thống cũ
      role: decoded.role || 'soldier',
    };
    return next();
  } catch (error) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid.',
      data: null,
    });
  }
};
