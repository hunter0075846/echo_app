import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 加载图片数据（移动端实现）
/// 返回 File 对象
Future<dynamic> loadImageData(XFile pickedFile) async {
  return File(pickedFile.path);
}

/// 构建图片 Widget（移动端实现）
/// 使用 Image.file
Widget buildImageWidget(dynamic imageData, double height) {
  return Image.file(
    imageData as File,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
  );
}
