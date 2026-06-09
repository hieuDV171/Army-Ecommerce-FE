import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';
import '../util/widgets/loading_overlay.dart';
import '../util/widgets/price_text.dart';
import '../util/widgets/section_header.dart';
import '../util/widgets/status_chip.dart';

class BuyerOrdersPage extends StatelessWidget {
  const BuyerOrdersPage({super.key});

  static const _tabs = [
    ('Tất cả', null),
    ('Chờ xử lý', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Đã nhận', 'delivered'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã nhận'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _tabs) _BuyerOrderList(stateFilter: tab.$2),
          ],
        ),
      ),
    );
  }
}

class _BuyerOrderList extends StatefulWidget {
  final String? stateFilter;

  const _BuyerOrderList({required this.stateFilter});

  @override
  State<_BuyerOrderList> createState() => _BuyerOrderListState();
}

class _BuyerOrderListState extends State<_BuyerOrderList> {
  Future<List<OrderModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderModel>> _load() {
    return context.read<MarketplaceRepository>().getOrders(
          state: widget.stateFilter,
          index: 0,
          count: 20,
        );
  }

  Future<void> _refresh() async {
    final newFuture = _load();
    setState(() {
      _future = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderModel>>(
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
            title: 'Chưa có đơn hàng',
            message: 'Các đơn hàng bạn đã đặt sẽ hiển thị ở đây.',
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
              return _OrderCard(
                order: order,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerOrderDetailPage(orderId: order.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = order.finalPrice > 0 ? order.finalPrice : order.total;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
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
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
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
                    label: _statusLabel(order.status),
                    color: _statusColor(order.status),
                    icon: _statusIcon(order.status),
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
                  PriceText(price: total),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyerOrderDetailPage extends StatefulWidget {
  final String orderId;

  const BuyerOrderDetailPage({super.key, required this.orderId});

  @override
  State<BuyerOrderDetailPage> createState() => _BuyerOrderDetailPageState();
}

class _BuyerOrderDetailPageState extends State<BuyerOrderDetailPage> {
  Future<OrderModel?>? _detailFuture;
  Future<List<OrderTimelineModel>>? _timelineFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repository = context.read<MarketplaceRepository>();
    _detailFuture = repository.getOrderDetail(widget.orderId);
    _timelineFuture = repository.getOrderTimeline(widget.orderId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([
      _detailFuture ?? Future.value(null),
      _timelineFuture ?? Future.value(const <OrderTimelineModel>[]),
    ]);
  }

  Future<void> _submit(Future<void> Function() action, {String successMessage = 'Đã cập nhật đơn hàng'}) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      setState(_load);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
            body: ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            ),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
            body: const EmptyState(
              title: 'Không tìm thấy đơn hàng',
              message: 'Đơn hàng không tồn tại hoặc bạn không có quyền xem.',
            ),
          );
        }

        return LoadingOverlay(
          isLoading: _isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Đơn #${order.id}'),
              actions: [
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildHeader(order),
                  const SizedBox(height: AppSpacing.lg),
                  _buildOverview(order),
                  const SizedBox(height: AppSpacing.lg),
                  _buildItems(order),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTimeline(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActions(order),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Card(
      elevation: 1,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: _statusLabel(order.status),
                  color: _statusColor(order.status),
                  icon: _statusIcon(order.status),
                ),
                const Spacer(),
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if ((order.createdAt ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tạo lúc: ${order.createdAt}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if ((order.sellerName ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Người bán: ${order.sellerName}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(OrderModel order) {
    final finalPrice = order.finalPrice > 0 ? order.finalPrice : (order.total + order.shipFee);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Thông tin đơn hàng'),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'Tổng tiền hàng', value: order.total),
            _InfoRow(label: 'Phí vận chuyển', value: order.shipFee),
            _InfoRow(label: 'Thanh toán cuối', value: finalPrice),
            if ((order.buyerName ?? '').isNotEmpty)
              _TextInfoRow(label: 'Người mua', value: order.buyerName!),
            if ((order.buyerPhone ?? '').isNotEmpty)
              _TextInfoRow(label: 'Số điện thoại', value: order.buyerPhone!),
            if ((order.buyerAddress ?? '').isNotEmpty)
              _TextInfoRow(label: 'Địa chỉ nhận', value: order.buyerAddress!),
            if ((order.note ?? '').isNotEmpty)
              _TextInfoRow(label: 'Ghi chú', value: order.note!),
          ],
        ),
      ),
    );
  }

  Widget _buildItems(OrderModel order) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Sản phẩm trong đơn'),
            const SizedBox(height: AppSpacing.md),
            if (order.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Không có dữ liệu sản phẩm.'),
              )
            else
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OrderItemTile(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Lịch sử đơn hàng'),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<OrderTimelineModel>>(
              future: _timelineFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                final timelines = snapshot.data ?? const <OrderTimelineModel>[];
                if (timelines.isEmpty) {
                  return const Text('Chưa có lịch sử thay đổi trạng thái.');
                }
                return Column(
                  children: timelines
                      .map(
                        (timeline) => _TimelineTile(
                          timeline: timeline,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(OrderModel order) {
    if (_isCancelable(order.status) || _isEditable(order.status)) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Thao tác đơn hàng'),
              const SizedBox(height: AppSpacing.md),
              if (_isEditable(order.status)) ...[
                AppButton(
                  label: 'Chỉnh sửa đơn hàng',
                  icon: Icons.edit_outlined,
                  onPressed: () => _openEditSheet(order),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_isCancelable(order.status)) ...[
                OutlinedButton.icon(
                  onPressed: () => _openCancelDialog(order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn hàng'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (order.status == 'shipping') ...[
                AppButton(
                  label: 'Xác nhận đã nhận hàng',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _confirmReceived(order),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (order.status == 'delivered') ...[
                AppButton(
                  label: 'Yêu cầu hoàn tiền / hoàn hàng',
                  icon: Icons.restart_alt,
                  onPressed: () => _openRefundDialog(order),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (order.status == 'shipping') {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Xác nhận đã nhận hàng',
            icon: Icons.check_circle_outline,
            onPressed: () => _confirmReceived(order),
          ),
        ),
      );
    }

    if (order.status == 'delivered') {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Yêu cầu hoàn tiền / hoàn hàng',
            icon: Icons.restart_alt,
            onPressed: () => _openRefundDialog(order),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isEditable(String status) => status == 'pending' || status == 'confirmed';

  bool _isCancelable(String status) => status == 'pending' || status == 'confirmed';

  Future<void> _confirmReceived(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng'),
        content: const Text('Bạn chắc chắn đã nhận được đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _submit(
      () => context.read<MarketplaceRepository>().confirmReceived(order.id),
      successMessage: 'Đã xác nhận đã nhận hàng',
    );
  }

  Future<void> _openRefundDialog(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _RefundDialog(),
    );

    if (reason == null) return;

    await _submit(
      () => context.read<MarketplaceRepository>().refundOrder(
            order.id,
            reason: reason.isEmpty ? null : reason,
          ),
      successMessage: 'Đã gửi yêu cầu hoàn tiền / hoàn hàng',
    );
  }

  Future<void> _openCancelDialog(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CancelDialog(),
    );

    if (reason == null) return;

    await _submit(
      () => context.read<MarketplaceRepository>().cancelOrder(
            order.id,
            reason: reason.isEmpty ? null : reason,
          ),
      successMessage: 'Đã hủy đơn hàng',
    );
  }

  Future<void> _openEditSheet(OrderModel order) async {
    final repository = context.read<MarketplaceRepository>();
    final addresses = await repository.getAddresses();
    if (!mounted) return;

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần có ít nhất 1 địa chỉ để chỉnh sửa đơn hàng')),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _EditOrderSheet(
        order: order,
        addresses: addresses,
      ),
    );

    if (result == null) return;

    await _submit(
      () => repository.editOrder(order.id, result),
      successMessage: 'Đã cập nhật địa chỉ / ghi chú',
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderLineItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderItemImage(imageUrl: item.imageUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'SL: ${item.quantity}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              PriceText(price: item.price),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          item.subtotal.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OrderItemImage extends StatelessWidget {
  final String? imageUrl;

  const _OrderItemImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.surface,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              )
            : const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final OrderTimelineModel timeline;

  const _TimelineTile({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: _statusColor(timeline.state).withValues(alpha: 0.12),
            child: Icon(
              _statusIcon(timeline.state),
              size: 16,
              color: _statusColor(timeline.state),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(timeline.state),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((timeline.message ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(timeline.message!),
                ],
                if ((timeline.time ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeline.time!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final num value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          PriceText(price: value),
        ],
      ),
    );
  }
}

class _TextInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _TextInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Chờ xử lý';
    case 'confirmed':
      return 'Đã xác nhận';
    case 'shipping':
      return 'Đang giao';
    case 'delivered':
      return 'Đã nhận';
    case 'cancelled':
      return 'Đã hủy';
    case 'refunded':
      return 'Hoàn tiền';
    default:
      return status.isEmpty ? 'Không rõ' : status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'confirmed':
      return AppColors.primary;
    case 'shipping':
      return AppColors.info;
    case 'delivered':
      return AppColors.success;
    case 'cancelled':
      return AppColors.danger;
    case 'refunded':
      return AppColors.purple;
    default:
      return AppColors.textSecondary;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_top;
    case 'confirmed':
      return Icons.verified_outlined;
    case 'shipping':
      return Icons.local_shipping_outlined;
    case 'delivered':
      return Icons.check_circle_outline;
    case 'cancelled':
      return Icons.cancel_outlined;
    case 'refunded':
      return Icons.restart_alt;
    default:
      return Icons.receipt_long_outlined;
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hủy đơn hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _reasonCtrl,
              label: 'Lý do hủy',
              hint: 'Không bắt buộc',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Không'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reasonCtrl.text.trim()),
          child: const Text('Hủy đơn'),
        ),
      ],
    );
  }
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog();

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yêu cầu hoàn tiền / hoàn hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _reasonCtrl,
              label: 'Lý do hoàn hàng/hoàn tiền',
              hint: 'Nhập lý do nếu có',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reasonCtrl.text.trim()),
          child: const Text('Gửi yêu cầu'),
        ),
      ],
    );
  }
}

class _EditOrderSheet extends StatefulWidget {
  final OrderModel order;
  final List<AddressModel> addresses;

  const _EditOrderSheet({
    required this.order,
    required this.addresses,
  });

  @override
  State<_EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends State<_EditOrderSheet> {
  late final TextEditingController _noteCtrl;
  late String _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.order.note ?? '');
    _selectedAddressId = widget.addresses.first.id;

    if (widget.order.buyerAddress != null && widget.order.buyerAddress!.isNotEmpty) {
      for (final address in widget.addresses) {
        if (address.fullAddress == widget.order.buyerAddress) {
          _selectedAddressId = address.id;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chỉnh sửa đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _selectedAddressId,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                border: OutlineInputBorder(),
              ),
              items: widget.addresses
                  .map(
                    (address) => DropdownMenuItem<String>(
                      value: address.id,
                      child: Text(
                        '${address.receiverName} • ${address.fullAddress}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedAddressId = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _noteCtrl,
              label: 'Ghi chú đơn hàng',
              hint: 'Ví dụ: Giao buổi chiều',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Lưu thay đổi',
              icon: Icons.save_outlined,
              onPressed: () {
                Navigator.pop(context, {
                  'address_id': _selectedAddressId,
                  'note': _noteCtrl.text.trim(),
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SELLER ORDERS PAGES
// ──────────────────────────────────────────────────────────────────────────────

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

    // Fetch all orders
    final allOrders = await repository.getOrders(index: 0, count: 100);

    // Fetch details for all orders in parallel to get full buyer/seller info
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

    // Filter to only those where the current user is the seller
    final sellerOrders = detailedOrders.where((order) {
      final isSeller = order.sellerId?.toString() == currentUserId?.toString() ||
          (order.sellerName != null && order.sellerName == currentUsername);
      if (!isSeller) return false;

      // Now filter by state
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
                                label: _statusLabel(order.status),
                                color: _statusColor(order.status),
                                icon: _statusIcon(order.status),
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

class SellerOrderDetailPage extends StatefulWidget {
  final String orderId;

  const SellerOrderDetailPage({super.key, required this.orderId});

  @override
  State<SellerOrderDetailPage> createState() => _SellerOrderDetailPageState();
}

class _SellerOrderDetailPageState extends State<SellerOrderDetailPage> {
  Future<OrderModel?>? _detailFuture;
  Future<List<OrderTimelineModel>>? _timelineFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repository = context.read<MarketplaceRepository>();
    _detailFuture = repository.getOrderDetail(widget.orderId);
    _timelineFuture = repository.getOrderTimeline(widget.orderId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([
      _detailFuture ?? Future.value(null),
      _timelineFuture ?? Future.value(const <OrderTimelineModel>[]),
    ]);
  }

  Future<void> _submit(Future<void> Function() action, {String successMessage = 'Đã cập nhật đơn hàng'}) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      setState(_load);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleAccept(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
      return;
    }
    await _submit(
      () => context.read<MarketplaceRepository>().setAcceptBuyer(
            order.id,
            order.buyerId!,
            true,
          ),
      successMessage: 'Đã chấp nhận đơn hàng',
    );
  }

  Future<void> _handleReject(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
      return;
    }
    await _submit(
      () => context.read<MarketplaceRepository>().setAcceptBuyer(
            order.id,
            order.buyerId!,
            false,
          ),
      successMessage: 'Đã từ chối đơn hàng',
    );
  }

  Future<void> _handleMarkShipped(OrderModel order) async {
    if (order.buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID người mua')),
      );
      return;
    }
    await _submit(
      () => context.read<MarketplaceRepository>().sellerMarkAsShipped(
            order.id,
            buyerId: order.buyerId,
          ),
      successMessage: 'Đơn hàng đã được đánh dấu vận chuyển',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đơn bán')),
            body: ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            ),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đơn bán')),
            body: const EmptyState(
              title: 'Không tìm thấy đơn hàng',
              message: 'Đơn hàng không tồn tại hoặc bạn không có quyền xem.',
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pop(context, true);
          },
          child: LoadingOverlay(
            isLoading: _isSubmitting,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Đơn bán #${order.id}'),
                actions: [
                  IconButton(
                    tooltip: 'Làm mới',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Card(
                      elevation: 1,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(
                                  label: _statusLabel(order.status),
                                  color: _statusColor(order.status),
                                  icon: _statusIcon(order.status),
                                ),
                                const Spacer(),
                                Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if ((order.createdAt ?? '').isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tạo lúc: ${order.createdAt}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                            if ((order.buyerName ?? '').isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Người mua: ${order.buyerName}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Thông tin đơn hàng'),
                            const SizedBox(height: AppSpacing.md),
                            _InfoRow(label: 'Tổng tiền hàng', value: order.total),
                            _InfoRow(label: 'Phí vận chuyển', value: order.shipFee),
                            _InfoRow(
                              label: 'Tổng cộng',
                              value: order.finalPrice > 0 ? order.finalPrice : (order.total + order.shipFee),
                            ),
                            if ((order.buyerName ?? '').isNotEmpty)
                              _TextInfoRow(label: 'Người nhận', value: order.buyerName!),
                            if ((order.buyerPhone ?? '').isNotEmpty)
                              _TextInfoRow(label: 'Số điện thoại', value: order.buyerPhone!),
                            if ((order.buyerAddress ?? '').isNotEmpty)
                              _TextInfoRow(label: 'Địa chỉ nhận', value: order.buyerAddress!),
                            if ((order.note ?? '').isNotEmpty)
                              _TextInfoRow(label: 'Ghi chú', value: order.note!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Sản phẩm trong đơn'),
                            const SizedBox(height: AppSpacing.md),
                            if (order.items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Text('Không có dữ liệu sản phẩm.'),
                              )
                            else
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: _OrderItemTile(item: item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Lịch sử đơn hàng'),
                            const SizedBox(height: AppSpacing.md),
                            FutureBuilder<List<OrderTimelineModel>>(
                              future: _timelineFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return ErrorState(
                                    message: snapshot.error.toString(),
                                    onRetry: _refresh,
                                  );
                                }
                                final timelines = snapshot.data ?? const <OrderTimelineModel>[];
                                if (timelines.isEmpty) {
                                  return const Text('Chưa có lịch sử thay đổi trạng thái.');
                                }
                                return Column(
                                  children: timelines
                                      .map(
                                        (timeline) => _TimelineTile(
                                          timeline: timeline,
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (order.status == 'pending' || order.status == 'confirmed') ...[
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(title: 'Thao tác đơn hàng'),
                              const SizedBox(height: AppSpacing.md),
                              if (order.status == 'pending') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _handleReject(order),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Từ chối'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(color: AppColors.danger),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _handleAccept(order),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Chấp nhận'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (order.status == 'confirmed') ...[
                                AppButton(
                                  label: 'Xác nhận gửi hàng',
                                  icon: Icons.local_shipping_outlined,
                                  onPressed: () => _handleMarkShipped(order),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



