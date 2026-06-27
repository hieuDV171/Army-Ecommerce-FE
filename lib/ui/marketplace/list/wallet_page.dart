import 'package:army_ecommerce/ui/util/widgets/price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/wallet/wallet_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/wallet/wallet_event.dart';
import 'package:army_ecommerce/blocs/marketplace/wallet/wallet_state.dart';
import 'package:army_ecommerce/models/wallet_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:intl/intl.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/section_header.dart';
import '../../util/theme/special_app_theme.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(WalletRequested()),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  void _showTransactionDetails(BuildContext context, WalletHistoryModel item) {
    final isPositive = _isPositiveTransaction(item);
    final absBalance = item.balance.abs();
    final formattedBalance = NumberFormat.decimalPattern(
      'vi_VN',
    ).format(absBalance);
    final balanceText = '${isPositive ? "+" : "-"}$formattedBalance xu';
    final balanceColor = isPositive ? AppColors.success : AppColors.danger;

    String displayDate = item.date;
    try {
      final dt = DateTime.parse(item.date);
      displayDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dt.toLocal());
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(
                    child: Text(
                      'Chi tiết giao dịch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      balanceText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow('Mã giao dịch (ID)', '#${item.historyId}'),
                  _buildDetailRow(
                    'Mã đối tượng',
                    item.objectId.isNotEmpty ? item.objectId : 'Không có',
                  ),
                  _buildDetailRow(
                    'Nội dung chi tiết',
                    item.detail.isNotEmpty ? item.detail : 'Không có chi tiết',
                  ),
                  _buildDetailRow(
                    'Loại giao dịch',
                    item.type == 'income'
                        ? 'Cộng xu (Income)'
                        : 'Trừ xu (Expense)',
                  ),
                  _buildDetailRow('Thời gian', displayDate),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: context.specialTheme.useGradient
                          ? context.specialTheme.primaryGradient
                          : null,
                      color: context.specialTheme.useGradient
                          ? null
                          : context.specialTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Xác định giao dịch là cộng (+) hay trừ (-) xu.
  /// Ưu tiên theo `type` từ BE; chỉ fallback theo dấu số dư khi type rỗng/lạ.
  static bool _isPositiveTransaction(WalletHistoryModel item) {
    switch (item.type) {
      case 'income':
        return true;
      case 'expense':
        return false;
      default:
        return item.balance >= 0;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ví quân nhu')),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
              ? ErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      context.read<WalletBloc>().add(WalletRequested()),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200 &&
                        state.hasMore &&
                        !state.isLoadingMore) {
                      context
                          .read<WalletBloc>()
                          .add(WalletLoadMoreRequested());
                    }
                    return false;
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: context.specialTheme.useGradient
                              ? context.specialTheme.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppColors.tactical,
                                    context.specialTheme.primaryColor
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số dư khả dụng',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PriceText(
                              price: state.balance?.available ?? 0,
                              color: Colors.white,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Đang chờ: ${state.balance?.pending ?? 0}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Lịch sử số dư'),
                      ...state.history.map((item) {
                        final isPositive = _isPositiveTransaction(item);
                        final absBalance = item.balance.abs();
                        final formattedBalance = NumberFormat.decimalPattern(
                          'vi_VN',
                        ).format(absBalance);
                        final balanceText =
                            '${isPositive ? "+" : "-"}$formattedBalance xu';
                        final balanceColor = isPositive
                            ? AppColors.success
                            : AppColors.danger;

                        String displayDate = item.date;
                        try {
                          final dt = DateTime.parse(item.date);
                          displayDate = DateFormat(
                            'dd/MM/yyyy HH:mm:ss',
                          ).format(dt.toLocal());
                        } catch (_) {}

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(displayDate),
                          trailing: Text(
                            balanceText,
                            style: TextStyle(
                              color: balanceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          onTap: () => _showTransactionDetails(context, item),
                        );
                      }),
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (!state.hasMore && state.history.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: Text(
                              'Đã hiển thị tất cả giao dịch',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
