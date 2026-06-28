import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_event.dart';
import 'package:army_ecommerce/blocs/marketplace/product_detail/product_detail_state.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/ui/util/widgets/login_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';

import 'package:army_ecommerce/core/services/cart_manager.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
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
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';
import '../../util/widgets/status_chip.dart';
import '../checkout/checkout_page.dart';
import '../../util/widgets/avatar_with_frame.dart';

class ProductDetailPage extends StatelessWidget {
  static String? activeProductId;

  final String productId;
  final bool? isStock;
  final bool scrollToComments;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.isStock,
    this.scrollToComments = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductDetailBloc(
            marketplaceRepository: context.read<MarketplaceRepository>(),
          )..add(ProductDetailRequested(productId, isStock: isStock)),
        ),
        // ChatBloc riêng cho trang sản phẩm — dùng khi nhấn nút Chat với người bán
        BlocProvider(
          create: (context) => ChatBloc(
            marketplaceRepository: context.read<MarketplaceRepository>(),
          ),
        ),
      ],
      child: _ProductDetailView(
        productId: productId,
        isStock: isStock,
        scrollToComments: scrollToComments,
      ),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  final String productId;
  final bool? isStock;
  final bool scrollToComments;
  const _ProductDetailView({
    required this.productId,
    this.isStock,
    required this.scrollToComments,
  });

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  late final PageController _pageController;
  late final ScrollController _scrollController;
  final GlobalKey _commentSectionKey = GlobalKey();
  int _currentImageIndex = 0;
  bool _hasScrolledToComments = false;

  String _formatSimpleVariantName(ProductSizeModel size) {
    final parts = <String>[];
    parts.add(size.name.isEmpty ? size.id : size.name);
    if (size.color != null && size.color!.isNotEmpty) {
      parts.add(size.color!);
    }
    return parts.join(' - ');
  }

  Widget _buildVariantMap(ProductSizeModel size) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVariantRow('Kích cỡ', size.name.isEmpty ? size.id : size.name),
          _buildVariantRow('Màu', size.color ?? 'Mặc định'),
          _buildVariantRow(
            'Tồn kho',
            (size.stock != null && size.stock! > 0) ? '${size.stock} sản phẩm' : 'Hết hàng',
          ),
          _buildVariantRow(
            'Khối lượng',
            size.weight != null ? '${size.weight}kg' : 'Chưa rõ',
          ),
        ],
      ),
    );
  }

  Widget _buildVariantRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Track active product page to suppress redundant notification redirects
    ProductDetailPage.activeProductId = widget.productId;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<ProductDetailBloc>();
      if (bloc.state.hasMoreComments && !bloc.state.isFetchingMoreComments) {
        bloc.add(ProductCommentsLoadMoreRequested());
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    if (ProductDetailPage.activeProductId == widget.productId) {
      ProductDetailPage.activeProductId = null;
    }
    super.dispose();
  }

  void _scrollToComments() {
    try {
      final context = _commentSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint('Scroll error: $e');
    }
  }

  Widget _safeImageNetwork(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return Container(
        width: width,
        height: height,
        color: AppColors.border,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSecondary,
        ),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppColors.border,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _formatBestOffers(String? value) {
    if (value == null || value.isEmpty || value == '[]') {
      return '0%';
    }
    final clean = value
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    if (clean.isEmpty) {
      return '0%';
    }
    final numVal = num.tryParse(clean);
    if (numVal == null) {
      return value;
    }
    if (numVal <= 100) {
      return '$numVal%';
    } else {
      try {
        return '${NumberFormat.decimalPattern('vi_VN').format(numVal)} xu';
      } catch (_) {
        return '$numVal xu';
      }
    }
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
        if (state.isDeleted) {
          AppSnackBar.show(context, message: state.successMessage ?? 'Đã xóa sản phẩm');
          Navigator.pop(context, true);
          return;
        }
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          final isTokenInvalidMsg = message.toLowerCase().contains('token is invalid') ||
              message.toLowerCase().contains('token_invalid') ||
              message.toLowerCase().contains('token is required');
          final isGuest = (context.read<AuthBloc>().state.currentUser?.token ?? '').isEmpty;
          if (!isGuest || !isTokenInvalidMsg) {
            AppSnackBar.show(context, message: message);
          }
        }
        if (state.product != null &&
            widget.scrollToComments &&
            !_hasScrolledToComments) {
          _hasScrolledToComments = true;
          final route = ModalRoute.of(context);
          if (route?.animation != null &&
              route!.animation!.status != AnimationStatus.completed) {
            void onAnimationStatus(AnimationStatus status) {
              if (status == AnimationStatus.completed) {
                route.animation!.removeStatusListener(onAnimationStatus);
                _scrollToComments();
              }
            }

            route.animation!.addStatusListener(onAnimationStatus);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToComments();
            });
          }
        }
      },
      builder: (context, state) {
        final product = state.product;
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: context.specialTheme.useGradient
                  ? Colors.transparent
                  : context.specialTheme.primaryDarkColor,
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
                  Builder(
                    builder: (context) {
                      final authState = context.read<AuthBloc>().state;
                      final currentUserId = authState.currentUser?.id ?? '';
                      final sellerId = product.seller?.id ?? '';
                      final isOwnProduct =
                          sellerId.isNotEmpty &&
                          sellerId.toString() == currentUserId.toString();
                      if (isOwnProduct) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Chỉnh sửa',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductFormPage(product: product),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  context.read<ProductDetailBloc>().add(
                                    ProductDetailRequested(product.id),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Xóa',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDeleteProduct(context, product.id),
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
                    },
                  ),
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
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Thêm giỏ hàng'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: 'Mua ngay',
                              icon: Icons.shopping_bag_outlined,
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final authState = context.read<AuthBloc>().state;
                      final token = authState.currentUser?.token ?? '';
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _showVariantSelectionSheet(
                                      context,
                                      product,
                                      isBuyNow: false,
                                    );
                                  },
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Thêm giỏ hàng'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(
                                  label: 'Mua ngay',
                                  icon: Icons.shopping_bag_outlined,
                                  onPressed: () {
                                    if (checkLogin(context, token: token)) {
                                      _showVariantSelectionSheet(
                                        context,
                                        product,
                                        isBuyNow: true,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
            const ShimmerBox(
              height: 50,
              width: 50,
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
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
    if (state.isLoading) {
      return _buildLoadingBody(context);
    }
    if (state.errorMessage != null && product == null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () {
          context.read<ProductDetailBloc>().add(
            ProductDetailRequested(widget.productId, isStock: widget.isStock),
          );
        },
      );
    }
    if (product == null) {
      return const EmptyState(title: 'Không tìm thấy sản phẩm');
    }

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id ?? '';
    final sellerId = product.seller?.id ?? '';
    final isMe = sellerId.isNotEmpty && sellerId == currentUserId;

    final images = _collectDisplayImages(product);
    final sellerName =
        product.seller?.name ?? product.sellerName ?? 'Người bán';
    final sellerScore =
        product.seller?.score ?? (product.rating?.toStringAsFixed(1));
    final sellerListing =
        product.seller?.listing ?? (product.soldCount?.toString());
    final displayRating =
        product.rating ?? double.tryParse(product.seller?.score ?? '');

    final hasDiscountText = (product.priceDiscount ?? '').isNotEmpty;

    final likeText = (product.like ?? '').isNotEmpty
        ? product.like!
        : product.likeCount.toString();
    final commentText = (product.comment ?? '').isNotEmpty
        ? product.comment!
        : state.comments.length.toString();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: images.isEmpty
                  ? Hero(
                      tag: 'product-image-${product.id}',
                      child: const ColoredBox(
                        color: AppColors.border,
                        child: Icon(Icons.image_outlined, size: 56),
                      ),
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
                        final imageWidget = _safeImageNetwork(
                          images[index],
                          fit: BoxFit.cover,
                        );
                        if (index == 0) {
                          return Hero(
                            tag: 'product-image-${product.id}',
                            child: imageWidget,
                          );
                        }
                        return imageWidget;
                      },
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
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
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: _safeImageNetwork(
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
                  DiscountPriceRow(
                    originalPrice: product.price,
                    priceNew: product.priceNew,
                    bestOffers: product.bestOffers,
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ưu đãi: ${_formatBestOffers(product.bestOffers)}',
                style: TextStyle(
                  color: context.specialTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Text(
                    'Trạng thái: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  StatusChip(
                    label: product.isStock ? 'Còn hàng' : 'Hết hàng',
                    color: product.isStock ? Colors.green : Colors.red,
                    icon: product.isStock
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                ],
              ),
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
                            context.read<ProductDetailBloc>().add(
                              ProductLikeToggled(),
                            );
                          }
                        },
                        icon: Icon(
                          product.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isLiked
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(likeText),
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _scrollToComments,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(commentText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (product.sizes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Phân loại / Kích thước'),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.sizes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final size = product.sizes[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        final authState = context.read<AuthBloc>().state;
                        final token = authState.currentUser?.token ?? '';
                        if (checkLogin(context, token: token)) {
                          _showVariantSelectionSheet(
                            context,
                            product,
                            isBuyNow: false,
                            preselectedSize: size,
                          );
                        }
                      },
                      child: _buildVariantMap(size),
                    );
                  },
                ),
              ],
              const Divider(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  splashColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  highlightColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.05,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Mô tả'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          product.described.isEmpty
                              ? 'Chưa có mô tả.'
                              : product.described,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  splashColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  highlightColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.05,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Thông tin sản phẩm'),
                        const SizedBox(height: AppSpacing.sm),
                        if (product.brand != null)
                          _MetaRow(
                            label: 'Thương hiệu',
                            value: product.brand!.name,
                          ),
                        if (product.category != null)
                          _MetaRow(
                            label: 'Danh mục',
                            value: product.category!.name,
                          ),
                        if ((product.shipsFrom ?? '').isNotEmpty)
                          _MetaRow(label: 'Gửi từ', value: product.shipsFrom!),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              const SectionHeader(title: 'Người bán'),
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  splashColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  highlightColor: context.specialTheme.primaryColor.withValues(
                    alpha: 0.05,
                  ),
                  onTap: () {
                    final authState = context.read<AuthBloc>().state;
                    final token = authState.currentUser?.token ?? '';
                    if (!checkLogin(context, token: token)) {
                      return;
                    }
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AvatarWithFrame(
                        radius: 24,
                        avatarImage: product.seller?.avatar != null && product.seller!.avatar!.isNotEmpty
                            ? SessionManager.getImageProvider(product.seller!.avatar!)
                            : null,
                        frameUrl: product.seller?.coverImageWeb,
                        fallbackChild: const Icon(Icons.storefront),
                      ),
                      title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        product.sellerLocation ??
                            product.shipsFrom ??
                            'Chưa có vị trí',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if ((sellerScore ?? '').isNotEmpty)
                                Text('Điểm: $sellerScore', style: const TextStyle(fontSize: 12)),
                              if ((sellerListing ?? '').isNotEmpty)
                                Text('Listing: $sellerListing', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMe
                                  ? Colors.grey[200]
                                  : (context.specialTheme.useGradient
                                      ? null
                                      : context.specialTheme.primaryColor),
                              gradient: isMe
                                  ? null
                                  : (context.specialTheme.useGradient
                                      ? context.specialTheme.primaryGradient
                                      : null),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, size: 20),
                              color: isMe ? Colors.grey[400] : Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              onPressed: isMe
                                  ? null
                                  : () {
                                      final token = authState.currentUser?.token ?? '';
                                      if (checkLogin(context, token: token)) {
                                        final chatBloc = context.read<ChatBloc>();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider(
                                              create: (context) => ChatBloc(
                                                marketplaceRepository: context.read<MarketplaceRepository>(),
                                              ),
                                              child: ChatScreen(
                                                partnerId: sellerId,
                                                partnerUsername: sellerName,
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
                                          if (context.mounted && token.isNotEmpty) {
                                            chatBloc.add(LoadConversationsRequested());
                                          }
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
              Builder(
                builder: (context) {
                  final authState = context.watch<AuthBloc>().state;
                  final token = authState.currentUser?.token ?? '';
                  if (token.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 32),
                      _RatingsSection(
                        productId: product.id,
                        sellerId: product.seller?.id,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                key: _commentSectionKey,
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
              else ...[
                ...state.comments.map(
                  (comment) => Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        splashColor: context.specialTheme.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                        highlightColor: context.specialTheme.primaryColor.withValues(
                          alpha: 0.05,
                        ),
                        onTap: () {
                          final authState = context.read<AuthBloc>().state;
                          final token = authState.currentUser?.token ?? '';
                          if (!checkLogin(context, token: token)) {
                            return;
                          }
                          if (comment.authorId.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerInfoPage(
                                userId: comment.authorId,
                                sellerName: comment.authorName,
                                avatarUrl: comment.avatar,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: AvatarWithFrame(
                            radius: 24,
                            avatarImage:
                                (comment.avatar != null && comment.avatar!.isNotEmpty)
                                ? SessionManager.getImageProvider(comment.avatar!)
                                : null,
                            frameUrl: comment.coverImageWeb,
                          ),
                          title: Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.content, style: const TextStyle(color: Colors.black87)),
                              if (comment.createdAt != null &&
                                  comment.createdAt!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(comment.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.isFetchingMoreComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.hasMoreComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'Kéo xuống để tải thêm bình luận...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else if (state.comments.length >= 20)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'Đã hết bình luận.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showOutOfStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sản phẩm đã hết hàng'),
        content: const Text(
          'Rất tiếc, sản phẩm này hiện đã hết hàng. Vui lòng quay lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showVariantSelectionSheet(
    BuildContext context,
    ProductModel product, {
    required bool isBuyNow,
    ProductSizeModel? preselectedSize,
  }) {
    // TIP-03: sản phẩm đã hết hàng -> báo ngay, không mở sheet chọn mua
    if (!product.isStock) {
      _showOutOfStockDialog(context);
      return;
    }
    ProductSizeModel? selectedSize = preselectedSize;
    int quantity = 1;
    String? errorMessage;

    AppBottomSheet.show<void>(
      context: context,
      child: StatefulBuilder(
        builder: (sheetContext, setState) {
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
                        ? _safeImageNetwork(
                            firstImg,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                    final isSoldOut = size.stock != null && size.stock! <= 0;
                    return ChoiceChip(
                      label: Text(
                        isSoldOut
                            ? '${_formatSimpleVariantName(size)} (Hết)'
                            : _formatSimpleVariantName(size),
                        style: TextStyle(
                          color: isSoldOut
                              ? Colors.grey
                              : (isSelected
                                  ? context.specialTheme.primaryDarkColor
                                  : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: context.specialTheme.primaryColor
                          .withValues(alpha: 0.2),
                      onSelected: isSoldOut
                          ? null
                          : (selected) {
                              setState(() {
                                selectedSize = selected ? size : null;
                                errorMessage = null; // Clear error on select
                                // TIP-02: kẹp số lượng theo tồn kho variant
                                final st = selectedSize?.stock;
                                if (st != null && st > 0 && quantity > st) {
                                  quantity = st;
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                if (selectedSize != null) ...[
                  _buildVariantMap(selectedSize!),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],

              // Quantity Section
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Số lượng:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        // TIP-02: chặn tăng vượt tồn kho của variant đã chọn
                        onPressed: (selectedSize?.stock != null &&
                                quantity >= selectedSize!.stock!)
                            ? null
                            : () => setState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),

              // Error display
              if (errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

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
                    label: isBuyNow ? 'Mua ngay' : 'Thêm vào giỏ hàng',
                    icon: isBuyNow
                        ? Icons.shopping_bag_outlined
                        : Icons.add_shopping_cart,
                    onPressed: () {
                      if (product.sizes.isNotEmpty && selectedSize == null) {
                        setState(() {
                          errorMessage = 'Vui lòng chọn phân loại / kích thước';
                        });
                        return;
                      }
                      // TIP-02/03: kiểm tra tồn kho của variant đã chọn
                      final stock = selectedSize?.stock;
                      if (stock != null && stock <= 0) {
                        setState(() {
                          errorMessage = 'Phân loại này đã hết hàng';
                        });
                        return;
                      }
                      if (stock != null && quantity > stock) {
                        setState(() {
                          errorMessage = 'Chỉ còn $stock sản phẩm cho phân loại này';
                        });
                        return;
                      }

                      // Appending selected size/variation name to the product ID to distinguish it
                      final cartProductId = selectedSize != null
                          ? "${product.id}-${selectedSize!.id}"
                          : product.id;
                      final displayTitle = selectedSize != null
                          ? "${product.title} (${selectedSize!.name.isEmpty ? selectedSize!.id : selectedSize!.name})"
                          : product.title;

                      if (isBuyNow) {
                        final buyNowItem = CartItem(
                          productId: cartProductId,
                          title: displayTitle,
                          price: product.price,
                          imageUrl: firstImg,
                          quantity: quantity,
                          sellerId: product.seller?.id,
                        );

                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(
                              items: [buyNowItem],
                              orderSource: 1,
                            ),
                          ),
                        );
                      } else {
                        CartManager().addToCart(
                          cartProductId,
                          displayTitle,
                          product.price,
                          firstImg,
                          quantity: quantity,
                          sellerId: product.seller?.id,
                        );

                        Navigator.pop(sheetContext);
                        AppSnackBar.show(
                          context,
                          message: 'Đã thêm $quantity sản phẩm vào giỏ hàng',
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        );
                      }
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
    final authState = context.read<AuthBloc>().state;
    final user = authState.currentUser;

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
              context.read<ProductDetailBloc>().add(
                ProductCommentSent(
                  controller.text,
                  currentUserId: user?.id,
                  currentUserName: user?.username,
                  currentUserAvatar: user?.avatar,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final detailController = TextEditingController();
    final customSubjectController = TextEditingController();

    final presetReasons = [
      'Hàng giả, hàng nhái',
      'Hình ảnh phản cảm, bạo lực',
      'Sản phẩm bị cấm buôn bán',
      'Lừa đảo, thông tin sai sự thật',
      'Lý do khác',
    ];

    String selectedReason = presetReasons.first;

    AppBottomSheet.show<void>(
      context: context,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final showCustomInput = selectedReason == 'Lý do khác';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Báo cáo sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Lý do báo cáo:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: presetReasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          selectedReason = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              if (showCustomInput) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: customSubjectController,
                  label: 'Nhập lý do cụ thể',
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: detailController,
                label: 'Chi tiết báo cáo',
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.bottomCenter,
                child: AppButton(
                  label: 'Gửi báo cáo',
                  onPressed: () {
                    final subject = showCustomInput
                        ? customSubjectController.text.trim()
                        : selectedReason;
                    if (subject.isEmpty) {
                      AppSnackBar.showError(
                        sheetContext,
                        message: 'Vui lòng cung cấp lý do báo cáo',
                      );
                      return;
                    }
                    context.read<ProductDetailBloc>().add(
                      ProductReported(
                        subject: subject,
                        details: detailController.text.trim(),
                      ),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa sản phẩm này không? Thao tác này không thể hoàn tác.',
        ),
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

    context.read<ProductDetailBloc>().add(ProductDeleted());
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
  final String? sellerId;

  const _RatingsSection({required this.productId, this.sellerId});

  @override
  State<_RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<_RatingsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductDetailBloc>().add(ProductRatesRequested(level: 0));
      }
    });
  }

  void _loadRates({bool isInitial = true}) {
    if (isInitial) {
      context.read<ProductDetailBloc>().add(ProductRatesRequested());
    } else {
      context.read<ProductDetailBloc>().add(ProductRatesLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        if (state.errorMessage != null && state.rates.isEmpty) {
          return Center(
            child: Text(state.errorMessage!),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: SectionHeader(title: 'Đánh giá')),
                PopupMenuButton<int>(
                  initialValue: state.selectedStarFilter,
                  onSelected: (star) {
                    context.read<ProductDetailBloc>().add(ProductRatesRequested(level: star));
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Tất cả đánh giá')),
                    ...List.generate(5, (index) {
                      final star = 5 - index;
                      return PopupMenuItem(
                        value: star,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$star'),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          ],
                        ),
                      );
                    }),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.selectedStarFilter == 0
                              ? 'Số sao'
                              : '${state.selectedStarFilter} sao',
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoadingRates)
              const Center(child: CircularProgressIndicator())
            else if (state.rates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Chưa có đánh giá.'),
              )
            else ...[
              ...state.rates.map(
                (r) => Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      splashColor: context.specialTheme.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      highlightColor: context.specialTheme.primaryColor.withValues(
                        alpha: 0.05,
                      ),
                      onTap: () {
                        final authState = context.read<AuthBloc>().state;
                        final token = authState.currentUser?.token ?? '';
                        if (!checkLogin(context, token: token)) {
                          return;
                        }
                        if (r.authorId == null || r.authorId!.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerInfoPage(
                              userId: r.authorId!,
                              sellerName: r.author,
                              avatarUrl: r.avatar,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: AvatarWithFrame(
                          radius: 24,
                          avatarImage: (r.avatar != null && r.avatar!.isNotEmpty)
                              ? SessionManager.getImageProvider(r.avatar!)
                              : null,
                          frameUrl: r.coverImageWeb,
                        ),
                        title: Text(r.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                RatingStars(rating: r.level.toDouble()),
                                const Spacer(),
                                if (r.createdAt != null && r.createdAt!.isNotEmpty)
                                  Text(
                                    _formatDateTime(r.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            if (r.purchaseId != null &&
                                r.purchaseId!.isNotEmpty &&
                                r.purchaseId != '0') ...[
                              const SizedBox(height: 2),
                              Text(
                                'Mã đơn: #${r.purchaseId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              r.content,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isFetchingMoreRates)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.hasMoreRates)
                Center(
                  child: TextButton(
                    onPressed: () => _loadRates(isInitial: false),
                    child: const Text('Xem thêm đánh giá'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

String _formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dt = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (_) {
    return dateStr;
  }
}
