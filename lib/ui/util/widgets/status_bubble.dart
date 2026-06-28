import 'package:flutter/material.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// A custom widget that displays a speech bubble with status text.
/// It supports scrolling if the text is too long.
class StatusBubble extends StatelessWidget {
  final String status;
  final String? title;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const StatusBubble({
    super.key,
    required this.status,
    this.title,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFFF8F8F8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // The bubble body
            Container(
              width: 220,
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        status,
                        style:
                            textStyle ??
                            const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The bubble tail pointing left from the side (middle-left)
            Positioned(
              left: -18,
              bottom: 12,
              child: CustomPaint(
                painter: _BubbleTailPainter(
                  color: bgColor,
                  borderColor: Colors.red.withValues(alpha: 0.3),
                ),
                size: const Size(20, 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    // Horizontal tail pointing left with a sagging (drooping) effect
    path.moveTo(size.width, 0);
    // Upper curve sagging down
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.6,
      0,
      size.height * 0.5,
    );
    // Lower curve sagging down
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 1.2,
      size.width,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Draw the curved border edges
    final borderPath = Path();
    borderPath.moveTo(size.width, 0);
    borderPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.6,
      0,
      size.height * 0.5,
    );
    borderPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width,
      size.height,
    );
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
