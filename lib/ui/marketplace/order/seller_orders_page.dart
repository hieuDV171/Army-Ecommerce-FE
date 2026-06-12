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

class _SellerOrderList extends StatefulWidget {
  final String? stateFilter;

  const _SellerOrderList({required this.stateFilter});

  @override
  State<_SellerOrderList> createState() => _SellerOrderListState();
}

class _SellerOrderListState extends State<_SellerOrderList> {
  final ScrollController _scrollController = ScrollController();
  List<OrderModel> _orders = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  String? _error;
  bool _isActionInProgress = false;

  late final TextEditingController _manualPurchaseIdController;
  late final TextEditingController _manualBuyerIdController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
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
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _orders = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
    });
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getOrdersSeller(
        state: widget.stateFilter,
        index: 0,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _orders = list;
        _currentIndex = list.length;
        _hasReachedEnd = list.length < 20;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedEnd || _isLoading) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getOrdersSeller(
        state: widget.stateFilter,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...list];
        _currentIndex += list.length;
        _hasReachedEnd = list.length < 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _handleAccept(OrderModel order) async {
    if (order.buyerId == null) {
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().setAcceptBuyer(
            order.id,
            order.buyerId!,
            true,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đã chấp nhận đơn hàng');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleReject(OrderModel order) async {
    if (order.buyerId == null) {
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().setAcceptBuyer(
            order.id,
            order.buyerId!,
            false,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đã từ chối đơn hàng');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleMarkShipped(OrderModel order) async {
    if (order.buyerId == null) {
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().sellerMarkAsShipped(
            order.id,
            buyerId: order.buyerId,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đơn hàng đã được đánh dấu vận chuyển');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleManualAccept() async {
    final purchaseId = _manualPurchaseIdController.text.trim();
    final buyerId = _manualBuyerIdController.text.trim();
    if (purchaseId.isEmpty || buyerId.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ mã đơn và mã người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().setAcceptBuyer(
            purchaseId,
            buyerId,
            true,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đã chấp nhận đơn hàng $purchaseId');
      _manualPurchaseIdController.clear();
      _manualBuyerIdController.clear();
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleManualReject() async {
    final purchaseId = _manualPurchaseIdController.text.trim();
    final buyerId = _manualBuyerIdController.text.trim();
    if (purchaseId.isEmpty || buyerId.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ mã đơn và mã người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().setAcceptBuyer(
            purchaseId,
            buyerId,
            false,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đã từ chối đơn hàng $purchaseId');
      _manualPurchaseIdController.clear();
      _manualBuyerIdController.clear();
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleManualMarkShipped() async {
    final purchaseId = _manualPurchaseIdController.text.trim();
    final buyerId = _manualBuyerIdController.text.trim();
    if (purchaseId.isEmpty || buyerId.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ mã đơn và mã người mua');
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().sellerMarkAsShipped(
            purchaseId,
            buyerId: buyerId,
          );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Đơn hàng $purchaseId đã được đánh dấu vận chuyển');
      _manualPurchaseIdController.clear();
      _manualBuyerIdController.clear();
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
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
            const Text(
              'Thao tác thủ công',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
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
                    onPressed: _handleManualReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _handleManualAccept,
                    child: const Text('Chấp nhận'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _handleManualMarkShipped,
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('Xác nhận gửi hàng'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCard = widget.stateFilter == 'pending' || widget.stateFilter == 'confirmed';

    Widget content;

    if (_isLoading && _orders.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _orders.isEmpty) {
      content = ErrorState(
        message: _error!,
        onRetry: _refresh,
      );
    } else if (_orders.isEmpty) {
      content = const EmptyState(
        title: 'Chưa có đơn hàng nào',
        message: 'Các đơn hàng bạn bán sẽ hiển thị ở đây.',
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == _orders.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final order = _orders[index];
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
                  if (updated == true) {
                    _refresh();
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
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
                              order.items.isEmpty
                                  ? '0 sản phẩm'
                                  : '${order.items.length} sản phẩm',
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
                                onPressed: () => _handleReject(order),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                ),
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              ElevatedButton(
                                onPressed: () => _handleAccept(order),
                                child: const Text('Chấp nhận'),
                              ),
                            ] else if (order.status == 'confirmed') ...[
                              ElevatedButton.icon(
                                onPressed: () => _handleMarkShipped(order),
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
      isLoading: _isActionInProgress,
      child: content,
    );
  }
}
