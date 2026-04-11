import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 加载图片数据（Web 端实现）
/// 返回 Uint8List
Future<dynamic> loadImageData(XFile pickedFile) async {
  return await pickedFile.readAsBytes();
}

/// 构建图片 Widget（Web 端实现）
/// 使用 Image.memory
Widget buildImageWidget(dynamic imageData, double height) {
  return Image.memory(
    imageData as Uint8List,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
  );
}
