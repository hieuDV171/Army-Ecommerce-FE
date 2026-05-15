import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:equatable/equatable.dart';

abstract class FollowState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Trạng thái khởi đầu
class FollowInitial extends FollowState {}

// Trạng thái đang tải dữ liệu lần đầu (hiển thị skeleton)
class FollowLoading extends FollowState {}

// Trạng thái đang tải thêm dữ liệu (đã có list, đang append)
class FollowLoadingMore extends FollowState {
  final List<UserFollowModel> currentList;

  FollowLoadingMore({required this.currentList});

  @override
  List<Object?> get props => [currentList];
}

// Trạng thái sau khi follow/unfollow thành công
class FollowActionSuccess extends FollowState {
  final String followeeId;
  final String username;
  final bool isFollowed;
  final int followerCount;
  final int followingCount;

  FollowActionSuccess({
    required this.followeeId,
    required this.username,
    required this.isFollowed,
    required this.followerCount,
    required this.followingCount,
  });

  @override
  List<Object?> get props => [followeeId, username, isFollowed, followerCount, followingCount];
}

// Trạng thái sau khi tải danh sách người theo dõi thành công
class FollowersLoaded extends FollowState {
  final List<UserFollowModel> followers;
  // Cho biết còn dữ liệu để tải thêm hay không
  final bool hasMore;

  FollowersLoaded({required this.followers, required this.hasMore});

  @override
  List<Object?> get props => [followers, hasMore];
}

// Trạng thái sau khi tải danh sách đang theo dõi thành công
class FollowingLoaded extends FollowState {
  final List<UserFollowModel> following;
  final bool hasMore;

  FollowingLoaded({required this.following, required this.hasMore});

  @override
  List<Object?> get props => [following, hasMore];
}

// Trạng thái khi có lỗi xảy ra
class FollowFailure extends FollowState {
  final String error;
  final String code;

  FollowFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}
