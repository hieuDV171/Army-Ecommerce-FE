import 'package:army_ecommerce/models/order_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:army_ecommerce/ui/util/constants/app_colors.dart';
import 'package:army_ecommerce/ui/util/constants/app_radius.dart';
import 'package:army_ecommerce/ui/util/constants/app_spacing.dart';
import 'package:army_ecommerce/ui/util/widgets/empty_state.dart';
import 'package:army_ecommerce/ui/util/widgets/error_state.dart';
import 'package:army_ecommerce/ui/util/widgets/loading_overlay.dart';
import 'package:army_ecommerce/ui/util/widgets/price_text.dart';
import 'package:army_ecommerce/ui/util/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_event.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_state.dart';

import 'widgets/order_card.dart';
import 'seller_order_detail_page.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';
import 'package:army_ecommerce/ui/util/widgets/app_text_field.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  static const _tabs = [
    ('Tất cả', null),
    ('Chờ xác nhận', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Đã giao', 'delivered'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý bán hàng'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã giao'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _tabs) _SellerOrderList(stateFilter: tab.$2),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderList extends StatelessWidget {
  final String? stateFilter;

  const _SellerOrderList({required this.stateFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(OrderListRequested(isSeller: true, stateFilter: stateFilter)),
      child: _SellerOrderListView(stateFilter: stateFilter),
    );
  }
}

class _SellerOrderListView extends StatefulWidget {
  final String? stateFilter;

  const _SellerOrderListView({required this.stateFilter});

  @override
  State<_SellerOrderListView> createState() => _SellerOrderListViewState();
}

class _SellerOrderListViewState extends State<_SellerOrderListView> {
  final ScrollController _scrollController = ScrollController();
  bool _isManualActionExpanded = false;

  late final TextEditingController _manualPurchaseIdController;
  late final TextEditingController _manualBuyerIdController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _manualPurchaseIdController = TextEditingController();
    _manualBuyerIdController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _manualPurchaseIdController.dispose();
    _manualBuyerIdController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      context.read<OrderBloc>().add(
            OrderLoadMoreRequested(isSeller: true, stateFilter: widget.stateFilter),
          );
    }
  }

  void _handleAction(OrderModel order, OrderActionType actionType) {
    context.read<OrderBloc>().add(
          OrderActionRequested(
            order: order,
            actionType: actionType,
          ),
        );
  }

  void _handleManualAction(OrderActionType actionType) {
    final purchaseId = _manualPurchaseIdController.text.trim();
    final buyerId = _manualBuyerIdController.text.trim();
    if (purchaseId.isEmpty || buyerId.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ mã đơn và mã người mua');
      return;
    }

    final dummyOrder = OrderModel(
      id: purchaseId,
      buyerId: buyerId,
      status: '',
      total: 0,
      shipFee: 0,
      finalPrice: 0,
      summary: '',
      items: const [],
    );

    context.read<OrderBloc>().add(
          OrderActionRequested(
            order: dummyOrder,
            actionType: actionType,
            buyerId: buyerId,
          ),
        );
  }

  Widget _buildManualActionCard() {
    final isPending = widget.stateFilter == 'pending';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thao tác thủ công',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(_isManualActionExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isManualActionExpanded = !_isManualActionExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isManualActionExpanded) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _manualPurchaseIdController,
                      label: 'Mã đơn hàng',
                      hint: 'purchase_id',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _manualBuyerIdController,
                      label: 'Mã người mua',
                      hint: 'buyer_id',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPending) ...[
                    OutlinedButton(
                      onPressed: () => _handleManualAction(OrderActionType.reject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('Từ chối'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => _handleManualAction(OrderActionType.accept),
                      child: const Text('Chấp nhận'),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => _handleManualAction(OrderActionType.ship),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('Xác nhận gửi hàng'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCard = widget.stateFilter == 'pending' || widget.stateFilter == 'confirmed';

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          AppSnackBar.showSuccess(context, message: state.successMessage!);
          _manualPurchaseIdController.clear();
          _manualBuyerIdController.clear();
          context.read<OrderBloc>().add(
                OrderListRequested(isSeller: true, stateFilter: widget.stateFilter, isRefresh: true),
              );
        } else if (state.errorMessage != null) {
          final errorMsg = state.errorMessage!;
          if (errorMsg.contains('Parameter value is invalid') || errorMsg.contains('1002')) {
            AppSnackBar.showError(
              context,
              message: 'Không thể tự động lấy mã người mua do giới hạn của server. Vui lòng dùng ô "Thao tác thủ công" ở đầu trang.',
            );
          } else {
            AppSnackBar.showError(context, message: 'Lỗi: $errorMsg');
          }
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          Widget content;

          if (state.isLoading && state.orders.isEmpty) {
            content = const Center(child: CircularProgressIndicator());
          } else if (state.errorMessage != null && state.orders.isEmpty) {
            content = ErrorState(
              message: state.errorMessage!,
              onRetry: () {
                context.read<OrderBloc>().add(
                      OrderListRequested(isSeller: true, stateFilter: widget.stateFilter, isRefresh: true),
                    );
              },
            );
          } else if (state.orders.isEmpty) {
            content = const EmptyState(
              title: 'Chưa có đơn hàng nào',
              message: 'Các đơn hàng bạn bán sẽ hiển thị ở đây.',
            );
          } else {
            content = RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<OrderBloc>();
                bloc.add(
                  OrderListRequested(isSeller: true, stateFilter: widget.stateFilter, isRefresh: true),
                );
                await bloc.stream.firstWhere((s) => !s.isLoading);
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (index == state.orders.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final order = state.orders[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerOrderDetailPage(orderId: order.id),
                          ),
                        );
                        if (updated == true && context.mounted) {
                          context.read<OrderBloc>().add(
                                OrderListRequested(isSeller: true, stateFilter: widget.stateFilter, isRefresh: true),
                              );
                        }
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.summary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Mã đơn: ${order.id}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                      if ((order.buyerName ?? '').isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Người mua: ${order.buyerName}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                      if ((order.createdAt ?? '').isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          order.createdAt!,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                StatusChip(
                                  label: statusLabel(order.status),
                                  color: statusColor(order.status),
                                  icon: statusIcon(order.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.items.isEmpty ? '0 sản phẩm' : '${order.items.length} sản phẩm',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                                PriceText(price: order.finalPrice > 0 ? order.finalPrice : order.total),
                              ],
                            ),
                            if (order.status == 'pending' || order.status == 'confirmed') ...[
                              const Divider(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (order.status == 'pending') ...[
                                    OutlinedButton(
                                      onPressed: () => _handleAction(order, OrderActionType.reject),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    ElevatedButton(
                                      onPressed: () => _handleAction(order, OrderActionType.accept),
                                      child: const Text('Chấp nhận'),
                                    ),
                                  ] else if (order.status == 'confirmed') ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _handleAction(order, OrderActionType.ship),
                                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                      label: const Text('Xác nhận gửi hàng'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          if (showCard) {
            content = Column(
              children: [
                _buildManualActionCard(),
                Expanded(child: content),
              ],
            );
          }

          return LoadingOverlay(
            isLoading: state.isActionInProgress,
            child: content,
          );
        },
      ),
    );
  }
}
