"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const path_1 = __importDefault(require("path"));
const dotenv_1 = __importDefault(require("dotenv"));
// Load variables
dotenv_1.default.config();
const apiRoutes_1 = __importDefault(require("./routes/apiRoutes"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Serve static files (Cho phép truy cập ảnh upload trực tiếp)
const uploadDir = path_1.default.join(__dirname, '../../uploads');
app.use('/uploads', express_1.default.static(uploadDir));
// Route API chính
app.use('/', apiRoutes_1.default);
// Khởi chạy server
app.listen(PORT, () => {
    console.log(`====================================================`);
    console.log(`🚀 Server đang chạy trên port: ${PORT}`);
    console.log(`👉 Link API Health: http://localhost:${PORT}/`);
    console.log(`📁 Thư mục Upload: ${uploadDir}`);
    console.log(`====================================================`);
});
