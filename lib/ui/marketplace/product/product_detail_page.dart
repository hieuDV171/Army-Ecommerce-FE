import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_event.dart';
import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_state.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/ui/util/widgets/login_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';

import 'package:army_ecommerce/core/services/cart_manager.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/theme/app_text_styles.dart';
import '../../util/widgets/app_bottom_sheet.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/app_text_field.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';
import '../../util/widgets/price_text.dart';
import '../../util/widgets/rating_stars.dart';
import '../../util/widgets/section_header.dart';
import '../../util/widgets/shimmer_box.dart';
import '../product_form_page.dart';
import 'seller_listings_page.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductDetailBloc(
            marketplaceRepository: context.read<MarketplaceRepository>(),
          )..add(ProductDetailRequested(productId)),
        ),
        // ChatBloc riêng cho trang sản phẩm — dùng khi nhấn nút Chat với người bán
        BlocProvider(
          create: (context) => ChatBloc(
            marketplaceRepository: context.read<MarketplaceRepository>(),
          ),
        ),
      ],
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _collectDisplayImages(ProductModel product) {
    if (product.images.isNotEmpty) {
      return product.images
          .map((item) => item.url)
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return product.imageUrls.where((url) => url.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final product = state.product;
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: context.specialTheme.useGradient ? Colors.transparent : context.specialTheme.primaryDarkColor,
              flexibleSpace: context.specialTheme.useGradient
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: context.specialTheme.primaryGradient,
                      ),
                    )
                  : null,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Chi tiết sản phẩm',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                if (product != null) ...[
                  Builder(builder: (context) {
                    final authState = context.read<AuthBloc>().state;
                    final currentUserId = authState.currentUser?.id ?? '';
                    final sellerId = product.seller?.id ?? '';
                    final isOwnProduct = sellerId.isNotEmpty && sellerId.toString() == currentUserId.toString();
                    if (isOwnProduct) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            icon: const Icon(Icons.edit_outlined, color: Colors.white),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductFormPage(product: product),
                                ),
                              );
                              if (result == true && context.mounted) {
                                context.read<ProductDetailBloc>().add(ProductDetailRequested(product.id));
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteProduct(context, product.id),
                          ),
                        ],
                      );
                    }
                    return IconButton(
                      tooltip: 'Báo cáo',
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        final token = authState.currentUser?.token ?? '';
                        if (checkLogin(context, token: token)) {
                          _showReportSheet(context);
                        }
                      },
                      icon: const Icon(Icons.flag_outlined),
                    );
                  }),
                ],
              ],
            ),
            bottomNavigationBar: product == null
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: 'Thêm giỏ hàng',
                              icon: Icons.add_shopping_cart,
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Builder(builder: (context) {
                    final authState = context.read<AuthBloc>().state;
                    final currentUserId = authState.currentUser?.id ?? '';
                    final sellerId = product.seller?.id ?? '';
                    final isOwnProduct = sellerId.isNotEmpty && sellerId == currentUserId;
                    final canChat = !isOwnProduct && sellerId.isNotEmpty;
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: canChat
                                    ? () {
                                        final token = authState.currentUser?.token ?? '';
                                        if (checkLogin(context, token: token)) {
                                          final chatBloc = context.read<ChatBloc>();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider.value(
                                                value: chatBloc,
                                                child: ChatScreen(
                                                  partnerId: sellerId,
                                                  partnerUsername:
                                                      product.sellerName ?? 'Người bán',
                                                  partnerAvatar: product.seller?.avatar,
                                                  currentUserId: currentUserId,
                                                  productId: product.id,
                                                  productTitle: product.title,
                                                  productPrice: product.price,
                                                  productImageUrl: product.imageUrls.isNotEmpty
                                                      ? product.imageUrls.first
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ).then((_) {
                                            if (token.isNotEmpty) {
                                              chatBloc.add(LoadConversationsRequested());
                                            }
                                          });
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Chat'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Thêm giỏ hàng',
                                icon: Icons.add_shopping_cart,
                                onPressed: isOwnProduct ? null : () => _showAddToCartSheet(context, product),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildLoadingBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const ShimmerBox(height: 300),
        const SizedBox(height: AppSpacing.md),
        const ShimmerBox(height: 24, width: 200),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerBox(height: 20, width: 100),
        const SizedBox(height: AppSpacing.lg),
        const ShimmerBox(height: 40),
        const Divider(height: 32),
        const ShimmerBox(height: 16),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerBox(height: 16),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerBox(height: 16),
        const Divider(height: 32),
        Row(
          children: [
            const ShimmerBox(height: 50, width: 50, borderRadius: BorderRadius.all(Radius.circular(25))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 16, width: 150),
                  const SizedBox(height: AppSpacing.xs),
                  const ShimmerBox(height: 14, width: 100),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    final product = state.product;
    if (state.isLoading || (state.errorMessage != null && product == null)) {
      return _buildLoadingBody(context);
    }
    if (product == null) {
      return const EmptyState(title: 'Không tìm thấy sản phẩm');
    }

    final images = _collectDisplayImages(product);
    final sellerName = product.seller?.name ?? product.sellerName ?? 'Người bán';
    final sellerScore = product.seller?.score ?? (product.rating?.toStringAsFixed(1));
    final sellerListing = product.seller?.listing ?? (product.soldCount?.toString());
    final displayRating = product.rating ?? double.tryParse(product.seller?.score ?? '');

    final priceNewNumber = num.tryParse(product.priceNew ?? '');
    final hasPriceNew = priceNewNumber != null && priceNewNumber > 0;
    final hasDiscountText = (product.priceDiscount ?? '').isNotEmpty;

    final likeText = (product.like ?? '').isNotEmpty
        ? product.like!
        : product.likeCount.toString();
    final commentText = (product.comment ?? '').isNotEmpty
        ? product.comment!
        : state.comments.length.toString();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'product-image-${product.id}',
                child: images.isEmpty
                    ? const ColoredBox(
                        color: AppColors.border,
                        child: Icon(Icons.image_outlined, size: 56),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(images[index], fit: BoxFit.cover);
                        },
                      ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: AppSpacing.sm,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (images.length > 1)
          SizedBox(
            height: 84,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final image = images[index];
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        image,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title, style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  PriceText(price: product.price),
                  if (hasPriceNew)
                    Text(
                      '${priceNewNumber.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  if (hasDiscountText)
                    Text(
                      '-${product.priceDiscount}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if ((product.bestOffers ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ưu đãi: ${product.bestOffers}',
                  style: TextStyle(color: context.specialTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (displayRating != null) RatingStars(rating: displayRating),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: product.isLiked ? 'Bỏ thích' : 'Thích',
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          final token = authState.currentUser?.token ?? '';
                          if (checkLogin(context, token: token)) {
                            context.read<ProductDetailBloc>().add(ProductLikeToggled());
                          }
                        },
                        icon: Icon(
                          product.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: product.isLiked ? AppColors.danger : AppColors.textSecondary,
                        ),
                      ),
                      Text(likeText),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(commentText),
                    ],
                  ),
                ],
              ),
              if (product.sizes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Phân loại / Kích thước'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: product.sizes
                      .map(
                        (size) => Chip(
                          label: Text(size.name.isEmpty ? size.id : size.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              const Divider(height: 32),
              const SectionHeader(title: 'Mô tả'),
              const SizedBox(height: AppSpacing.sm),
              Text(product.described.isEmpty ? 'Chưa có mô tả.' : product.described),
              const Divider(height: 32),
              const SectionHeader(title: 'Thông tin sản phẩm'),
              const SizedBox(height: AppSpacing.sm),
              if (product.brand != null)
                _MetaRow(label: 'Thương hiệu', value: product.brand!.name),
              if (product.category != null)
                _MetaRow(label: 'Danh mục', value: product.category!.name),
              if ((product.condition ?? '').isNotEmpty)
                _MetaRow(label: 'Tình trạng', value: product.condition!),
              if ((product.shipsFrom ?? '').isNotEmpty)
                _MetaRow(label: 'Gửi từ', value: product.shipsFrom!),
              if ((product.weight ?? '').isNotEmpty)
                _MetaRow(label: 'Khối lượng', value: product.weight!),
              if (product.dimension.isNotEmpty)
                _MetaRow(label: 'Kích thước', value: product.dimension.join(' x ')),
              if ((product.state ?? '').isNotEmpty)
                _MetaRow(label: 'Trạng thái', value: product.state!),
              if ((product.canEdit ?? '').isNotEmpty)
                _MetaRow(label: 'Có thể sửa', value: product.canEdit!),
              if ((product.isBlocked ?? '').isNotEmpty)
                _MetaRow(label: 'Bị chặn', value: product.isBlocked!),
              if ((product.banned ?? '').isNotEmpty)
                _MetaRow(label: 'Bị cấm', value: product.banned!),
              if ((product.shareUrl ?? '').isNotEmpty)
                _MetaRow(label: 'Link chia sẻ', value: product.shareUrl!),
              const Divider(height: 32),
              const SectionHeader(title: 'Người bán'),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: product.seller?.avatar != null && product.seller!.avatar!.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(product.seller!.avatar!))
                    : const CircleAvatar(child: Icon(Icons.storefront)),
                title: Text(sellerName),
                subtitle: Text(product.sellerLocation ?? product.shipsFrom ?? 'Chưa có vị trí'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((sellerScore ?? '').isNotEmpty) Text('Điểm: $sellerScore'),
                    if ((sellerListing ?? '').isNotEmpty) Text('Listing: $sellerListing'),
                  ],
                ),
                onTap: () {
                  final userId = product.seller?.id ?? '';
                  if (userId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerInfoPage(
                        userId: userId,
                        productId: product.id,
                        sellerName: sellerName,
                        avatarUrl: product.seller?.avatar,
                        sellerScore: sellerScore,
                        sellerListing: sellerListing,
                      ),
                    ),
                  );
                },
              ),
              if (product.videos.isNotEmpty) ...[
                const Divider(height: 32),
                const SectionHeader(title: 'Video'),
                const SizedBox(height: AppSpacing.sm),
                ...product.videos.map(
                  (video) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_outline, size: 18),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            video.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (product.messages.isNotEmpty) ...[
                const Divider(height: 32),
                const SectionHeader(title: 'Thông báo từ hệ thống'),
                const SizedBox(height: AppSpacing.sm),
                ...product.messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('- '),
                        Expanded(child: Text(message)),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(height: 32),
              _RatingsSection(productId: product.id),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Bình luận',
                actionLabel: 'Viết',
                onActionTap: () {
                  final authState = context.read<AuthBloc>().state;
                  final token = authState.currentUser?.token ?? '';
                  if (checkLogin(context, token: token)) {
                    _showCommentSheet(context);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.comments.isEmpty)
                const Text('Chưa có bình luận.')
              else
                ...state.comments.map(
                  (comment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(comment.author),
                    subtitle: Text(comment.content),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddToCartSheet(BuildContext context, ProductModel product) {
    ProductSizeModel? selectedSize;
    int quantity = 1;

    AppBottomSheet.show<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) {
          final firstImg = product.images.isNotEmpty
              ? product.images.first.url
              : (product.imageUrls.isNotEmpty ? product.imageUrls.first : null);

          final subtotal = product.price * quantity;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: firstImg != null && firstImg.isNotEmpty
                        ? Image.network(
                            firstImg,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                          ),
                  ),
                  SizedBox(
                    width: 240, // Đảm bảo text không chiếm hết chiều ngang gây đẩy wrap
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        PriceText(price: product.price),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Variation/Size Section
              if (product.sizes.isNotEmpty) ...[
                const Text(
                  'Chọn phân loại / kích thước:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: product.sizes.map((size) {
                    final isSelected = selectedSize?.id == size.id;
                    return ChoiceChip(
                      label: Text(size.name.isEmpty ? size.id : size.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        setState(() {
                          selectedSize = selected ? size : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Quantity Section
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Số lượng:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: quantity <= 1
                            ? null
                            : () => setState(() => quantity--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),

              // Confirm Button
               Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      PriceText(price: subtotal),
                    ],
                  ),
                  AppButton(
                    label: 'Thêm vào giỏ hàng',
                    icon: Icons.add_shopping_cart,
                    onPressed: () {
                      if (product.sizes.isNotEmpty && selectedSize == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn phân loại / kích thước'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Appending selected size/variation name to the product ID to distinguish it in the cart
                      final cartProductId = selectedSize != null
                          ? "${product.id}-${selectedSize!.id}"
                          : product.id;
                      final displayTitle = selectedSize != null
                          ? "${product.title} (${selectedSize!.name.isEmpty ? selectedSize!.id : selectedSize!.name})"
                          : product.title;

                      CartManager().addToCart(
                        cartProductId,
                        displayTitle,
                        product.price,
                        firstImg,
                        quantity: quantity,
                        sellerId: product.seller?.id,
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm $quantity sản phẩm vào giỏ hàng'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCommentSheet(BuildContext context) {
    final controller = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: controller, label: 'Bình luận'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Gửi bình luận',
            onPressed: () {
              context.read<ProductDetailBloc>().add(ProductCommentSent(controller.text));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final subjectController = TextEditingController(text: 'Sản phẩm không phù hợp');
    final detailController = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: subjectController, label: 'Lý do'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: detailController, label: 'Chi tiết'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Gửi báo cáo',
            onPressed: () {
              context.read<ProductDetailBloc>().add(
                    ProductReported(
                      subject: subjectController.text,
                      details: detailController.text,
                    ),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(BuildContext context, String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<MarketplaceRepository>().deleteProduct(productId);
      if (!context.mounted) return;
      Navigator.pop(context); // Pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sản phẩm thành công')),
      );
      Navigator.pop(context, true); // Pop detail page back to listings, with refresh indicator
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _RatingsSection extends StatefulWidget {
  final String productId;

  const _RatingsSection({required this.productId});

  @override
  State<_RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<_RatingsSection> {
  bool _isLoading = true;
  String? _error;
  List<RateModel> _rates = [];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _rates = [];
    });
    final repo = context.read<MarketplaceRepository>();
    try {
      final rates = await repo.getRates(productId: widget.productId, index: 0, count: 20);
      if (!mounted) return;
      setState(() {
        _rates = rates;
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

  void _openWriteSheet() {
    final levelNotifier = ValueNotifier<int>(5);
    final controller = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Viết đánh giá', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<int>(
            valueListenable: levelNotifier,
            builder: (context, level, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    level >= star ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.warning,
                  ),
                  onPressed: () => levelNotifier.value = star,
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: controller, label: 'Nội dung đánh giá'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Gửi đánh giá',
            onPressed: () async {
              final authState = context.read<AuthBloc>().state;
              final userId = authState.currentUser?.id ?? '';
              if (userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập để đánh giá')));
                return;
              }
              final level = levelNotifier.value;
              final content = controller.text.trim();
              Navigator.pop(context);
              try {
                await context.read<MarketplaceRepository>().setRates(
                      userId: userId,
                      level: level,
                      content: content,
                      productId: widget.productId,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá')));
                await _loadRates();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              } finally {
                if (mounted) {}
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Đánh giá', actionLabel: 'Viết', onActionTap: _openWriteSheet),
        const SizedBox(height: AppSpacing.sm),
        if (_isLoading) const Center(child: CircularProgressIndicator())
        else if (_error != null) ErrorState(message: _error!, onRetry: _loadRates)
        else if (_rates.isEmpty)
          const Text('Chưa có đánh giá.')
        else
        ..._rates.map((r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(r.author),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: r.level.toDouble()),
                  const SizedBox(height: AppSpacing.xs),
                  Text(r.content),
                ],
              ),
            )),
      ],
    );
  }
}
