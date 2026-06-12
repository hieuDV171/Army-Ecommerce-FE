import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/models/order_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';
import '../../util/widgets/price_text.dart';
import '../../util/widgets/section_header.dart';
import '../../util/widgets/status_chip.dart';
import 'widgets/order_card.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

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
      AppSnackBar.showSuccess(context, message: successMessage);
      setState(_load);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleAccept(OrderModel order) async {
    if (order.buyerId == null) {
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
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
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
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
      AppSnackBar.showError(context, message: 'Không tìm thấy ID người mua');
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
                                  label: statusLabel(order.status),
                                  color: statusColor(order.status),
                                  icon: statusIcon(order.status),
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
            backgroundColor: statusColor(timeline.state).withValues(alpha: 0.12),
            child: Icon(
              statusIcon(timeline.state),
              size: 16,
              color: statusColor(timeline.state),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel(timeline.state),
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
