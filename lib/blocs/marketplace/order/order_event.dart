import 'package:army_ecommerce/models/order_model.dart';
import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderListRequested extends OrderEvent {
  final bool isSeller;
  final String? stateFilter;
  final bool isRefresh;

  const OrderListRequested({
    required this.isSeller,
    this.stateFilter,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [isSeller, stateFilter, isRefresh];
}

class OrderLoadMoreRequested extends OrderEvent {
  final bool isSeller;
  final String? stateFilter;

  const OrderLoadMoreRequested({required this.isSeller, this.stateFilter});

  @override
  List<Object?> get props => [isSeller, stateFilter];
}

class OrderDetailRequested extends OrderEvent {
  final String orderId;

  const OrderDetailRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

enum OrderActionType { accept, reject, ship, cancel, confirmReceived, refund }

class OrderActionRequested extends OrderEvent {
  final OrderModel order;
  final OrderActionType actionType;
  final String? buyerId;
  final String? reason;

  const OrderActionRequested({
    required this.order,
    required this.actionType,
    this.buyerId,
    this.reason,
  });

  @override
  List<Object?> get props => [order, actionType, buyerId, reason];
}

class OrderEditRequested extends OrderEvent {
  final String orderId;
  final Map<String, dynamic> data;

  const OrderEditRequested({required this.orderId, required this.data});

  @override
  List<Object?> get props => [orderId, data];
}
