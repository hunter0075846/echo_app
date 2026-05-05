import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color_tokens.dart';

/// 用户头像组件
///
/// 默认显示姓氏首字母 + 品牌渐变背景。
/// 若提供了 [imageUrl]，优先显示网络图片。
/// 渐变根据 [id] 或 [name] 的 hash 选取，保证同一用户始终同一颜色。
class UserAvatar extends StatelessWidget {
  final String? id;
  final String? name;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.id,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.onTap,
  });

  String get _initial {
    if (name == null || name!.isEmpty) return '?';
    return name![0].toUpperCase();
  }

  List<Color> get _gradient {
    if (id != null && id!.isNotEmpty) {
      return EchoColors.gradientForId(id!);
    }
    return EchoColors.gradientForString(name);
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gradient[0].withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: (size * 0.45).sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size.w,
          height: size.w,
          fit: BoxFit.cover,
          placeholder: (context, url) => avatar,
          errorWidget: (context, url, error) => avatar,
        ),
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
