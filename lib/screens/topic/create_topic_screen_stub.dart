import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 加载图片数据（存根）
/// 在移动端返回 File，在 Web 端返回 Uint8List
Future<dynamic> loadImageData(XFile pickedFile) async {
  throw UnsupportedError('Platform not supported');
}

/// 构建图片 Widget（存根）
/// 在移动端使用 Image.file，在 Web 端使用 Image.memory
Widget buildImageWidget(dynamic imageData, double height) {
  throw UnsupportedError('Platform not supported');
}
