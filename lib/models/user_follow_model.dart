// Model đại diện cho một user trong danh sách follow/block
class UserFollowModel {
  final String id;
  final String username;
  final String? avatar;
  // Trạng thái follow của current user với user này (null nếu là danh sách block)
  final bool? isFollowed;

  UserFollowModel({
    required this.id,
    required this.username,
    this.avatar,
    this.isFollowed,
  });

  // Tạo bản sao với một số trường được thay đổi
  UserFollowModel copyWith({bool? isFollowed}) {
    return UserFollowModel(
      id: id,
      username: username,
      avatar: avatar,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  // get_list_blocks  → trường 'name', 'image'
  // get_list_followed  → trường 'username', 'avatar', 'followed' (0/1)
  // get_list_following → trường 'username', 'avatar', 'is_followed' (0/1/bool)
  factory UserFollowModel.fromJson(Map<String, dynamic> json) {
    bool? isFollowed;
    if (json['followed'] != null) {
      isFollowed = json['followed'] == 1 || json['followed'] == true;
    } else if (json['is_followed'] != null) {
      isFollowed = json['is_followed'] == true || json['is_followed'] == 1;
    }

    return UserFollowModel(
      id: json['id']?.toString() ?? '',
      // 'name' dùng cho block list, 'username' dùng cho follow list
      username: (json['username'] ?? json['name'])?.toString() ?? '',
      // 'image' dùng cho block list, 'avatar' dùng cho follow list
      avatar: (json['avatar'] ?? json['image'])?.toString(),
      isFollowed: isFollowed,
    );
  }
}

// Kết quả trả về sau khi thực hiện follow/unfollow
class FollowActionResult {
  final String followeeId;
  final bool isFollowed;
  // Số người đang theo dõi followeeId
  final int followerCount;
  // Số người mà current user đang theo dõi
  final int followingCount;

  FollowActionResult({
    required this.followeeId,
    required this.isFollowed,
    required this.followerCount,
    required this.followingCount,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory FollowActionResult.fromJson(Map<String, dynamic> json) {
    return FollowActionResult(
      followeeId: json['followee_id']?.toString() ?? '',
      isFollowed: json['is_followed'] == true || json['is_followed'] == 1,
      followerCount:
          int.tryParse(json['follower_count']?.toString() ?? '0') ?? 0,
      followingCount:
          int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// Wrapper phản hồi API cho danh sách user follow/block
class UserFollowListResponse {
  final String code;
  final String message;
  final List<UserFollowModel>? data;

  UserFollowListResponse({
    required this.code,
    required this.message,
    this.data,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory UserFollowListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<UserFollowModel>? dataList;
    if (rawData is List) {
      dataList = rawData
          .whereType<Map>()
          .map(
            (item) => UserFollowModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return UserFollowListResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: dataList,
    );
  }
}

// Wrapper phản hồi API cho thao tác follow/unfollow
class FollowActionResponse {
  final String code;
  final String message;
  final FollowActionResult? data;

  FollowActionResponse({required this.code, required this.message, this.data});

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory FollowActionResponse.fromJson(Map<String, dynamic> json) {
    return FollowActionResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: (json['data'] != null && json['data'] is Map)
          ? FollowActionResult.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}
