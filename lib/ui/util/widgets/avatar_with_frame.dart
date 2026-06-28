import 'dart:io';

import 'package:flutter/material.dart';

/// Widget hiển thị avatar có khung viền overlay từ [frameUrl] hoặc [frameFile].
///
/// [frameUrl] hoặc [frameFile] nên là ảnh PNG có nền trong suốt (transparent background)
/// với lỗ tròn ở giữa (donut shape) để avatar hiển thị qua.
/// Nếu cả hai đều null, chỉ hiển thị avatar bình thường.
class AvatarWithFrame extends StatelessWidget {
  final ImageProvider? avatarImage;
  final String? frameUrl;
  final File? frameFile;
  final double radius;
  final Widget? fallbackChild;
  final VoidCallback? onTap;

  const AvatarWithFrame({
    super.key,
    this.avatarImage,
    this.frameUrl,
    this.frameFile,
    this.radius = 40.0,
    this.fallbackChild,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double totalSize = radius * 2;
    // Frame được scale lớn hơn avatar một chút để tạo hiệu ứng viền
    final double frameSize = totalSize * 1.18;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundImage: avatarImage,
      child: avatarImage == null
          ? (fallbackChild ??
                Icon(Icons.person, size: radius * 0.8, color: Colors.grey))
          : null,
    );

    final bool hasFrame =
        (frameUrl != null && frameUrl!.isNotEmpty) || (frameFile != null);

    if (!hasFrame) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    Widget frameImageWidget;
    if (frameFile != null) {
      frameImageWidget = Image.file(
        frameFile!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    } else {
      frameImageWidget = Image.network(
        frameUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Avatar ở dưới
            avatar,
            // Frame overlay ở trên — chúng ta đục lỗ giữa để đảm bảo thấy avatar
            Positioned.fill(
              child: ClipPath(clipper: DonutClipper(), child: frameImageWidget),
            ),
          ],
        ),
      ),
    );
  }
}

class DonutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Vòng ngoài: hình tròn bao quanh toàn bộ frame
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2;

    path.addOval(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: outerRadius),
    );

    // Vòng trong: hình tròn ở giữa để "đục lỗ"
    // Chúng ta dùng PathFillType.evenOdd để tạo hiệu ứng donut
    // Bán kính lỗ hổng khoảng 42% kích thước frame (tương đương với size của avatar bên dưới)
    final double innerRadius = size.width * 0.42;

    path.addOval(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: innerRadius),
    );
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
