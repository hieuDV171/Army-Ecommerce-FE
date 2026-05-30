import express from 'express';
import cors from 'cors';
import path from 'path';
import dotenv from 'dotenv';

// Load variables
dotenv.config();

import apiRoutes from './routes/apiRoutes';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files (Cho phép truy cập ảnh upload trực tiếp)
const uploadDir = path.join(__dirname, '../uploads');
app.use('/uploads', express.static(uploadDir));

// Route API chính
app.use('/', apiRoutes);

// Khởi chạy server
app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`🚀 Server đang chạy trên port: ${PORT}`);
  console.log(`👉 Link API Health: http://localhost:${PORT}/`);
  console.log(`📁 Thư mục Upload: ${uploadDir}`);
  console.log(`====================================================`);
});
