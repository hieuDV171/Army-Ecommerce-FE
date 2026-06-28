import 'package:army_ecommerce/blocs/follow/follow_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Số lượng item tải mỗi lần (dùng chung cho followers và following)
const int _pageSize = 20;

class FollowBloc extends Bloc<FollowEvent, FollowState> {
  final FollowRepository followRepository;

  // Lưu số trang hiện tại (1-indexed) để phục vụ infinite scroll
  int _followersIndex = 0;
  int _followingIndex = 0;

  FollowBloc({required this.followRepository}) : super(FollowInitial()) {
    on<FollowUserRequested>(_onFollowUserRequested);
    on<LoadFollowersRequested>(_onLoadFollowersRequested);
    on<LoadMoreFollowersRequested>(_onLoadMoreFollowersRequested);
    on<LoadFollowingRequested>(_onLoadFollowingRequested);
    on<LoadMoreFollowingRequested>(_onLoadMoreFollowingRequested);
  }

  // Xử lý sự kiện follow hoặc unfollow một user
  Future<void> _onFollowUserRequested(
    FollowUserRequested event,
    Emitter<FollowState> emit,
  ) async {
    // Lưu lại state hiện tại để cập nhật list sau khi action thành công
    final previousState = state;

    try {
      final response = await followRepository.setUserFollow(
        followeeId: event.followeeId,
        action: event.action,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        // Dùng event.action thay vì response.data.isFollowed vì API có thể không trả về đúng
        final newIsFollowed = event.action == 'follow';
        emit(
          FollowActionSuccess(
            followeeId: response.data!.followeeId,
            username: event.username,
            isFollowed: newIsFollowed,
            followerCount: response.data!.followerCount,
            followingCount: response.data!.followingCount,
          ),
        );
        if (previousState is FollowingLoaded) {
          final updatedList = previousState.following.map((user) {
            return user.id == event.followeeId
                ? user.copyWith(isFollowed: newIsFollowed)
                : user;
          }).toList();
          emit(
            FollowingLoaded(
              following: updatedList,
              hasMore: previousState.hasMore,
            ),
          );
        } else if (previousState is FollowersLoaded) {
          final updatedList = previousState.followers.map((user) {
            return user.id == event.followeeId
                ? user.copyWith(isFollowed: newIsFollowed)
                : user;
          }).toList();
          emit(
            FollowersLoaded(
              followers: updatedList,
              hasMore: previousState.hasMore,
            ),
          );
        }
      } else {
        // Mã 1010: đã thực hiện hành động trước đó - không cần báo lỗi ra UI
        if (responseCode == ResponseCode.actionDone) {
          logger.w(
            'FollowBloc: action already done for followeeId=${event.followeeId}',
          );
          return;
        }
        logger.w('FollowBloc: follow action failed code=${response.code}');
        emit(FollowFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(
        FollowFailure(error: e.toString(), code: ResponseCode.exception.code),
      );
    }
  }

  // Xử lý tải trang đầu danh sách người theo dõi
  Future<void> _onLoadFollowersRequested(
    LoadFollowersRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(FollowLoading());
    _followersIndex = 0;

    try {
      final response = await followRepository.getListFollowed(
        userId: event.userId,
        index: _followersIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _followersIndex += 1;
        emit(
          FollowersLoaded(followers: list, hasMore: list.length == _pageSize),
        );
      } else {
        logger.w('FollowBloc: getListFollowed failed code=${response.code}');
        emit(FollowFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(
        FollowFailure(error: e.toString(), code: ResponseCode.exception.code),
      );
    }
  }

  // Xử lý tải thêm danh sách người theo dõi (infinite scroll)
  Future<void> _onLoadMoreFollowersRequested(
    LoadMoreFollowersRequested event,
    Emitter<FollowState> emit,
  ) async {
    // Chỉ tải thêm nếu state hiện tại có list để append vào
    final currentState = state;
    if (currentState is! FollowersLoaded || !currentState.hasMore) return;

    emit(FollowLoadingMore(currentList: currentState.followers));

    try {
      final response = await followRepository.getListFollowed(
        userId: event.userId,
        index: _followersIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _followersIndex += 1;
        final updatedList = [...currentState.followers, ...newItems];
        emit(
          FollowersLoaded(
            followers: updatedList,
            hasMore: newItems.length == _pageSize,
          ),
        );
      } else {
        // Khi hết dữ liệu (9994), giữ nguyên list, tắt cờ hasMore
        if (ResponseCode.fromCode(response.code) == ResponseCode.noData) {
          emit(
            FollowersLoaded(followers: currentState.followers, hasMore: false),
          );
          return;
        }
        logger.w('FollowBloc: loadMore followers failed code=${response.code}');
        emit(FollowFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(
        FollowFailure(error: e.toString(), code: ResponseCode.exception.code),
      );
    }
  }

  // Xử lý tải trang đầu danh sách đang theo dõi
  Future<void> _onLoadFollowingRequested(
    LoadFollowingRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(FollowLoading());
    _followingIndex = 0;

    try {
      final response = await followRepository.getListFollowing(
        userId: event.userId,
        index: _followingIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _followingIndex += 1;
        emit(
          FollowingLoaded(following: list, hasMore: list.length == _pageSize),
        );
      } else {
        logger.w('FollowBloc: getListFollowing failed code=${response.code}');
        emit(FollowFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(
        FollowFailure(error: e.toString(), code: ResponseCode.exception.code),
      );
    }
  }

  // Xử lý tải thêm danh sách đang theo dõi (infinite scroll)
  Future<void> _onLoadMoreFollowingRequested(
    LoadMoreFollowingRequested event,
    Emitter<FollowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FollowingLoaded || !currentState.hasMore) return;

    emit(FollowLoadingMore(currentList: currentState.following));

    try {
      final response = await followRepository.getListFollowing(
        userId: event.userId,
        index: _followingIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _followingIndex += 1;
        final updatedList = [...currentState.following, ...newItems];
        emit(
          FollowingLoaded(
            following: updatedList,
            hasMore: newItems.length == _pageSize,
          ),
        );
      } else {
        if (ResponseCode.fromCode(response.code) == ResponseCode.noData) {
          emit(
            FollowingLoaded(following: currentState.following, hasMore: false),
          );
          return;
        }
        logger.w('FollowBloc: loadMore following failed code=${response.code}');
        emit(FollowFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(
        FollowFailure(error: e.toString(), code: ResponseCode.exception.code),
      );
    }
  }
}
