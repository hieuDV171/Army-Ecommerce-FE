import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
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

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  static const _tabs = [
    ('Tất cả', null),
    ('Chờ xác nhận', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Đã giao', 'delivered'),
    ('Đã hủy / Hoàn tiền', 'cancelled_refunded'),
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
              Tab(text: 'Hủy/Hoàn tiền'),
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
  Future<List<OrderModel>>? _future;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderModel>> _load() async {
    final repository = context.read<MarketplaceRepository>();
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id;
    final currentUsername = authState.currentUser?.username;

    final allOrders = await repository.getOrders(index: 0, count: 100);

    final detailedOrders = await Future.wait(
      allOrders.map((order) async {
        try {
          final detail = await repository.getOrderDetail(order.id);
          return detail ?? order;
        } catch (_) {
          return order;
        }
      }),
    );

    final sellerOrders = detailedOrders.where((order) {
      final isSeller = order.sellerId?.toString() == currentUserId?.toString() ||
          (order.sellerName != null && order.sellerName == currentUsername);
      if (!isSeller) return false;

      if (widget.stateFilter == null) return true;
      if (widget.stateFilter == 'cancelled_refunded') {
        return order.status == 'cancelled' || order.status == 'refunded';
      }
      return order.status == widget.stateFilter;
    }).toList();

    return sellerOrders;
  }

  Future<void> _refresh() async {
    final newFuture = _load();
    setState(() {
      _future = newFuture;
    });
    await newFuture;
  }

  Future<void> _handleAccept(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận đơn hàng')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleReject(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối đơn hàng')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleMarkShipped(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await context.read<MarketplaceRepository>().sellerMarkAsShipped(
            order.id,
            buyerId: order.buyerId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được đánh dấu vận chuyển')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isActionInProgress,
      child: FutureBuilder<List<OrderModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final orders = snapshot.data ?? const <OrderModel>[];
          if (orders.isEmpty) {
            return const EmptyState(
              title: 'Chưa có đơn hàng nào',
              message: 'Các đơn hàng bạn bán sẽ hiển thị ở đây.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final order = orders[index];
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
        },
      ),
    );
  }
}
