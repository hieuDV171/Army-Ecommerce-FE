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

  UserModel copyWith({String? token, String? username, String? avatar}) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
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
