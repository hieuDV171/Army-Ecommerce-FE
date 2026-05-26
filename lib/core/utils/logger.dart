import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// Khởi tạo đối tượng Logger dùng chung cho cả dự án
final logger = Logger(

  level: kDebugMode ? Level.all : Level.off,

  printer: PrettyPrinter(
    methodCount: 0,         // Không in ra danh sách các hàm đã gọi (để log gọn hơn)
    errorMethodCount: 5,    // Nếu có lỗi thì in ra 5 dòng để dễ debug
    lineLength: 80,         // Độ dài đường kẻ ngăn cách
    colors: true,           // In màu cho dễ nhìn (Xanh/Đỏ/Vàng)
    printEmojis: true,      // Thêm icon cho sinh động
  ),
);