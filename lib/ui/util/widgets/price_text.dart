import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_text_styles.dart';

class PriceText extends StatelessWidget {
  final num price;
  final String suffix;

  const PriceText({
    super.key,
    required this.price,
    this.suffix = 'xu',
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat.decimalPattern('vi_VN').format(price);
    return Text(
      '$formattedPrice $suffix',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.productPrice,
    );
  }
}
