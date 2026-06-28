import 'package:army_ecommerce/models/order_model.dart';
import 'package:equatable/equatable.dart';

class OrderState extends Equatable {
  final List<OrderModel> orders;
  final OrderModel? orderDetail;
  final List<OrderTimelineModel> timeline;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final bool isDetailLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const OrderState({
    this.orders = const [],
    this.orderDetail,
    this.timeline = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.isDetailLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.successMessage,
    this.index = 0,
    this.count = 20,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    OrderModel? orderDetail,
    List<OrderTimelineModel>? timeline,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    bool? isDetailLoading,
    bool? isActionInProgress,
    String? errorMessage,
    String? successMessage,
    int? index,
    int? count,
    bool clearMessages = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      orderDetail: orderDetail ?? this.orderDetail,
      timeline: timeline ?? this.timeline,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    orders,
    orderDetail,
    timeline,
    isLoading,
    isLoadingMore,
    hasReachedEnd,
    isDetailLoading,
    isActionInProgress,
    errorMessage,
    successMessage,
    index,
    count,
  ];
}
