import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductCardData> products;
  final ValueChanged<ProductCardData>? onProductTap;
  final ValueChanged<ProductCardData>? onLikeTap;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onLikeTap,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => onProductTap?.call(product),
          onLikeTap: () => onLikeTap?.call(product),
        );
      },
    );
  }
}
