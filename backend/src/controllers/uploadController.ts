import { Request, Response } from 'express';


export const uploadFile = (req: Request, res: Response) => {
  if (!req.file) {
    return res.status(200).json({
      code: '1002',
      message: 'Parameter is not enough (no file uploaded)',
      data: null,
    });
  }

  try {
    const filename = req.file.filename;
    
    // Tự động nhận diện protocol và host từ request để sinh URL chính xác cho client
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.get('host');
    const fileUrl = `${protocol}://${host}/uploads/${filename}`;

    return res.status(201).json({
      code: '1000',
      message: 'OK',
      data: {
        url: fileUrl,
        filename: filename,
      },
    });
  } catch (error) {
    console.error('uploadFile controller error:', error);
    return res.status(200).json({
      code: '1007',
      message: 'Upload File Failed!',
      data: null,
    });
  }
};
