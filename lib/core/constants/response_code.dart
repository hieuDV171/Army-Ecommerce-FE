enum ResponseCode {
  ok('1000', 'Thành công'),
  spam('9991', 'Thao tác quá nhanh, vui lòng thử lại sau'),
  productNotExisted('9992', 'Sản phẩm không tồn tại hoặc đã bị xóa'),
  codeVerifyIncorrect('9993', 'Mã xác thực không chính xác'),
  noData('9994', 'Không có dữ liệu hoặc đã hết danh sách'),
  userNotValidated(
    '9995',
    'Tài khoản chưa đăng ký hoặc mật khẩu không chính xác',
  ),
  userExisted('9996', 'Tài khoản hoặc số điện thoại đã tồn tại'),
  methodInvalid('9997', 'Phương thức yêu cầu không hợp lệ'),
  tokenInvalid('9998', 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ'),
  exception('9999', 'Hệ thống gặp sự cố, vui lòng thử lại sau'),

  // Các mã lỗi hệ thống và validate
  dbConnectionError('1001', 'Không thể kết nối cơ sở dữ liệu'),
  parameterNotEnough('1002', 'Thiếu tham số yêu cầu'),
  parameterTypeInvalid('1003', 'Kiểu tham số không hợp lệ'),
  parameterValueInvalid('1004', 'Giá trị tham số không hợp lệ'),
  unknownError('1005', 'Lỗi không xác định từ hệ thống'),
  tooBigFile('1006', 'Kích thước tệp tin quá lớn'),
  uploadFileFailed('1007', 'Tải tệp tin lên thất bại'),
  maxImages('1008', 'Đã đạt số lượng ảnh tối đa cho phép'),
  notAccess('1009', 'Bạn không có quyền thực hiện thao tác này'),
  actionDone('1010', 'Thao tác này đã được thực hiện trước đó'),
  productSold('1011', 'Sản phẩm này đã được bán'),
  shippingUnsupported('1012', 'Địa chỉ này không hỗ trợ vận chuyển'),
  urlUserIsExisted('1013', 'Đường dẫn người dùng đã tồn tại'),
  promotionalCodeExpired('1014', 'Mã khuyến mãi đã hết hạn'),
  cannotProcessBankCard('1015', 'Không thể xử lý thẻ ngân hàng này'),
  policyViolation(
    '1016',
    'Vi phạm chính sách: không hỗ trợ hàng nặng quá 20kg hoặc giá trên 30 triệu',
  ),
  leastTimeChangeUsername(
    '1017',
    'Bạn phải đợi ít nhất 30 ngày để đổi lại tên đăng nhập',
  ),
  sameUsername('1018', 'Tên đăng nhập mới trùng với tên đăng nhập hiện tại'),

  // Mã mặc định dùng khi API trả về một mã lạ chưa được định nghĩa
  unhandled('', 'Lỗi không xác định');

  final String code;
  final String message;

  const ResponseCode(this.code, this.message);

  // Hàm tiện ích để chuyển đổi string từ API thành Enum
  static ResponseCode fromCode(String codeString) {
    return ResponseCode.values.firstWhere(
      (e) => e.code == codeString,
      orElse: () => ResponseCode.unhandled,
    );
  }
}
