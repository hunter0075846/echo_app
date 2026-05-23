import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/user_avatar.dart';

class FriendDetailScreen extends StatefulWidget {
  final String userId;
  final String? nickname;
  final String? avatar;

  const FriendDetailScreen({
    super.key,
    required this.userId,
    this.nickname,
    this.avatar,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  final FriendService _friendService = FriendService();
  bool _isDeleting = false;

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 ${widget.nickname ?? widget.userId} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await _friendService.deleteFriend(widget.userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除好友')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isDeleting = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.nickname ?? '用户';

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友详情'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 用户信息卡片
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  UserAvatar(
                    id: widget.userId,
                    name: widget.nickname,
                    imageUrl: widget.avatar,
                    size: 80,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'ID: ${widget.userId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // 二维码卡片
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Text(
                    '好友二维码',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '扫一扫添加该好友',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  QrImageView(
                    data: 'echo://friend/${widget.userId}',
                    version: QrVersions.auto,
                    size: 180.w,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 操作按钮
          ElevatedButton.icon(
            onPressed: () {
              context.push('/chat/${widget.userId}', extra: {
                'userId': widget.userId,
                'nickname': widget.nickname,
                'avatar': widget.avatar,
              });
            },
            icon: const Icon(Icons.message),
            label: const Text('发消息'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),

          SizedBox(height: 12.h),

          OutlinedButton.icon(
            onPressed: _isDeleting ? null : _showDeleteConfirm,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            label: Text(
              '删除好友',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
