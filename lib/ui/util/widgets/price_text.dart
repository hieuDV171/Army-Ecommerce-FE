import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/special_app_theme.dart';
import '../theme/app_text_styles.dart';

class PriceText extends StatelessWidget {
  final num price;
  final String suffix;
  final Color? color;

  const PriceText({
    super.key,
    required this.price,
    this.suffix = 'xu',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat.decimalPattern('vi_VN').format(price);
    final specialTheme = context.specialTheme;
    
    final textStyle = AppTextStyles.productPrice.copyWith(
      color: color ?? (specialTheme.useGradient ? Colors.white : specialTheme.primaryColor),
    );

    final textWidget = Text(
      '$formattedPrice $suffix',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );

    if (color == null && specialTheme.useGradient) {
      return ShaderMask(
        shaderCallback: (bounds) => specialTheme.primaryGradient!.createShader(bounds),
        child: textWidget,
      );
    }
    return textWidget;
  }
}
