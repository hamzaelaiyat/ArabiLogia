import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Captures a Flutter widget subtree as a PNG image byte array.
///
/// Uses [RepaintBoundary] and [RenderRepaintBoundary.toImage] for efficient
/// off-screen rendering, then encodes via the `image` package.
class WidgetImageCaptureService {
  WidgetImageCaptureService._();

  /// Renders the widget subtree inside [boundaryKey] to a [Uint8List] PNG.
  ///
  /// [pixelRatio] controls output resolution (default 3.0 for retina quality).
  static Future<Uint8List?> captureWidget(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Decode and re-encode for consistent output
      final decoded = img.decodeImage(byteData.buffer.asUint8List());
      if (decoded == null) return byteData.buffer.asUint8List();

      return Uint8List.fromList(img.encodePng(decoded));
    } catch (e) {
      debugPrint('WidgetImageCaptureService error: $e');
      return null;
    }
  }

  /// Saves the PNG byte data to a temporary file and returns the [File].
  static Future<File?> saveToTempFile(
    Uint8List pngBytes, {
    String prefix = 'arabilogia_share',
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('WidgetImageCaptureService save error: $e');
      return null;
    }
  }
}
