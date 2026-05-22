import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import 'shimmer_box.dart';

class ShimmerProductGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerProductGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ShimmerBox(
                height: double.infinity,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(height: 14),
            SizedBox(height: AppSpacing.xs),
            ShimmerBox(width: 92, height: 18),
          ],
        );
      },
    );
  }
}
