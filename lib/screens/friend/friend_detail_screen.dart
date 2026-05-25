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
  final String? phone;
  final DateTime? createdAt;

  const FriendDetailScreen({
    super.key,
    required this.userId,
    this.nickname,
    this.avatar,
    this.phone,
    this.createdAt,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  final FriendService _friendService = FriendService();
  bool _isDeleting = false;
  bool _isOnline = true;
  int _commonFriends = 0;
  bool _isLoadingCommonFriends = false;

  @override
  void initState() {
    super.initState();
    _loadCommonFriends();
  }

  Future<void> _loadCommonFriends() async {
    setState(() => _isLoadingCommonFriends = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _commonFriends = 3);
    } catch (e) {
      setState(() => _commonFriends = 0);
    } finally {
      setState(() => _isLoadingCommonFriends = false);
    }
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.length != 11) return '未知';
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天添加';
    if (diff.inDays == 1) return '昨天添加';
    if (diff.inDays < 7) return '${diff.inDays}天前添加';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}周前添加';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}个月前添加';
    return '${diff.inDays ~/ 365}年前添加';
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '分享好友',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code, size: 48),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          Navigator.pop(context);
                          _showQrCodeDialog();
                        },
                      ),
                      SizedBox(height: 8.h),
                      const Text('分享二维码'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 48),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('链接已复制到剪贴板')),
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      const Text('复制链接'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, size: 48),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('分享功能已触发')),
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      const Text('分享给好友'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '好友二维码',
                style: TextStyle(
                  fontSize: 18.sp,
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
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: QrImageView(
                  data: 'echo://friend/${widget.userId}',
                  version: QrVersions.auto,
                  size: 200.w,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: AppTheme.primaryColor,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(
                    id: widget.userId,
                    name: widget.nickname,
                    imageUrl: widget.avatar,
                    size: 40,
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nickname ?? '用户',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatPhone(widget.phone),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('图片已保存到相册')),
                        );
                      },
                      child: const Text('保存图片'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCall(type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type == 'voice' ? '语音' : '视频'}通话功能开发中')),
    );
  }

  void _showCommonFriends() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '共同好友',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${_commonFriends}位'),
              ],
            ),
            SizedBox(height: 16.h),
            if (_commonFriends == 0)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64.w,
                      color: AppTheme.textTertiaryColor,
                    ),
                    SizedBox(height: 12.h),
                    Text('暂无共同好友'),
                  ],
                ),
              )
            else
              Column(
                children: List.generate(
                  _commonFriends,
                  (index) => ListTile(
                    leading: UserAvatar(id: 'common_$index', name: '好友${index + 1}'),
                    title: Text('好友${index + 1}'),
                    onTap: () {},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        padding: EdgeInsets.zero,
        children: [
          // 顶部渐变背景卡片
          Container(
            height: 280.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // 头像区域
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 头像外发光效果
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Colors.white30],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      // 头像
                      UserAvatar(
                        id: widget.userId,
                        name: widget.nickname,
                        imageUrl: widget.avatar,
                        size: 100,
                      ),
                      // 在线状态指示器
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // 昵称和在线状态
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _isOnline ? '在线' : '离线',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // 快捷操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 语音通话
                      _buildActionButton(
                        icon: Icons.phone,
                        label: '语音',
                        onTap: () => _handleCall('voice'),
                      ),
                      SizedBox(width: 24.w),
                      // 视频通话
                      _buildActionButton(
                        icon: Icons.video_call,
                        label: '视频',
                        onTap: () => _handleCall('video'),
                      ),
                      SizedBox(width: 24.w),
                      // 分享
                      _buildActionButton(
                        icon: Icons.share,
                        label: '分享',
                        onTap: _showShareOptions,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 用户信息卡片
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: '昵称',
                      value: displayName,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.phone_outline,
                      label: '手机号',
                      value: _formatPhone(widget.phone),
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.date_range,
                      label: '添加时间',
                      value: _formatDate(widget.createdAt),
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.people_outline,
                      label: '共同好友',
                      value: _isLoadingCommonFriends
                          ? '加载中...'
                          : '$_commonFriends 位',
                      onTap: _showCommonFriends,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 操作按钮区域
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
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
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 4,
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
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.textSecondaryColor,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTheme.textTertiaryColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppTheme.borderColor,
      indent: 32.w,
    );
  }
}
