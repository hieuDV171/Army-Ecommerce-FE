import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/ui/util/widgets/login_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';
import '../../blocs/block/block_bloc.dart';
import '../../blocs/block/block_event.dart';
import '../../blocs/block/block_state.dart';
import '../../blocs/follow/follow_bloc.dart';
import '../../blocs/follow/follow_event.dart';
import '../../blocs/follow/follow_state.dart';
import '../../blocs/marketplace/marketplace_bloc.dart' show ProductDetailBloc, ProductSearchBloc, CheckoutBloc;
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart' show ProductDetailState, ProductSearchState, CheckoutState;
import '../../models/marketplace_models.dart';
import '../../models/user_model.dart';
import '../../models/api_response.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/marketplace_repository.dart';
import '../../core/services/cart_manager.dart';
import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/theme/app_text_styles.dart';
import '../util/widgets/app_bottom_sheet.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';
import '../util/widgets/loading_overlay.dart';
import '../util/widgets/price_text.dart';
import '../util/widgets/product_card.dart';
import '../util/widgets/rating_stars.dart';
import '../util/widgets/section_header.dart';
import '../util/widgets/shimmer_product_grid.dart';
import '../util/widgets/shimmer_box.dart';
import 'marketplace_shared.dart';
import 'product_form_page.dart';
import '../util/theme/special_app_theme.dart';

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
            chatRepository: context.read<ChatRepository>(),
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
              Row(
                children: [
                  PriceText(price: product.price),
                  if (hasPriceNew) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${priceNewNumber.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (hasDiscountText) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '-${product.priceDiscount}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
              Row(
                children: [
                  if (displayRating != null) RatingStars(rating: displayRating),
                  const Spacer(),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Số lượng:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Row(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppButton(
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

class SearchPage extends StatelessWidget {
  final String? categoryId;

  const SearchPage({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductSearchBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ProductSearchRequested(categoryId: categoryId)),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _keywordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ProductSearchBloc>().add(ProductSearchLoadMoreRequested());
    }
  }

  Future<void> _openFilterSheet(BuildContext context, ProductSearchState state) async {
    final searchBloc = context.read<ProductSearchBloc>();
    await AppBottomSheet.show<void>(
      context: context,
      child: BlocProvider.value(
        value: searchBloc,
        child: _ProductSearchFilterSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductSearchBloc, ProductSearchState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tìm kiếm')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _keywordController,
                        label: 'Từ khóa',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      tooltip: 'Tìm kiếm',
                      onPressed: () {
                        context.read<ProductSearchBloc>().add(
                              ProductSearchRequested(
                                keyword: _keywordController.text.trim(),
                                categoryId: state.categoryId,
                              ),
                            );
                      },
                      icon: const Icon(Icons.search),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      tooltip: 'Lọc kết quả',
                      onPressed: () => _openFilterSheet(context, state),
                      icon: const Icon(Icons.tune),
                    ),
                  ],
                ),
              ),
              // Hiển thị danh sách thương hiệu nếu có categoryId
              if (state.categoryId != null)
                _BrandsList(
                  brands: state.brands,
                  isLoading: state.isBrandsLoading,
                  selectedBrandId: state.brandId,
                  onBrandSelected: (brandId) {
                    context.read<ProductSearchBloc>().add(
                          ProductSearchFiltered(
                            keyword: state.keyword,
                            categoryId: state.categoryId,
                            brandId: brandId,
                            priceMin: state.priceMin,
                            priceMax: state.priceMax,
                          ),
                        );
                  },
                ),
              Expanded(child: _buildResult(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResult(BuildContext context, ProductSearchState state) {
    if (state.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ShimmerProductGrid(),
      );
    }
    if (state.errorMessage != null && state.products.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<ProductSearchBloc>().add(
              state.useListProductsApi
                  ? ProductSearchFiltered(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    )
                  : ProductSearchRequested(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    ),
            ),
      );
    }
    if (state.products.isEmpty) {
      return const EmptyState(
        title: 'Không tìm thấy sản phẩm',
        message: 'Hãy thử từ khóa hoặc bộ lọc khác.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductSearchBloc>().add(
              state.useListProductsApi
                  ? ProductSearchFiltered(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    )
                  : ProductSearchRequested(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    ),
            );
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = state.products[index];
          return ProductCard(
            product: productCardDataFromModel(product),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id)),
            ),
          );
        },
      ),
    );
  }
}

class _ProductSearchFilterSheet extends StatefulWidget {
  final ProductSearchState state;

  const _ProductSearchFilterSheet({required this.state});

  @override
  State<_ProductSearchFilterSheet> createState() => _ProductSearchFilterSheetState();
}

class _ProductSearchFilterSheetState extends State<_ProductSearchFilterSheet> {
  late List<ProductBrandInfo> _availableBrands;
  String? _selectedBrandId;
  late double _currentMinPrice;
  late double _currentMaxPrice;
  late double _minPriceBound;
  late double _maxPriceBound;

  @override
  void initState() {
    super.initState();
    _selectedBrandId = widget.state.brandId;

    // Collect brands from products
    final Map<String, ProductBrandInfo> brandMap = {};
    for (final product in widget.state.products) {
      final brand = product.brand;
      if (brand != null && brand.id.isNotEmpty) {
        brandMap[brand.id] = brand;
      }
    }
    // Also include currently selected brand if not already in the map
    if (widget.state.brandId != null && !brandMap.containsKey(widget.state.brandId)) {
      brandMap[widget.state.brandId!] = ProductBrandInfo(
        id: widget.state.brandId!,
        name: 'ID: ${widget.state.brandId}',
      );
    }
    _availableBrands = brandMap.values.toList();

    // Determine price range bounds
    final products = widget.state.products;
    if (products.isNotEmpty) {
      _minPriceBound = products.map((p) => p.price.toDouble()).reduce((a, b) => a < b ? a : b);
      _maxPriceBound = products.map((p) => p.price.toDouble()).reduce((a, b) => a > b ? a : b);
    } else {
      _minPriceBound = 0;
      _maxPriceBound = 10000000;
    }

    if (_minPriceBound == _maxPriceBound) {
      _maxPriceBound = _minPriceBound + 100000;
    }

    _currentMinPrice = (widget.state.priceMin?.toDouble() ?? _minPriceBound).clamp(_minPriceBound, _maxPriceBound);
    _currentMaxPrice = (widget.state.priceMax?.toDouble() ?? _maxPriceBound).clamp(_minPriceBound, _maxPriceBound);
    if (_currentMinPrice > _currentMaxPrice) {
      _currentMinPrice = _minPriceBound;
      _currentMaxPrice = _maxPriceBound;
    }
  }

  String _formatPrice(num value) {
    try {
      return '${NumberFormat.decimalPattern('vi_VN').format(value)} xu';
    } catch (_) {
      return '${value.toStringAsFixed(0)} xu';
    }
  }

  void _applyFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchFiltered(
            keyword: widget.state.keyword,
            categoryId: widget.state.categoryId,
            brandId: _selectedBrandId,
            priceMin: _currentMinPrice.round(),
            priceMax: _currentMaxPrice.round(),
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchRequested(
            keyword: widget.state.keyword,
            categoryId: widget.state.categoryId,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bộ lọc tìm kiếm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Thương hiệu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_availableBrands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Không có thương hiệu nào từ các sản phẩm tìm thấy',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _availableBrands.map((brand) {
                  final isSelected = _selectedBrandId == brand.id;
                  final displayName = brand.name.isNotEmpty && brand.name != 'Thương hiệu'
                      ? brand.name
                      : 'ID: ${brand.id}';
                  return ChoiceChip(
                    label: Text(displayName),
                    selected: isSelected,
                    selectedColor: specialTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: specialTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? specialTheme.primaryColor : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedBrandId = selected ? brand.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khoảng giá',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_formatPrice(_currentMinPrice)} - ${_formatPrice(_currentMaxPrice)}',
                  style: TextStyle(
                    color: specialTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            RangeSlider(
              values: RangeValues(_currentMinPrice, _currentMaxPrice),
              min: _minPriceBound,
              max: _maxPriceBound,
              activeColor: specialTheme.primaryColor,
              inactiveColor: AppColors.border,
              labels: RangeLabels(
                _formatPrice(_currentMinPrice),
                _formatPrice(_currentMaxPrice),
              ),
              onChanged: (values) {
                setState(() {
                  _currentMinPrice = values.start;
                  _currentMaxPrice = values.end;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilter,
                    child: const Text('Xóa lọc'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Áp dụng',
                    onPressed: _applyFilter,
                    icon: Icons.filter_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class SellerListingsPage extends StatefulWidget {
  final String userId;

  const SellerListingsPage({super.key, required this.userId});

  @override
  State<SellerListingsPage> createState() => _SellerListingsPageState();
}

class _SellerListingsPageState extends State<SellerListingsPage> {
  late final MarketplaceRepository _repository;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<ProductModel> _products = [];
  int _currentIndex = 0;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketplaceRepository>();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 360;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
    });

    try {
      final products = await _repository.getUserListings(
        userId: widget.userId,
        index: 0,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _currentIndex = 1;
        _hasReachedEnd = products.length < 20;
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

    setState(() => _isLoadingMore = true);
    try {
      final products = await _repository.getUserListings(
        userId: widget.userId,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...products];
        _currentIndex += 1;
        _hasReachedEnd = products.length < 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id ?? '';
    final isOwnListings = currentUserId.isNotEmpty && currentUserId.toString() == widget.userId.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm người bán')),
      floatingActionButton: isOwnListings
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductFormPage(),
                  ),
                );
                if (result == true) {
                  _loadProducts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              backgroundColor: context.specialTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _products.isEmpty
              ? ErrorState(
                  message: _error!,
                  onRetry: _loadProducts,
                )
              : _products.isEmpty
                  ? const EmptyState(title: 'Chưa có sản phẩm')
                  : RefreshIndicator(
                      onRefresh: () async => _loadProducts(),
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            sliver: SliverGrid.builder(
                              itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.66,
                              ),
                              itemBuilder: (context, index) {
                                if (index >= _products.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final product = _products[index];
                                return ProductCard(
                                  product: productCardDataFromModel(product),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(productId: product.id),
                                    ),
                                  ).then((_) => _loadProducts()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class SellerInfoPage extends StatefulWidget {
  final String userId;
  final String? productId;
  final String sellerName;
  final String? avatarUrl;
  final String? sellerScore;
  final String? sellerListing;

  const SellerInfoPage({
    super.key,
    required this.userId,
    this.productId,
    required this.sellerName,
    this.avatarUrl,
    this.sellerScore,
    this.sellerListing,
  });

  @override
  State<SellerInfoPage> createState() => _SellerInfoPageState();
}

class _SellerInfoPageState extends State<SellerInfoPage> {
  bool _isLoading = true;
  String? _error;
  UserModel? _user;

  String get _sellerUserId {
    final loadedUserId = _user?.id;
    return loadedUserId != null && loadedUserId.isNotEmpty ? loadedUserId : widget.userId;
  }

  // BLoC follow, block và chat — tạo riêng cho màn hình này
  late final FollowBloc _followBloc;
  late final BlockBloc _blockBloc;
  late final ChatBloc _chatBloc;
  // Trạng thái nút — optimistic update ngay khi người dùng bấm
  bool _isFollowed = false;
  bool _isBlocked = false;

  // Trạng thái sản phẩm & phân trang
  late final ScrollController _scrollController;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  int _currentIndex = 0;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _followBloc = FollowBloc(followRepository: context.read<FollowRepository>());
    _blockBloc = BlockBloc(blockRepository: context.read<BlockRepository>());
    _chatBloc = ChatBloc(chatRepository: context.read<ChatRepository>());
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadUser();
  }

  @override
  void dispose() {
    _followBloc.close();
    _blockBloc.close();
    _chatBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
      _isLoadingProducts = true;
    });

    final authRepo = context.read<AuthRepository>();
    final marketRepo = context.read<MarketplaceRepository>();
    try {
      final token = await SessionManager.getToken();
      final isGuest = token == null || token.isEmpty;

      if (isGuest) {
        // Guest mode: load listings, skip follow/block status
        final productsResponse = await marketRepo.getUserListings(
          userId: _sellerUserId,
          index: 0,
          count: 20,
        );
        if (!mounted) return;
        setState(() {
          _products = productsResponse;
          _currentIndex = 1;
          _hasReachedEnd = productsResponse.length < 20;
          _isFollowed = false;
          _isBlocked = false;
          _isLoading = false;
          _isLoadingProducts = false;
        });
      } else {
        // Fetch user info and first listings page concurrently
        final results = await Future.wait([
          authRepo.getUserInfo(token: token, userId: _sellerUserId),
          marketRepo.getUserListings(userId: _sellerUserId, index: 0, count: 20),
        ]);

        final userResponse = results[0] as ApiResponse<UserModel>;
        final productsResponse = results[1] as List<ProductModel>;

        if (userResponse.data != null) {
          if (!mounted) return;
          setState(() {
            _user = userResponse.data;
            _products = productsResponse;
            _currentIndex = 1;
            _hasReachedEnd = productsResponse.length < 20;
            _isFollowed = userResponse.data!.followed ?? false;
            _isBlocked = userResponse.data!.isBlocked ?? false;
            _isLoading = false;
            _isLoadingProducts = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _error = userResponse.message.isNotEmpty ? userResponse.message : 'Không tìm thấy người dùng.';
            _isLoading = false;
            _isLoadingProducts = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingProducts || _hasReachedEnd || _isLoading) return;
    setState(() => _isLoadingProducts = true);
    try {
      final marketRepo = context.read<MarketplaceRepository>();
      final more = await marketRepo.getUserListings(
        userId: _sellerUserId,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(more);
        _currentIndex++;
        _hasReachedEnd = more.length < 20;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  void _toggleFollow() {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã chặn người dùng này, không thể thực hiện thao tác.')),
      );
      return;
    }
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isFollowed) {
        _showUnfollowDialog();
      } else {
        setState(() => _isFollowed = true);
        _followBloc.add(FollowUserRequested(
          followeeId: _sellerUserId,
          username: widget.sellerName,
          action: 'follow',
        ));
      }
    }
  }

  // Dialog xác nhận hủy theo dõi
  Future<void> _showUnfollowDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Hủy theo dõi'),
        content: Text('Bỏ theo dõi "${widget.sellerName}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isFollowed = false);
      _followBloc.add(FollowUserRequested(
        followeeId: _sellerUserId,
        username: widget.sellerName,
        action: 'unfollow',
      ));
    }
  }

  // Bật/tắt chặn người bán
  void _toggleBlock() {
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isBlocked) {
        _showUnblockDialog();
      } else {
        _showBlockDialog();
      }
    }
  }

  // Dialog xác nhận chặn người bán
  Future<void> _showBlockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Chặn người dùng'),
        content: Text(
          'Chặn "${widget.sellerName}"? Người này sẽ không thể xem trang cá nhân hay liên hệ với bạn.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            child: const Text('Chặn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isBlocked = true);
      _blockBloc.add(BlockUserRequested(
        userId: _sellerUserId,
        username: widget.sellerName,
        action: 'block',
      ));
    }
  }

  // Dialog xác nhận bỏ chặn người bán
  Future<void> _showUnblockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Bỏ chặn người dùng'),
        content: Text(
          'Bỏ chặn "${widget.sellerName}"? Người này sẽ có thể xem trang và liên hệ với bạn.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isBlocked = false);
      _blockBloc.add(BlockUserRequested(
        userId: _sellerUserId,
        username: widget.sellerName,
        action: 'unblock',
      ));
    }
  }

  void _openChat() {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã chặn người dùng này, không thể thực hiện thao tác.')),
      );
      return;
    }
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã chặn người này, không thể thực hiện thao tác.')),
        );
        return;
      }
      final currentUserId = authState.currentUser?.id ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _chatBloc,
            child: ChatScreen(
              partnerId: _sellerUserId,
              partnerUsername: _user?.username ?? widget.sellerName,
              partnerAvatar: _user?.avatar ?? widget.avatarUrl,
              currentUserId: currentUserId,
              productId: null,
            ),
          ),
        ),
      ).then((_) {
        if (mounted && token.isNotEmpty) {
          _chatBloc.add(LoadConversationsRequested());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAvatar = _user?.avatar ?? widget.avatarUrl;
    final displayName = _user?.username ?? widget.sellerName;
    final displayListing = _user?.listing?.toString() ?? widget.sellerListing;
    final displayScore = widget.sellerScore;

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id ?? '';
    final isMe = _sellerUserId == currentUserId && currentUserId.isNotEmpty;
    final isGuest = !authState.isAuthenticated;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _followBloc),
        BlocProvider.value(value: _blockBloc),
        BlocProvider.value(value: _chatBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<FollowBloc, FollowState>(
            listenWhen: (_, current) =>
                current is FollowActionSuccess || current is FollowFailure,
            listener: (context, state) {
              if (state is FollowActionSuccess) {
                setState(() => _isFollowed = state.isFollowed);
                final msg = state.isFollowed
                    ? 'Theo dõi ${state.username} thành công'
                    : 'Đã hủy theo dõi ${state.username}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
                );
              } else if (state is FollowFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${state.error}')),
                );
              }
            },
          ),
          BlocListener<BlockBloc, BlockState>(
            listenWhen: (_, current) =>
                current is BlockActionSuccess || current is BlockFailure,
            listener: (context, state) {
              if (state is BlockActionSuccess) {
                setState(() => _isBlocked = state.isBlocked);
                final msg = state.isBlocked
                    ? 'Đã chặn ${state.username}'
                    : 'Đã bỏ chặn ${state.username}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              } else if (state is BlockFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${state.error}')),
                );
              }
            },
          ),
        ],
        child: Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(
                  message: _error!,
                  onRetry: _loadUser,
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Row(
                      children: [
                        displayAvatar != null && displayAvatar.isNotEmpty
                            ? CircleAvatar(radius: 36, backgroundImage: NetworkImage(displayAvatar))
                            : const CircleAvatar(radius: 36, child: Icon(Icons.storefront)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: AppTextStyles.screenTitle),
                              const SizedBox(height: AppSpacing.xs),
                              if (displayScore != null && displayScore.isNotEmpty) Text('Điểm: $displayScore'),
                              if (displayListing != null && displayListing.isNotEmpty) Text('Listing: $displayListing'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (isMe) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Đây là trang cửa hàng của bạn. Bạn không thể tự nhắn tin, theo dõi hoặc tự chặn chính mình.',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ] else if (isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Bạn đang ở chế độ khách. Đăng nhập để nhắn tin, theo dõi hoặc chặn người bán này.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    // Hàng 1: Chat (Full width)
                    AppButton(
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline,
                      onPressed: isMe ? null : _openChat,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Hàng 2: Theo dõi + Chặn
                    Row(
                      children: [
                        Expanded(
                          child: _SellerActionButton(
                            label: _isFollowed ? 'Đang theo dõi' : 'Theo dõi',
                            icon: _isFollowed ? Icons.check : Icons.person_add_outlined,
                            isActive: _isFollowed,
                            activeColor: context.specialTheme.primaryColor,
                            onTap: isMe ? null : _toggleFollow,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SellerActionButton(
                            label: _isBlocked ? 'Đã chặn' : 'Chặn',
                            icon: Icons.block,
                            isActive: _isBlocked,
                            activeColor: Colors.black87,
                            onTap: isMe ? null : _toggleBlock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(title: 'Thông tin người bán'),
                    const SizedBox(height: AppSpacing.sm),
                    if (_user != null) ...[
                      if ((_user!.email ?? '').isNotEmpty) _MetaRow(label: 'Email', value: _user!.email!),
                      if ((_user!.phoneNumber ?? '').isNotEmpty) _MetaRow(label: 'Số điện thoại', value: _user!.phoneNumber!),
                      if ((_user!.address ?? '').isNotEmpty) _MetaRow(label: 'Địa chỉ', value: _user!.address!),
                      if ((_user!.city ?? '').isNotEmpty) _MetaRow(label: 'Thành phố', value: _user!.city!),
                      if ((_user!.status ?? '').isNotEmpty) _MetaRow(label: 'Trạng thái', value: _user!.status!),
                      if ((_user!.firstName ?? '').isNotEmpty || (_user!.lastName ?? '').isNotEmpty)
                        _MetaRow(label: 'Tên', value: '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim()),
                    ]
                    else
                      const Text('Thông tin chi tiết người bán chưa có.'),
                    const Divider(height: 32),
                    const SectionHeader(title: 'Sản phẩm đang bán'),
                    const SizedBox(height: AppSpacing.sm),
                    if (_products.isEmpty && !_isLoadingProducts)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text(
                          'Chưa đăng bán sản phẩm nào.',
                          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      )
                    else ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            product: productCardDataFromModel(product),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(productId: product.id),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isLoadingProducts)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final List<CartItem> items;

  const CheckoutPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final firstItemId = items.isNotEmpty ? int.tryParse(items.first.productId.split('-')[0]) : null;
    return BlocProvider(
      create: (context) => CheckoutBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(CheckoutRequested(productId: firstItemId)),
      child: _CheckoutView(items: items),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final List<CartItem> items;

  const _CheckoutView({required this.items});

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<num>(0, (sum, item) => sum + item.price * item.quantity);

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
        if (state.successMessage != null) {
          CartManager().clearCart();
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

// Nút hành động với người bán (Theo dõi / Chặn) — đổi màu theo trạng thái active
class _SellerActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _SellerActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final specialTheme = context.specialTheme;
    final isThemePrimary = activeColor == AppColors.primary || activeColor == specialTheme.primaryColor;

    Gradient? bgGradient;
    Color? bgSolidColor;
    Color borderClr;

    if (isDisabled) {
      bgSolidColor = Colors.grey[200];
      borderClr = Colors.grey[300]!;
    } else if (isActive) {
      if (isThemePrimary && specialTheme.useGradient) {
        bgGradient = specialTheme.primaryGradient;
        borderClr = Colors.transparent;
      } else {
        bgSolidColor = activeColor;
        borderClr = activeColor;
      }
    } else {
      bgSolidColor = Colors.white;
      borderClr = Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgSolidColor,
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: borderClr == Colors.transparent
              ? null
              : Border.all(
                  color: borderClr,
                  width: 1,
                ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDisabled
                  ? Colors.grey[400]
                  : (isActive ? Colors.white : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? Colors.grey[400]
                    : (isActive ? Colors.white : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị danh sách thương hiệu nằm ngang có thể cuộn
class _BrandsList extends StatelessWidget {
  final List<BrandModel> brands;
  final bool isLoading;
  final String? selectedBrandId;
  final Function(String?) onBrandSelected;

  const _BrandsList({
    required this.brands,
    required this.isLoading,
    required this.selectedBrandId,
    required this.onBrandSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thương hiệu',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: isLoading
                ? const Center(child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: brands.length + 1,
                    separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Nút "Tất cả" để xóa filter thương hiệu
                        return _BrandChip(
                          label: 'Tất cả',
                          isSelected: selectedBrandId == null,
                          onTap: () => onBrandSelected(null),
                        );
                      }
                      final brand = brands[index - 1];
                      return _BrandChip(
                        label: brand.name,
                        isSelected: selectedBrandId == brand.id,
                        onTap: () => onBrandSelected(brand.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị từng thương hiệu dưới dạng chip bấm được
class _BrandChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
