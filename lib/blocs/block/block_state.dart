import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:equatable/equatable.dart';

abstract class BlockState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Trạng thái khởi đầu
class BlockInitial extends BlockState {}

// Trạng thái đang tải lần đầu (hiển thị skeleton)
class BlockLoading extends BlockState {}

// Trạng thái đang tải thêm (đã có list, đang append)
class BlockLoadingMore extends BlockState {
  final List<UserFollowModel> currentList;

  BlockLoadingMore({required this.currentList});

  @override
  List<Object?> get props => [currentList];
}

// Trạng thái sau khi block/unblock thành công
class BlockActionSuccess extends BlockState {
  final String userId;
  final String username;
  final bool isBlocked;

  BlockActionSuccess({
    required this.userId,
    required this.username,
    required this.isBlocked,
  });

  @override
  List<Object?> get props => [userId, username, isBlocked];
}

// Trạng thái sau khi tải danh sách đã chặn thành công
class BlockedUsersLoaded extends BlockState {
  final List<UserFollowModel> blockedUsers;
  final bool hasMore;

  BlockedUsersLoaded({required this.blockedUsers, required this.hasMore});

  @override
  List<Object?> get props => [blockedUsers, hasMore];
}

// Trạng thái khi có lỗi xảy ra
class BlockFailure extends BlockState {
  final String error;
  final String code;

  BlockFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}
