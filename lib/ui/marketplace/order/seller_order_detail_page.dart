import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
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
import '../product/product_detail_page.dart';

import 'package:army_ecommerce/blocs/marketplace/order/order_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_event.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_state.dart';

class SellerOrderDetailPage extends StatelessWidget {
  final String orderId;

  const SellerOrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(OrderDetailRequested(orderId)),
      child: _SellerOrderDetailView(orderId: orderId),
    );
  }
}

class _SellerOrderDetailView extends StatefulWidget {
  final String orderId;

  const _SellerOrderDetailView({required this.orderId});

  @override
  State<_SellerOrderDetailView> createState() => _SellerOrderDetailViewState();
}

class _SellerOrderDetailViewState extends State<_SellerOrderDetailView> {
  bool _shouldRefreshOnPop = false;

  void _submitAction(OrderModel order, OrderActionType actionType) {
    context.read<OrderBloc>().add(
          OrderActionRequested(
            order: order,
            actionType: actionType,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          _shouldRefreshOnPop = true;
          AppSnackBar.showSuccess(context, message: state.successMessage!);
          context.read<OrderBloc>().add(OrderDetailRequested(widget.orderId));
        } else if (state.errorMessage != null) {
          AppSnackBar.showError(context, message: state.errorMessage!);
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state.isDetailLoading && state.orderDetail == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (state.errorMessage != null && state.orderDetail == null) {
            final errorMsg = state.errorMessage!;
            final isPermissionError = errorMsg.contains('Parameter value is invalid') || errorMsg.contains('1002');
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết đơn bán')),
              body: ErrorState(
                message: isPermissionError
                    ? 'Do giới hạn phân quyền phía server, thông tin chi tiết đơn bán chỉ có thể được xem bởi Người mua. Người bán vui lòng sử dụng tính năng "Thao tác thủ công" ở màn hình danh sách bên ngoài.'
                    : errorMsg,
                onRetry: () {
                  context.read<OrderBloc>().add(OrderDetailRequested(widget.orderId));
                },
              ),
            );
          }

          final order = state.orderDetail;
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
              Navigator.pop(context, _shouldRefreshOnPop);
            },
            child: LoadingOverlay(
              isLoading: state.isActionInProgress,
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Đơn bán #${order.id}'),
                  actions: [
                    IconButton(
                      tooltip: 'Làm mới',
                      onPressed: () {
                        context.read<OrderBloc>().add(OrderDetailRequested(widget.orderId));
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
                      _buildActions(order),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
    );
  }

  Widget _buildOverview(OrderModel order) {
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
                    .map(
                      (timeline) => _TimelineTile(
                        timeline: timeline,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(OrderModel order) {
    if (order.status == 'pending' || order.status == 'confirmed') {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Card(
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
                          onPressed: () => _submitAction(order, OrderActionType.reject),
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
                          onPressed: () => _submitAction(order, OrderActionType.accept),
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
                    onPressed: () => _submitAction(order, OrderActionType.ship),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderLineItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: context.specialTheme.primaryColor.withValues(
        alpha: 0.15,
      ),
      highlightColor: context.specialTheme.primaryColor.withValues(
        alpha: 0.05,
      ),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '${item.quantity} sản phẩm',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(height: 1, thickness: 1, color: AppColors.border),
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
