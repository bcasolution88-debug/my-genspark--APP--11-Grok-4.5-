import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final Uint8List bytes;
  final String name;
  PickedImage(this.bytes, this.name);
}

/// 跨平台图片选择（Web / Android 均支持）
class FilePickerService {
  static final _picker = ImagePicker();

  static Future<PickedImage?> pickImage({bool fromCamera = false}) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedImage(await file.readAsBytes(), file.name);
  }
}
