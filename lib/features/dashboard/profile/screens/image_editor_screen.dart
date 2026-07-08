import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageEditorScreen({super.key, required this.imageBytes});

  static Future<Uint8List?> show(BuildContext context, Uint8List imageBytes) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(imageBytes: imageBytes),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  ui.Image? _uiImage;
  int _originalWidth = 0;
  int _originalHeight = 0;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _lastScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;

  Size _displaySize = Size.zero;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final decoded = img.decodeImage(widget.imageBytes);
    if (decoded == null) return;
    _originalWidth = decoded.width;
    _originalHeight = decoded.height;

    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    if (mounted) setState(() {});
  }

  void _calculateLayout(Size viewport) {
    if (_originalWidth == 0 || _originalHeight == 0) return;
    _viewportSize = viewport;
    final imageW = _originalWidth.toDouble();
    final imageH = _originalHeight.toDouble();
    final viewportAspect = viewport.width / viewport.height;
    final imageAspect = imageW / imageH;

    if (imageAspect > viewportAspect) {
      _displaySize = Size(viewport.width, viewport.width / imageAspect);
    } else {
      _displaySize = Size(viewport.height * imageAspect, viewport.height);
    }
  }

  Rect get _imageRect {
    final left = (_viewportSize.width - _displaySize.width * _scale) / 2 + _offset.dx;
    final top = (_viewportSize.height - _displaySize.height * _scale) / 2 + _offset.dy;
    return Rect.fromLTWH(
      left, top,
      _displaySize.width * _scale,
      _displaySize.height * _scale,
    );
  }

  Rect get _cropRect {
    final cropSize = math.min(_viewportSize.width, _viewportSize.height) * 0.8;
    return Rect.fromCenter(
      center: Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      width: cropSize,
      height: cropSize,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = _scale;
    _lastFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_lastScale * details.scale).clamp(_minScale, _maxScale);
      _offset = _offset + (details.focalPoint - _lastFocalPoint);
      _lastFocalPoint = details.focalPoint;
    });
  }

  Uint8List? _crop() {
    if (_originalWidth == 0 || _originalHeight == 0) return null;
    final original = img.decodeImage(widget.imageBytes);
    if (original == null) return null;

    final imageRect = _imageRect;
    final cropRect = _cropRect;

    final relLeft = cropRect.left - imageRect.left;
    final relTop = cropRect.top - imageRect.top;

    final scaleX = _originalWidth / (_displaySize.width * _scale);
    final scaleY = _originalHeight / (_displaySize.height * _scale);

    int x = (relLeft * scaleX).round();
    int y = (relTop * scaleY).round();
    int w = (cropRect.width * scaleX).round();
    int h = (cropRect.height * scaleY).round();

    x = x.clamp(0, _originalWidth);
    y = y.clamp(0, _originalHeight);
    w = w.clamp(1, _originalWidth - x);
    h = h.clamp(1, _originalHeight - y);

    if (w <= 0 || h <= 0) return null;

    final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'قص الصورة',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              final result = _crop();
              Navigator.pop(context, result);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_viewportSize != constraints.biggest) {
            _calculateLayout(constraints.biggest);
          }
          if (_uiImage == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Stack(
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: CustomPaint(
                        painter: _ImagePainter(
                          image: _uiImage!,
                          imageRect: _imageRect,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CropMaskPainter(cropRect: _cropRect),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: _scale,
                min: _minScale,
                max: _maxScale,
                divisions: 40,
                label: '${(_scale * 100).round()}%',
                onChanged: (v) => setState(() => _scale = v),
              ),
            ),
          ),
          const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${(_scale * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final Rect imageRect;

  _ImagePainter({required this.image, required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter old) =>
      old.image != image || old.imageRect != imageRect;
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;

  _CropMaskPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect);

    canvas.drawPath(path, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(cropRect, borderPaint);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        guidePaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CropMaskPainter old) => old.cropRect != cropRect;
}
