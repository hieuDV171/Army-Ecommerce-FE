import 'package:equatable/equatable.dart';

abstract class FollowEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện follow hoặc unfollow một user
class FollowUserRequested extends FollowEvent {
  final String followeeId;
  // action: 'follow' | 'unfollow'
  final String action;

  FollowUserRequested({required this.followeeId, required this.action});

  @override
  List<Object?> get props => [followeeId, action];
}

// Sự kiện tải danh sách người đang theo dõi user_id (trang đầu)
class LoadFollowersRequested extends FollowEvent {
  final String userId;

  LoadFollowersRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Sự kiện tải thêm danh sách người theo dõi (infinite scroll)
class LoadMoreFollowersRequested extends FollowEvent {
  final String userId;

  LoadMoreFollowersRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Sự kiện tải danh sách user mà user_id đang theo dõi (trang đầu)
class LoadFollowingRequested extends FollowEvent {
  final String userId;

  LoadFollowingRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Sự kiện tải thêm danh sách đang theo dõi (infinite scroll)
class LoadMoreFollowingRequested extends FollowEvent {
  final String userId;

  LoadMoreFollowingRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}
