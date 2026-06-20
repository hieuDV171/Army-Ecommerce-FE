import 'package:flutter/material.dart';
import 'package:army_ecommerce/ui/marketplace/product/product_detail_page.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'price_text.dart';
import 'rating_stars.dart';
import 'shimmer_box.dart';
import 'status_chip.dart';

class ProductCardData {
  final String id;
  final String title;
  final num price;
  final String? priceNew;
  final String? priceDiscount;
  final String? bestOffers;
  final String? imageUrl;
  final double? rating;
  final int? soldCount;
  final String? sellerLocation;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final bool isStock;

  const ProductCardData({
    required this.id,
    required this.title,
    required this.price,
    this.priceNew,
    this.priceDiscount,
    this.bestOffers,
    this.imageUrl,
    this.rating,
    this.soldCount,
    this.sellerLocation,
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isStock = true,
  });
}

class ProductCard extends StatelessWidget {
  final ProductCardData product;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(product: product, onLikeTap: onLikeTap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DiscountPriceRow(
                    originalPrice: product.price,
                    priceNew: product.priceNew,
                    bestOffers: product.bestOffers,
                    isVertical: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ProductMeta(product: product, onCommentTap: onCommentTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatefulWidget {
  final ProductCardData product;
  final VoidCallback? onLikeTap;

  const _ProductImage({
    required this.product,
    this.onLikeTap,
  });

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product.imageUrl;
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _scale = 1.15;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPressCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const ColoredBox(
                        color: AppColors.border,
                        child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
                      )
                    : Hero(
                        tag: 'product-image-${widget.product.id}',
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const ShimmerBox(height: double.infinity);
                          },
                          errorBuilder: (context, error, stackTrace) => const ColoredBox(
                            color: AppColors.border,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (widget.onLikeTap != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: GestureDetector(
                onTap: widget.onLikeTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.product.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.product.isLiked ? Colors.red : Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductMeta extends StatelessWidget {
  final ProductCardData product;
  final VoidCallback? onCommentTap;

  const _ProductMeta({
    required this.product,
    this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (product.rating != null) RatingStars(rating: product.rating!, size: 13),
            if (product.soldCount != null)
              Text('Đã bán ${product.soldCount}', style: AppTextStyles.metadata),
            if (product.sellerLocation != null && product.sellerLocation!.isNotEmpty)
              StatusChip(
                label: product.sellerLocation!,
                color: AppColors.tactical,
                icon: Icons.location_on_outlined,
              ),
            StatusChip(
              label: product.isStock ? 'Còn hàng' : 'Hết hàng',
              color: product.isStock ? Colors.green : Colors.red,
              icon: product.isStock ? Icons.check_circle_outline : Icons.remove_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${product.likeCount}', style: AppTextStyles.metadata),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCommentTap ??
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          productId: product.id,
                          isStock: product.isStock,
                          scrollToComments: true,
                        ),
                      ),
                    );
                  },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mode_comment, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text('${product.commentCount}', style: AppTextStyles.metadata),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
