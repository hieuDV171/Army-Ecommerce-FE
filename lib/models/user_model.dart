class UserModel {
  final String id;
  final String username;
  final String token;
  final String? avatar;
  final int active;

  UserModel({
    required this.id,
    required this.username,
    required this.token,
    this.avatar,
    required this.active,
  });

  UserModel copyWith({String? token}) {
    return UserModel(
      id: id,
      username: username,
      token: token ?? this.token,
      avatar: avatar,
      active: active,
    );
  }

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      active: int.tryParse(json['active']?.toString() ?? '0') ?? 0,
    );
  }
}

class AuthResponse {
  final String code;
  final String message;
  final UserModel? data;

  AuthResponse({
    required this.code,
    required this.message,
    this.data
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
    );
  }
}