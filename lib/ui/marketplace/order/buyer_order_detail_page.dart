import 'package:army_ecommerce/models/address_model.dart';
import 'package:army_ecommerce/models/order_model.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import '../../../core/services/session_manager.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/app_text_field.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';
import '../../util/widgets/price_text.dart';
import '../../util/widgets/section_header.dart';
import '../../util/widgets/status_chip.dart';
import 'widgets/order_card.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';
import '../product/product_detail_page.dart';

import 'package:army_ecommerce/blocs/marketplace/order/order_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_event.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_state.dart';

class BuyerOrderDetailPage extends StatelessWidget {
  final String orderId;
  final VoidCallback? onRefresh;

  const BuyerOrderDetailPage({super.key, required this.orderId, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(OrderDetailRequested(orderId)),
      child: _BuyerOrderDetailView(orderId: orderId, onRefresh: onRefresh),
    );
  }
}

class _BuyerOrderDetailView extends StatefulWidget {
  final String orderId;
  final VoidCallback? onRefresh;

  const _BuyerOrderDetailView({required this.orderId, this.onRefresh});

  @override
  State<_BuyerOrderDetailView> createState() => _BuyerOrderDetailViewState();
}

class _BuyerOrderDetailViewState extends State<_BuyerOrderDetailView> {
  bool _isAlreadyEdited = false;
  bool _shouldRefreshOnPop = false;

  @override
  void initState() {
    super.initState();
    SessionManager.isOrderEdited(widget.orderId).then((edited) {
      if (mounted) {
        setState(() {
          _isAlreadyEdited = edited;
        });
      }
    });
  }

  void _submitAction(
    OrderModel order,
    OrderActionType actionType, {
    String? reason,
  }) {
    context.read<OrderBloc>().add(
      OrderActionRequested(
        order: order,
        actionType: actionType,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _shouldRefreshOnPop && result != true) {
          // Refresh callback handled on pop
        }
      },
      child: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            _shouldRefreshOnPop = true;
            AppSnackBar.show(context, message: state.successMessage!);

            final isConfirmReceived = state.successMessage == 'Đã xác nhận đã nhận hàng';
            final orderToReview = state.orderDetail;

            // Refresh details & timeline
            context.read<OrderBloc>().add(OrderDetailRequested(widget.orderId));
            widget.onRefresh?.call();
            SessionManager.isOrderEdited(widget.orderId).then((edited) {
              if (mounted) {
                setState(() {
                  _isAlreadyEdited = edited;
                });
              }
            });

            if (isConfirmReceived && orderToReview != null) {
              _showReviewDialog(orderToReview);
            }
          } else if (state.errorMessage != null) {
            AppSnackBar.showError(context, message: state.errorMessage!);
          }
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state.isDetailLoading && state.orderDetail == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.errorMessage != null && state.orderDetail == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
                body: ErrorState(
                  message: state.errorMessage!,
                  onRetry: () {
                    context.read<OrderBloc>().add(
                      OrderDetailRequested(widget.orderId),
                    );
                  },
                ),
              );
            }

            final order = state.orderDetail;
            if (order == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
                body: const EmptyState(
                  title: 'Không tìm thấy đơn hàng',
                  message:
                      'Đơn hàng không tồn tại hoặc bạn không có quyền xem.',
                ),
              );
            }

            return LoadingOverlay(
              isLoading: state.isActionInProgress,
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Đơn #${order.id}'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        Navigator.pop(context, _shouldRefreshOnPop),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Làm mới',
                      onPressed: () {
                        context.read<OrderBloc>().add(
                          OrderDetailRequested(widget.orderId),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                body: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<OrderBloc>();
                    bloc.add(OrderDetailRequested(widget.orderId));
                    await bloc.stream.firstWhere((s) => !s.isDetailLoading);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _buildHeader(order),
                      const SizedBox(height: AppSpacing.lg),
                      _buildOverview(order),
                      const SizedBox(height: AppSpacing.lg),
                      _buildItems(order),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTimeline(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildActions(order),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
    final finalPrice = order.finalPrice > 0
        ? order.finalPrice
        : (order.total + order.shipFee);

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

  Widget _buildTimeline(OrderState state) {
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
            if (state.timeline.isEmpty)
              const Text('Chưa có lịch sử thay đổi trạng thái.')
            else
              Column(
                children: state.timeline
                    .map((timeline) => _TimelineTile(timeline: timeline))
                    .toList(),
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
                  onPressed: (order.status == 'confirmed' && _isAlreadyEdited)
                      ? null
                      : () => _openEditSheet(order),
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
              if (order.status == 'confirmed') ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    _isAlreadyEdited
                        ? 'Bạn đã chỉnh sửa đơn hàng đã xác nhận này rồi (chỉ được sửa 1 lần)'
                        : 'Lưu ý: Đơn hàng đã xác nhận chỉ có thể chỉnh sửa địa chỉ/ghi chú 1 lần duy nhất',
                    style: TextStyle(
                      color: _isAlreadyEdited
                          ? Colors.redAccent
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                  label: 'Viết đánh giá',
                  icon: Icons.rate_review_outlined,
                  onPressed: () => _showReviewDialog(order),
                ),
                const SizedBox(height: AppSpacing.sm),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: 'Viết đánh giá',
                icon: Icons.rate_review_outlined,
                onPressed: () => _showReviewDialog(order),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Yêu cầu hoàn tiền / hoàn hàng',
                icon: Icons.restart_alt,
                onPressed: () => _openRefundDialog(order),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isEditable(String status) =>
      status == 'pending' || status == 'confirmed';

  bool _isCancelable(String status) =>
      status == 'pending' || status == 'confirmed';

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

    _submitAction(order, OrderActionType.confirmReceived);
  }

  Future<void> _showReviewDialog(OrderModel order) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ReviewDialog(order: order),
    );
    if (result == true && mounted) {
      context.read<OrderBloc>().add(OrderDetailRequested(widget.orderId));
    }
  }

  Future<void> _openRefundDialog(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _RefundDialog(),
    );

    if (reason == null) return;

    _submitAction(
      order,
      OrderActionType.refund,
      reason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _openCancelDialog(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CancelDialog(),
    );

    if (reason == null) return;

    _submitAction(
      order,
      OrderActionType.cancel,
      reason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _openEditSheet(OrderModel order) async {
    final repository = context.read<MarketplaceRepository>();
    final addresses = await repository.getAddresses();
    if (!mounted) return;

    if (addresses.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Bạn cần có ít nhất 1 địa chỉ để chỉnh sửa đơn hàng',
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _EditOrderSheet(order: order, addresses: addresses),
    );

    if (result == null) return;

    if (!mounted) return;
    context.read<OrderBloc>().add(
      OrderEditRequested(orderId: order.id, data: result),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderLineItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: context.specialTheme.primaryColor.withValues(alpha: 0.15),
      highlightColor: context.specialTheme.primaryColor.withValues(alpha: 0.05),
      onTap: () {
        final rawId = item.productId;
        final cleanId = rawId.split('-').first;
        if (cleanId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: cleanId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giá:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    PriceText(
                      price: item.price,
                      suffix: 'xu/sản phẩm',
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'x SL:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${item.quantity} sản phẩm',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thành tiền:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    PriceText(
                      price: item.subtotal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
                errorBuilder: (_, _, _) => const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.textSecondary,
                ),
              )
            : const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textSecondary,
              ),
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
            backgroundColor: statusColor(
              timeline.state,
            ).withValues(alpha: 0.12),
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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

  const _EditOrderSheet({required this.order, required this.addresses});

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

    if (widget.order.buyerAddress != null &&
        widget.order.buyerAddress!.isNotEmpty) {
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

class _ReviewDialog extends StatefulWidget {
  final OrderModel order;

  const _ReviewDialog({required this.order});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final ValueNotifier<int> _levelNotifier = ValueNotifier<int>(5);
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _levelNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.currentUser?.id ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Cảm ơn bạn đã nhận hàng.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Hãy viết đánh giá đến người bán nhé!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Đánh giá chất lượng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<int>(
              valueListenable: _levelNotifier,
              builder: (context, level, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    iconSize: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      level >= star
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                    onPressed: () => _levelNotifier.value = star,
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nội dung đánh giá',
                hintText: 'Chia sẻ trải nghiệm của bạn về dịch vụ...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Gửi đánh giá',
                isLoading: _isSubmitting,
                onPressed: () async {
                  if (userId.isEmpty) {
                    AppSnackBar.show(
                      context,
                      message: 'Bạn cần đăng nhập để đánh giá',
                    );
                    return;
                  }
                  final level = _levelNotifier.value;
                  final content = _controller.text.trim();

                  setState(() => _isSubmitting = true);
                  try {
                    await context.read<MarketplaceRepository>().setRates(
                      userId: widget.order.sellerId ?? '',
                      level: level,
                      content: content,
                      productId: widget.order.items.isNotEmpty
                          ? widget.order.items.first.productId
                          : null,
                      purchaseId: widget.order.id,
                    );
                    if (!context.mounted) return;
                    AppSnackBar.showSuccess(
                      context,
                      message: 'Đã gửi đánh giá thành công',
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    AppSnackBar.showError(
                      context,
                      message: 'Lỗi gửi đánh giá: $e',
                    );
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
