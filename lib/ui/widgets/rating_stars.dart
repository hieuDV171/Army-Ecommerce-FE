import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final icon = rating >= starValue
            ? Icons.star_rounded
            : rating >= starValue - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;

        return Icon(icon, size: size, color: AppColors.warning);
      }),
    );
  }
}
