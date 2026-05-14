import 'package:army_ecommerce/blocs/block/block_event.dart';
import 'package:army_ecommerce/blocs/block/block_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _pageSize = 20;

class BlockBloc extends Bloc<BlockEvent, BlockState> {
  final BlockRepository blockRepository;

  int _index = 0;

  BlockBloc({required this.blockRepository}) : super(BlockInitial()) {
    on<BlockUserRequested>(_onBlockUserRequested);
    on<LoadBlockedUsersRequested>(_onLoadBlockedUsersRequested);
    on<LoadMoreBlockedUsersRequested>(_onLoadMoreBlockedUsersRequested);
  }

  // Xử lý sự kiện block hoặc unblock một user
  Future<void> _onBlockUserRequested(
    BlockUserRequested event,
    Emitter<BlockState> emit,
  ) async {
    try {
      final response = await blockRepository.setBlocks(
        userId: event.userId,
        action: event.action,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        emit(BlockActionSuccess(
          userId: event.userId,
          isBlocked: event.action == 'block',
        ));
      } else {
        // Mã 1010: hành động đã thực hiện trước đó - không cần báo ra UI
        if (responseCode == ResponseCode.actionDone) {
          logger.w('BlockBloc: action already done for userId=${event.userId}');
          return;
        }
        logger.w('BlockBloc: block action failed code=${response.code}');
        emit(BlockFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(BlockFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải trang đầu danh sách user đã chặn
  Future<void> _onLoadBlockedUsersRequested(
    LoadBlockedUsersRequested event,
    Emitter<BlockState> emit,
  ) async {
    emit(BlockLoading());
    _index = 1;

    try {
      final response = await blockRepository.getListBlocks(
        index: _index,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _index += 1;
        emit(BlockedUsersLoaded(blockedUsers: list, hasMore: list.length == _pageSize));
      } else {
        logger.w('BlockBloc: getListBlocks failed code=${response.code}');
        emit(BlockFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(BlockFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải thêm danh sách user đã chặn (infinite scroll)
  Future<void> _onLoadMoreBlockedUsersRequested(
    LoadMoreBlockedUsersRequested event,
    Emitter<BlockState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BlockedUsersLoaded || !currentState.hasMore) return;

    emit(BlockLoadingMore(currentList: currentState.blockedUsers));

    try {
      final response = await blockRepository.getListBlocks(
        index: _index,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _index += 1;
        final updatedList = [...currentState.blockedUsers, ...newItems];
        emit(BlockedUsersLoaded(blockedUsers: updatedList, hasMore: newItems.length == _pageSize));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(BlockedUsersLoaded(blockedUsers: currentState.blockedUsers, hasMore: false));
          return;
        }
        logger.w('BlockBloc: loadMore blocked users failed code=${response.code}');
        emit(BlockFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(BlockFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }
}
