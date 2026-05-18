class UserModel {
  final String id;
  final String username;
  final String token;
  final String? avatar;
  final int active;

  final String? email;
  final String? phoneNumber;
  final String? status;
  final String? coverImage;
  final String? coverImageWeb;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String? city;
  final int? listing;
  final bool? followed;
  final bool? isBlocked;
  final dynamic defaultAddress;
  final bool? online;

  UserModel({
    required this.id,
    required this.username,
    required this.token,
    this.avatar,
    required this.active,
    this.email,
    this.phoneNumber,
    this.status,
    this.coverImage,
    this.coverImageWeb,
    this.firstName,
    this.lastName,
    this.address,
    this.city,
    this.listing,
    this.followed,
    this.isBlocked,
    this.defaultAddress,
    this.online,
  });

  UserModel copyWith({
    String? token,
    String? username,
    String? avatar,
    String? email,
    String? phoneNumber,
    String? status,
    String? coverImage,
    String? coverImageWeb,
    String? firstName,
    String? lastName,
    String? address,
    String? city,
    int? listing,
    bool? followed,
    bool? isBlocked,
    dynamic defaultAddress,
    bool? online,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      active: active,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      coverImage: coverImage ?? this.coverImage,
      coverImageWeb: coverImageWeb ?? this.coverImageWeb,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      city: city ?? this.city,
      listing: listing ?? this.listing,
      followed: followed ?? this.followed,
      isBlocked: isBlocked ?? this.isBlocked,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      online: online ?? this.online,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      active: int.tryParse(json['active']?.toString() ?? '-1') ?? -1,
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      status: json['status']?.toString(),
      coverImage: json['cover_image']?.toString(),
      coverImageWeb: json['cover_image_web']?.toString(),
      firstName: json['firstname']?.toString(),
      lastName: json['lastname']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      listing: int.tryParse(json['listing']?.toString() ?? ''),
      followed: _parseBool(json['followed']),
      isBlocked: _parseBool(json['is_blocked']),
      defaultAddress: json['default_address'],
      online: _parseBool(json['online']),
    );
  }


  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
    return null;
  }
}
