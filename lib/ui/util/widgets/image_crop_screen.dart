import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageCropScreen extends StatefulWidget {
  final File imageFile;
  final bool isCircle;
  final double aspectRatio;
  final String title;

  const ImageCropScreen({
    super.key,
    required this.imageFile,
    this.isCircle = true,
    this.aspectRatio = 1.0,
    required this.title,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  late Future<ui.Image> _imageLoader;
  final TransformationController _transformationController = TransformationController();
  
  double _currentScale = 1.0;
  int _rotationQuarterTurns = 0;
  bool _isSaving = false;

  // Layout sizes computed in LayoutBuilder
  double _wView = 0.0;
  double _hView = 0.0;
  double _wCrop = 0.0;
  double _hCrop = 0.0;
  double _xCrop = 0.0;
  double _yCrop = 0.0;
  
  double _wImg = 0.0;
  double _hImg = 0.0;
  double _xImg = 0.0;
  double _yImg = 0.0;

  @override
  void initState() {
    super.initState();
    _imageLoader = _loadImage(widget.imageFile);
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (mounted) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  Future<ui.Image> _loadImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _calculateLayout(ui.Image image, double maxWidth, double maxHeight) {
    _wView = maxWidth;
    _hView = maxHeight;

    // Crop box dimensions
    if (widget.isCircle) {
      final size = math.min(_wView, _hView) * 0.75;
      _wCrop = size;
      _hCrop = size;
    } else {
      // Rectangular crop box
      _wCrop = _wView * 0.85;
      _hCrop = _wCrop / widget.aspectRatio;
      
      // Ensure height fits comfortably within viewport
      if (_hCrop > _hView * 0.7) {
        _hCrop = _hView * 0.7;
        _wCrop = _hCrop * widget.aspectRatio;
      }
    }

    _xCrop = (_wView - _wCrop) / 2;
    _yCrop = (_hView - _hCrop) / 2;

    // effective original size under current rotation
    final bool isRotated = _rotationQuarterTurns % 2 == 1;
    final double origW = isRotated ? image.height.toDouble() : image.width.toDouble();
    final double origH = isRotated ? image.width.toDouble() : image.height.toDouble();

    // Fitted size (covering the crop box)
    final double initialScale = math.max(_wCrop / origW, _hCrop / origH);
    _wImg = origW * initialScale;
    _hImg = origH * initialScale;

    _xImg = (_wView - _wImg) / 2;
    _yImg = (_hView - _hImg) / 2;
  }

  void _resetCrop() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _onScaleChanged(double newScale) {
    final double centerX = _wView / 2;
    final double centerY = _hView / 2;
    
    final Matrix4 currentMatrix = _transformationController.value;
    final double oldScale = currentMatrix.getMaxScaleOnAxis();
    final double oldTx = currentMatrix.storage[12];
    final double oldTy = currentMatrix.storage[13];
    
    final double childCenterX = (centerX - oldTx) / oldScale;
    final double childCenterY = (centerY - oldTy) / oldScale;
    
    final double newTx = centerX - childCenterX * newScale;
    final double newTy = centerY - childCenterY * newScale;
    
    final Matrix4 newMatrix = Matrix4.identity();
    newMatrix.setEntry(0, 0, newScale);
    newMatrix.setEntry(1, 1, newScale);
    newMatrix.setEntry(0, 3, newTx);
    newMatrix.setEntry(1, 3, newTy);
    _transformationController.value = newMatrix;
  }

  Future<void> _confirmCrop(ui.Image image) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Rendering resolution scale (3x crop box size for high resolution)
      const double renderPixelRatio = 3.0;
      final double outW = _wCrop * renderPixelRatio;
      final double outH = _hCrop * renderPixelRatio;

      canvas.scale(renderPixelRatio);
      canvas.translate(-_xCrop, -_yCrop);

      // Apply the translation & scale matrix from controller
      canvas.transform(_transformationController.value.storage);

      // Center of the image layout container in child space
      final double cx = _xImg + _wImg / 2;
      final double cy = _yImg + _hImg / 2;

      canvas.translate(cx, cy);
      canvas.rotate(_rotationQuarterTurns * math.pi / 2);

      final bool isRotated = _rotationQuarterTurns % 2 == 1;
      final double origW = isRotated ? _hImg : _wImg;
      final double origH = isRotated ? _wImg : _hImg;

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTRB(-origW / 2, -origH / 2, origW / 2, origH / 2),
        paint,
      );

      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(outW.toInt(), outH.toInt());
      final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      final croppedFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
      await croppedFile.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cropping image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cắt ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Đặt lại',
            icon: const Icon(Icons.refresh),
            onPressed: _resetCrop,
          ),
          IconButton(
            tooltip: 'Xoay 90°',
            icon: const Icon(Icons.rotate_right),
            onPressed: _rotateImage,
          ),
        ],
      ),
      body: FutureBuilder<ui.Image>(
        future: _imageLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Không thể tải ảnh', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          final image = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              _calculateLayout(image, constraints.maxWidth, constraints.maxHeight);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Interactive image viewport
                  InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 6.0,
                    clipBehavior: Clip.none,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox(
                      width: _wView,
                      height: _hView,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: _xImg,
                            top: _yImg,
                            width: _wImg,
                            height: _hImg,
                            child: RotatedBox(
                              quarterTurns: _rotationQuarterTurns,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Translucent crop area overlay mask
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CropMaskPainter(
                        cropRect: Rect.fromLTWH(_xCrop, _yCrop, _wCrop, _hCrop),
                        isCircle: widget.isCircle,
                      ),
                      size: Size.infinite,
                    ),
                  ),

                  // 3. UI Controls Glassmorphic bottom panel
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Scale slider
                            Row(
                              children: [
                                const Icon(Icons.zoom_out, color: Colors.white54, size: 18),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.blue.shade400,
                                      inactiveTrackColor: Colors.white12,
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.blue.withValues(alpha: 0.12),
                                    ),
                                    child: Slider(
                                      value: _currentScale.clamp(1.0, 6.0),
                                      min: 1.0,
                                      max: 6.0,
                                      onChanged: _onScaleChanged,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.zoom_in, color: Colors.white54, size: 18),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : () => _confirmCrop(image),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  final bool isCircle;

  _CropMaskPainter({required this.cropRect, required this.isCircle});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final cutout = isCircle
        ? (Path()..addOval(cropRect))
        : (Path()..addRect(cropRect));

    // Difference leaves the outside area dark
    final maskPath = Path.combine(PathOperation.difference, path, cutout);
    
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    // Draw viewport glowing border
    canvas.drawPath(
      cutout,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Add subtle corner highlights if rectangular
    if (!isCircle) {
      final double strokeLen = 16.0;
      final double thickness = 3.5;
      final borderPaint = Paint()
        ..color = Colors.blue.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness;

      // Top-Left
      canvas.drawPath(
        Path()
          ..moveTo(cropRect.left, cropRect.top + strokeLen)
          ..lineTo(cropRect.left, cropRect.top)
          ..lineTo(cropRect.left + strokeLen, cropRect.top),
        borderPaint,
      );
      // Top-Right
      canvas.drawPath(
        Path()
          ..moveTo(cropRect.right - strokeLen, cropRect.top)
          ..lineTo(cropRect.right, cropRect.top)
          ..lineTo(cropRect.right, cropRect.top + strokeLen),
        borderPaint,
      );
      // Bottom-Left
      canvas.drawPath(
        Path()
          ..moveTo(cropRect.left, cropRect.bottom - strokeLen)
          ..lineTo(cropRect.left, cropRect.bottom)
          ..lineTo(cropRect.left + strokeLen, cropRect.bottom),
        borderPaint,
      );
      // Bottom-Right
      canvas.drawPath(
        Path()
          ..moveTo(cropRect.right - strokeLen, cropRect.bottom)
          ..lineTo(cropRect.right, cropRect.bottom)
          ..lineTo(cropRect.right, cropRect.bottom - strokeLen),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropMaskPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.isCircle != isCircle;
  }
}
