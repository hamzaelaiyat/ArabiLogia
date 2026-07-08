import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AvatarPickerService {
  final ImagePicker _picker;

  AvatarPickerService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  Future<Uint8List?> pickBytes() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return null;
    return image.readAsBytes();
  }

  Future<Uint8List> processCropped(Uint8List croppedBytes) async {
    final decoded = img.decodeImage(croppedBytes);
    if (decoded == null) throw Exception('غير قادر على قراءة الصورة');
    final resized = img.copyResize(decoded, width: 100, height: 100);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
