import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
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
import '../../repositories/auth_repository.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/marketplace_repository.dart';
import '../../core/services/cart_manager.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/price_text.dart';
import '../widgets/product_card.dart';
import '../widgets/rating_stars.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_product_grid.dart';
import 'marketplace_shared.dart';

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
              title: const Text('Chi tiết sản phẩm'),
              actions: [
                IconButton(
                  tooltip: 'Báo cáo',
                  onPressed: product == null ? null : () => _showReportSheet(context),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
            bottomNavigationBar: product == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: product.seller?.id == null || product.seller!.id.isEmpty
                                  ? null
                                  : () {
                                final authState = context.read<AuthBloc>().state;
                                final currentUserId =
                                    authState is AuthSuccess ? authState.user.id : '';
                                final chatBloc = context.read<ChatBloc>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: chatBloc,
                                      child: ChatScreen(
                                        partnerId: product.seller!.id,
                                        partnerUsername:
                                            product.sellerName ?? 'Người bán',
                                        partnerAvatar: product.seller?.avatar,
                                        currentUserId: currentUserId,
                                        productId: product.id,
                                        // Truyền thông tin sản phẩm để hiển thị trên banner
                                        productTitle: product.title,
                                        productPrice: product.price,
                                        productImageUrl: product.imageUrls.isNotEmpty
                                            ? product.imageUrls.first
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: 'Thêm giỏ hàng',
                              icon: Icons.add_shopping_cart,
                              onPressed: () => _showAddToCartSheet(context, product),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    final product = state.product;
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && product == null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () {
          final bloc = context.read<ProductDetailBloc>();
          final id = (bloc.state.product?.id).toString();
          if (id.isNotEmpty) bloc.add(ProductDetailRequested(id));
        },
      );
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
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (displayRating != null) RatingStars(rating: displayRating),
                  const Spacer(),
                  IconButton(
                    tooltip: product.isLiked ? 'Bỏ thích' : 'Thích',
                    onPressed: () => context.read<ProductDetailBloc>().add(ProductLikeToggled()),
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
                onActionTap: () => _showCommentSheet(context),
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
              final userId = authState is AuthSuccess ? authState.user.id : '';
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
    await AppBottomSheet.show<void>(
      context: context,
      child: _ProductSearchFilterSheet(state: state),
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
  late final TextEditingController _brandController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.state.brandId ?? '');
    _minPriceController = TextEditingController(text: widget.state.priceMin?.toString() ?? '');
    _maxPriceController = TextEditingController(text: widget.state.priceMax?.toString() ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  num? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }

  void _applyFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchFiltered(
            keyword: widget.state.keyword,
            categoryId: widget.state.categoryId,
            brandId: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
            priceMin: _parseNumber(_minPriceController.text),
            priceMax: _parseNumber(_maxPriceController.text),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bộ lọc tìm kiếm', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _brandController,
              label: 'Brand ID',
              hint: 'Nhập brand ID nếu cần lọc',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _minPriceController,
              label: 'Giá tối thiểu',
              hint: 'Ví dụ: 100000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _maxPriceController,
              label: 'Giá tối đa',
              hint: 'Ví dụ: 500000',
              keyboardType: TextInputType.number,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm người bán')),
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
                                  ),
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

  @override
  void initState() {
    super.initState();
    _followBloc = FollowBloc(followRepository: context.read<FollowRepository>());
    _blockBloc = BlockBloc(blockRepository: context.read<BlockRepository>());
    _chatBloc = ChatBloc(chatRepository: context.read<ChatRepository>());
    _loadUser();
  }

  @override
  void dispose() {
    _followBloc.close();
    _blockBloc.close();
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authRepo = context.read<AuthRepository>();
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Bạn cần đăng nhập để xem thông tin người dùng.';
          _isLoading = false;
        });
        return;
      }

      final response = await authRepo.getUserInfo(token: token, userId: _sellerUserId);
      if (response.data != null) {
        setState(() {
          _user = response.data;
          _isLoading = false;
          // Khởi tạo trạng thái nút từ dữ liệu API trả về
          _isFollowed = response.data!.followed ?? false;
          _isBlocked = response.data!.isBlocked ?? false;
        });
      } else {
        setState(() {
          _error = response.message.isNotEmpty ? response.message : 'Không tìm thấy người dùng.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openSellerListings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerListingsPage(userId: _sellerUserId)),
    );
  }

  // Bật/tắt follow người bán
  void _toggleFollow() {
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
    if (_isBlocked) {
      _showUnblockDialog();
    } else {
      _showBlockDialog();
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
    // Lấy userId của người dùng hiện tại từ AuthBloc để xác định bong bóng tin nhắn
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.id : '';

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
            // Chat từ trang người bán không đính kèm sản phẩm cụ thể → không hiện banner
            productId: null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayAvatar = _user?.avatar ?? widget.avatarUrl;
    final displayName = _user?.username ?? widget.sellerName;
    final displayListing = _user?.listing?.toString() ?? widget.sellerListing;
    final displayScore = widget.sellerScore;

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
                    // Hàng 1: Chat + Xem sản phẩm
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Chat',
                            icon: Icons.chat_bubble_outline,
                            onPressed: _openChat,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Xem sản phẩm của người bán',
                            icon: Icons.inventory_2_outlined,
                            onPressed: _openSellerListings,
                          ),
                        ),
                      ],
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
                            activeColor: AppColors.primary,
                            onTap: _toggleFollow,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SellerActionButton(
                            label: _isBlocked ? 'Đã chặn' : 'Chặn',
                            icon: Icons.block,
                            isActive: _isBlocked,
                            activeColor: Colors.black87,
                            onTap: _toggleBlock,
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
  final VoidCallback onTap;

  const _SellerActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey[400]!,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[700],
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
