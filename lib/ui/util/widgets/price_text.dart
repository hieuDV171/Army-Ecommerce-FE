import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/special_app_theme.dart';
import '../theme/app_text_styles.dart';

class PriceText extends StatelessWidget {
  final num price;
  final String suffix;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const PriceText({
    super.key,
    required this.price,
    this.suffix = 'xu',
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat.decimalPattern('vi_VN').format(price);
    final specialTheme = context.specialTheme;
    
    final textStyle = AppTextStyles.productPrice.copyWith(
      color: color ?? (specialTheme.useGradient ? Colors.white : specialTheme.primaryColor),
      fontSize: fontSize,
      fontWeight: fontWeight,
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

class DiscountPriceRow extends StatelessWidget {
  final num originalPrice;
  final String? priceNew;
  final String? bestOffers;
  final double fontSize;
  final Color? priceColor;
  final bool isVertical;

  const DiscountPriceRow({
    super.key,
    required this.originalPrice,
    this.priceNew,
    this.bestOffers,
    this.fontSize = 14,
    this.priceColor,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceNewNumber = num.tryParse(priceNew ?? '');
    final hasPriceNew = priceNewNumber != null && priceNewNumber > 0;
    
    num discountedPrice = originalPrice;
    if (hasPriceNew && priceNewNumber < originalPrice) {
      discountedPrice = priceNewNumber;
    } else if (bestOffers != null && bestOffers!.isNotEmpty && bestOffers != '[]') {
      final clean = bestOffers!
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .trim();
      final numVal = num.tryParse(clean);
      if (numVal != null) {
        if (numVal <= 100) {
          discountedPrice = originalPrice * (1 - numVal / 100);
        } else {
          discountedPrice = (originalPrice - numVal).clamp(0, originalPrice);
        }
      }
    }

    final formattedOriginal = NumberFormat.decimalPattern('vi_VN').format(originalPrice);

    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PriceText(
            price: discountedPrice,
            color: priceColor,
          ),
          const SizedBox(height: 2),
          Text(
            '$formattedOriginal xu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[500],
              fontSize: fontSize - 2,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PriceText(
          price: discountedPrice,
          color: priceColor,
        ),
        const SizedBox(width: 6),
        Text(
          '$formattedOriginal xu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey[500],
            fontSize: fontSize - 2,
          ),
        ),
      ],
    );
  }
}
