"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadFile = void 0;
const uploadFile = (req, res) => {
    if (!req.file) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough (no file uploaded)',
            data: null,
        });
    }
    try {
        const filename = req.file.filename;
        // Tạo link download public tĩnh
        const baseUrl = process.env.BASE_URL || `http://${req.hostname}:${process.env.PORT || 3000}`;
        const fileUrl = `${baseUrl}/uploads/${filename}`;
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                url: fileUrl,
                filename: filename,
            },
        });
    }
    catch (error) {
        console.error('uploadFile controller error:', error);
        return res.status(200).json({
            code: '1007',
            message: 'Upload File Failed!',
            data: null,
        });
    }
};
exports.uploadFile = uploadFile;
