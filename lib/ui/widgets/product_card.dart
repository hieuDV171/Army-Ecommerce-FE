import 'package:flutter/material.dart';

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
  final String? imageUrl;
  final double? rating;
  final int? soldCount;
  final String? sellerLocation;
  final bool isLiked;

  const ProductCardData({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    this.rating,
    this.soldCount,
    this.sellerLocation,
    this.isLiked = false,
  });
}

class ProductCard extends StatelessWidget {
  final ProductCardData product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
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
            _ProductImage(product: product),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PriceText(price: product.price),
                  const SizedBox(height: AppSpacing.sm),
                  _ProductMeta(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductCardData product;

  const _ProductImage({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? const ColoredBox(
                    color: AppColors.border,
                    child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
                  )
                : Hero(
                    tag: 'product-image-${product.id}',
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
      ],
    );
  }
}

class _ProductMeta extends StatelessWidget {
  final ProductCardData product;

  const _ProductMeta({required this.product});

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
      ],
    );
  }
}
