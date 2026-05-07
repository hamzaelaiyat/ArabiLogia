import 'package:flutter/material.dart';
import 'dart:io';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ZoomableImageViewer extends StatefulWidget {
  final String imagePath;
  final String? title;

  const ZoomableImageViewer({
    super.key,
    required this.imagePath,
    this.title,
  });

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateZoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.5).clamp(1.0, 4.0);
    _animateToScale(newScale);
  }

  void _animateZoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.5).clamp(1.0, 4.0);
    _animateToScale(newScale);
  }

  void _animateToScale(double targetScale) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    
    final scaleFactor = targetScale / currentScale;
    final targetMatrix = currentMatrix.clone()..scale(scaleFactor);
    
    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
    
    _animationController.forward(from: 0);
  }

  void _resetZoom() {
    _animateToScale(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    final isFile = widget.imagePath.startsWith('/') || widget.imagePath.contains('/');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title ?? 'الصورة',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تعيين',
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: isFile
                  ? Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      widget.imagePath,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'تعذر تحميل الصورة',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ZoomButton(
                    icon: Icons.zoom_out,
                    onPressed: _animateZoomOut,
                    label: 'تصغير',
                  ),
                  _ZoomButton(
                    icon: Icons.zoom_in,
                    onPressed: _animateZoomIn,
                    label: 'تكبير',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'اسحب للتكبير والتصغير',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppTokens.fontSizeXs,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}