import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/order_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final MarketplaceRepository marketplaceRepository;

  OrderBloc({required this.marketplaceRepository}) : super(const OrderState()) {
    on<OrderListRequested>(_onListRequested);
    on<OrderLoadMoreRequested>(_onLoadMoreRequested);
    on<OrderDetailRequested>(_onDetailRequested);
    on<OrderActionRequested>(_onActionRequested);
    on<OrderEditRequested>(_onEditRequested);
  }

  Future<void> _onListRequested(
    OrderListRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, index: 0, clearMessages: true, orders: []));
    try {
      final list = event.isSeller
          ? await marketplaceRepository.getOrdersSeller(
              state: event.stateFilter,
              index: 0,
              count: state.count,
            )
          : await marketplaceRepository.getOrders(
              state: event.stateFilter,
              index: 0,
              count: state.count,
            );
      emit(state.copyWith(
        orders: list,
        isLoading: false,
        hasReachedEnd: list.length < state.count,
        index: list.length,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    OrderLoadMoreRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    try {
      final list = event.isSeller
          ? await marketplaceRepository.getOrdersSeller(
              state: event.stateFilter,
              index: state.index,
              count: state.count,
            )
          : await marketplaceRepository.getOrders(
              state: event.stateFilter,
              index: state.index,
              count: state.count,
            );
      final merged = [...state.orders, ...list];
      emit(state.copyWith(
        orders: merged,
        isLoadingMore: false,
        hasReachedEnd: list.length < state.count,
        index: merged.length,
      ));
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onDetailRequested(
    OrderDetailRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isDetailLoading: true, clearMessages: true, orderDetail: null, timeline: []));
    try {
      final detailFuture = marketplaceRepository.getOrderDetail(event.orderId);
      final timelineFuture = marketplaceRepository.getOrderTimeline(event.orderId);
      final detail = await detailFuture;
      final timeline = await timelineFuture;
      emit(state.copyWith(
        orderDetail: detail,
        timeline: timeline,
        isDetailLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(isDetailLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onActionRequested(
    OrderActionRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearMessages: true));
    try {
      String? buyerId = event.buyerId ?? event.order.buyerId;
      if (event.actionType == OrderActionType.accept ||
          event.actionType == OrderActionType.reject ||
          event.actionType == OrderActionType.ship) {
        if (buyerId == null) {
          final detail = await marketplaceRepository.getOrderDetail(event.order.id);
          buyerId = detail?.buyerId;
        }
        if (buyerId == null) {
          throw Exception('Không tìm thấy ID người mua');
        }
      }

      String msg = '';
      switch (event.actionType) {
        case OrderActionType.accept:
          await marketplaceRepository.setAcceptBuyer(event.order.id, buyerId!, true);
          msg = 'Đã chấp nhận đơn hàng';
          break;
        case OrderActionType.reject:
          await marketplaceRepository.setAcceptBuyer(event.order.id, buyerId!, false);
          msg = 'Đã từ chối đơn hàng';
          break;
        case OrderActionType.ship:
          await marketplaceRepository.sellerMarkAsShipped(event.order.id, buyerId: buyerId!);
          msg = 'Đơn hàng đã được đánh dấu vận chuyển';
          break;
        case OrderActionType.cancel:
          await marketplaceRepository.cancelOrder(event.order.id, reason: event.reason);
          msg = 'Đã hủy đơn hàng';
          break;
        case OrderActionType.confirmReceived:
          await marketplaceRepository.confirmReceived(event.order.id);
          msg = 'Đã xác nhận đã nhận hàng';
          break;
        case OrderActionType.refund:
          await marketplaceRepository.refundOrder(event.order.id, reason: event.reason);
          msg = 'Đã gửi yêu cầu hoàn tiền / hoàn hàng';
          break;
      }

      emit(state.copyWith(
        isActionInProgress: false,
        successMessage: msg,
      ));
    } catch (error) {
      emit(state.copyWith(isActionInProgress: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onEditRequested(
    OrderEditRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearMessages: true));
    try {
      final updatedData = await marketplaceRepository.editOrder(event.orderId, event.data);
      final currentDetail = state.orderDetail;
      if (currentDetail != null && currentDetail.status == 'confirmed') {
        await SessionManager.setOrderEdited(event.orderId, true);
      }
      
      OrderModel? updatedDetail;
      if (currentDetail != null) {
        final updatedNote = updatedData['note']?.toString() ?? currentDetail.note;
        final updatedAddress = updatedData['address']?.toString() ?? currentDetail.buyerAddress;
        updatedDetail = currentDetail.copyWith(
          note: updatedNote,
          buyerAddress: updatedAddress,
        );
      }

      emit(state.copyWith(
        isActionInProgress: false,
        successMessage: 'Đã cập nhật địa chỉ / ghi chú',
        orderDetail: updatedDetail,
      ));
    } catch (error) {
      emit(state.copyWith(isActionInProgress: false, errorMessage: error.toString()));
    }
  }
}
