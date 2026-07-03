import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class AvatarPickerService {
  final ImagePicker _picker;
  final ImageCropper _cropper;

  AvatarPickerService({
    ImagePicker? picker,
    ImageCropper? cropper,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  Future<Uint8List?> pickAndProcessAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return null;

    final Uint8List? croppedBytes = await _cropImage(image);
    if (croppedBytes == null) return null;

    final decoded = img.decodeImage(croppedBytes);
    if (decoded == null) throw Exception('غير قادر على قراءة الصورة');

    final resized = img.copyResize(decoded, width: 100, height: 100);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<Uint8List?> _cropImage(XFile image) async {
    const bool isWeb = kIsWeb;
    final bool isDesktop =
        !isWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    if (!isDesktop && !isWeb) {
      final croppedFile = await _cropper.cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile == null) return null;
      return await croppedFile.readAsBytes();
    }

    final originalBytes = await image.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) throw Exception('غير قادر على قراءة الصورة');

    final size =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    final x = (decoded.width - size) ~/ 2;
    final y = (decoded.height - size) ~/ 2;
    final cropped =
        img.copyCrop(decoded, x: x, y: y, width: size, height: size);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  }
}
