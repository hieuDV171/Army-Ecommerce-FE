import 'package:equatable/equatable.dart';

abstract class BlockEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện block hoặc unblock một user
class BlockUserRequested extends BlockEvent {
  final String userId;
  // action: 'block' | 'unblock'
  final String action;

  BlockUserRequested({required this.userId, required this.action});

  @override
  List<Object?> get props => [userId, action];
}

// Sự kiện tải danh sách user đã chặn (trang đầu)
class LoadBlockedUsersRequested extends BlockEvent {}

// Sự kiện tải thêm danh sách user đã chặn (infinite scroll)
class LoadMoreBlockedUsersRequested extends BlockEvent {}
