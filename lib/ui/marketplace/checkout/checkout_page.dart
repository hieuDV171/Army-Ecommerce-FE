import 'package:army_ecommerce/blocs/marketplace/checkout/checkout_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/checkout/checkout_event.dart';
import 'package:army_ecommerce/blocs/marketplace/checkout/checkout_state.dart';
import 'package:army_ecommerce/core/services/cart_manager.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';
import '../../util/widgets/price_text.dart';
import '../../util/widgets/section_header.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItem> items;
  final int orderSource;

  const CheckoutPage({
    super.key,
    required this.items,
    this.orderSource = 0,
  });

  @override
  Widget build(BuildContext context) {
    final firstItemId = items.isNotEmpty ? int.tryParse(items.first.productId.split('-')[0]) : null;
    return BlocProvider(
      create: (context) => CheckoutBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(CheckoutRequested(productId: firstItemId)),
      child: _CheckoutView(items: items, orderSource: orderSource),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final List<CartItem> items;
  final int orderSource;

  const _CheckoutView({
    required this.items,
    required this.orderSource,
  });

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  void _showProductNotExistedDialog(BuildContext context) {
    final firstItemTitle = widget.items.isNotEmpty ? widget.items.first.title : '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thông báo'),
          content: Text('Sản phẩm "$firstItemTitle" không còn tồn tại.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Quay lại'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<num>(0, (sum, item) => sum + item.price * item.quantity);

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state.isProductNotExisted) {
          _showProductNotExistedDialog(context);
          return;
        }
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          AppSnackBar.show(context, message: message);
        }
        if (state.successMessage != null) {
          if (widget.orderSource == 0) {
            CartManager().clearCart();
          }
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final total = subtotal + state.shippingFee;
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Thanh toán')),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Đặt hàng',
                  icon: Icons.payment,
                  onPressed: () {
                    context.read<CheckoutBloc>().add(
                          CheckoutSubmitted(
                            items: widget.items,
                            orderSource: widget.orderSource,
                          ),
                        );
                  },
                ),
              ),
            ),
            body: _buildBody(context, state, subtotal, total),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState state, num subtotal, num total) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.addresses.isEmpty) {
      final firstItemId = widget.items.isNotEmpty ? int.tryParse(widget.items.first.productId) : null;
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<CheckoutBloc>().add(CheckoutRequested(productId: firstItemId)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionHeader(title: 'Địa chỉ nhận hàng'),
        const SizedBox(height: AppSpacing.sm),
        if (state.addresses.isEmpty)
          const EmptyState(
            title: 'Chưa có địa chỉ',
            message: 'Bạn cần thêm địa chỉ trước khi đặt hàng.',
          )
        else
          ...state.addresses.map(
            (address) => ListTile(
              onTap: () {
                context.read<CheckoutBloc>().add(CheckoutAddressSelected(address));
              },
              title: Text(address.title),
              subtitle: Text(address.subtitle),
              trailing: Icon(
                state.selectedAddress?.id == address.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: state.selectedAddress?.id == address.id
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Sản phẩm'),
        const SizedBox(height: AppSpacing.sm),
        ...widget.items.map((item) => _CheckoutItemTile(item: item)),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tạm tính'),
            PriceText(price: subtotal),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phí vận chuyển'),
                if (state.leatime != null)
                  Text(
                    'Dự kiến giao: ${state.leatime} ngày',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            PriceText(price: state.shippingFee),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PriceText(price: total),
          ],
        ),
      ],
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  final CartItem item;

  const _CheckoutItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? NetworkImage(item.imageUrl!)
            : null,
        child: item.imageUrl == null || item.imageUrl!.isEmpty
            ? const Icon(Icons.inventory_2_outlined)
            : null,
      ),
      title: Text(item.title),
      subtitle: PriceText(price: item.price),
      trailing: Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
