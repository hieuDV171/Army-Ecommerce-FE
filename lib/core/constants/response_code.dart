enum ResponseCode {
  ok('1000', 'OK'),
  spam('9991', 'Spam'),
  productNotExisted('9992', 'Product is not existed'),
  codeVerifyIncorrect('9993', 'Code verify is incorrect'),
  noData('9994', 'No Data or end of list data'),
  userNotValidated('9995', 'Tài khoản chưa đăng ký hoặc mật khẩu không chính xác'),
  userExisted('9996', 'User existed'),
  methodInvalid('9997', 'Method is invalid'),
  tokenInvalid('9998', 'Token is invalid'),
  exception('9999', 'Exception occurred'),

  // Các mã lỗi hệ thống và validate
  dbConnectionError('1001', 'Cannot connect to DB'),
  parameterNotEnough('1002', 'Parameter is not enough'),
  parameterTypeInvalid('1003', 'Parameter type is invalid'),
  parameterValueInvalid('1004', 'Parameter value is invalid'),
  unknownError('1005', 'Unknown error'),
  tooBigFile('1006', 'File size is too big'),
  uploadFileFailed('1007', 'Upload File Failed!'),
  maxImages('1008', 'Maximum number of images.'),
  notAccess('1009', 'Not access'),
  actionDone('1010', 'Action has been done previously by this user'),
  productSold('1011', 'The product has been sold'),
  shippingUnsupported('1012', 'Address is not supported for shipping'),
  urlUserIsExisted('1013', 'URL user is existed'),
  promotionalCodeExpired('1014', 'Promotional code is expired'),
  cannotProcessBankCard('1015', 'Cannot process bank card'),
  policyViolation('1016', 'Policy violation, not support weight over 20kg & price over 30M'),
  leastTimeChangeUsername('1017', 'You must wait at least 30 days to change username again'),
  sameUsername('1018', 'The new username is the same as the current one'),

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