import 'package:army_ecommerce/models/order_model.dart';
import 'package:flutter/material.dart';
import '../../../util/constants/app_colors.dart';
import '../../../util/constants/app_radius.dart';
import '../../../util/constants/app_spacing.dart';
import '../../../util/widgets/price_text.dart';
import '../../../util/widgets/status_chip.dart';

String statusLabel(String status) {
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

Color statusColor(String status) {
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

IconData statusIcon(String status) {
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

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

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
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if ((order.createdAt ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            order.createdAt!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
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
