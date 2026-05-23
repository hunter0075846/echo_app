import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/user_avatar.dart';

class FriendNotificationScreen extends StatefulWidget {
  const FriendNotificationScreen({super.key});

  @override
  State<FriendNotificationScreen> createState() => _FriendNotificationScreenState();
}

class _FriendNotificationScreenState extends State<FriendNotificationScreen> {
  final FriendService _friendService = FriendService();
  List<FriendInviteModel> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    setState(() => _isLoading = true);
    try {
      final invites = await _friendService.getFriendInvites();
      if (mounted) {
        setState(() {
          _invites = invites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _handleAccept(String friendId) async {
    try {
      await _friendService.acceptFriendRequest(friendId);
      await _loadInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加好友')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(String friendId) async {
    try {
      await _friendService.rejectFriendRequest(friendId);
      await _loadInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已拒绝')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  String _getStatusText(FriendInviteModel invite) {
    if (invite.direction == 'received') {
      switch (invite.status) {
        case 'pending':
          return '请求添加你为好友';
        case 'accepted':
          return '已成为好友';
        case 'rejected':
          return '已拒绝';
        default:
          return '';
      }
    } else {
      switch (invite.status) {
        case 'pending':
          return '等待对方确认';
        case 'accepted':
          return '对方已接受';
        case 'rejected':
          return '对方已拒绝';
        default:
          return '';
      }
    }
  }

  Widget _buildStatusBadge(FriendInviteModel invite) {
    Color color;
    String text;

    if (invite.direction == 'sent') {
      switch (invite.status) {
        case 'pending':
          color = AppTheme.warningColor;
          text = '等待确认';
          break;
        case 'accepted':
          color = AppTheme.successColor;
          text = '已接受';
          break;
        case 'rejected':
          color = AppTheme.errorColor;
          text = '已拒绝';
          break;
        default:
          color = AppTheme.textSecondaryColor;
          text = invite.status;
      }
    } else {
      switch (invite.status) {
        case 'pending':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _handleReject(invite.userId),
                child: Text(
                  '拒绝',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
              SizedBox(width: 4.w),
              ElevatedButton(
                onPressed: () => _handleAccept(invite.userId),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: const Text('接受'),
              ),
            ],
          );
        case 'accepted':
          color = AppTheme.successColor;
          text = '已成为好友';
          break;
        case 'rejected':
          color = AppTheme.errorColor;
          text = '已拒绝';
          break;
        default:
          color = AppTheme.textSecondaryColor;
          text = invite.status;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知消息'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _invites.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _invites.length,
                    itemBuilder: (context, index) {
                      final invite = _invites[index];
                      return _buildInviteItem(invite);
                    },
                  ),
      ),
    );
  }

  Widget _buildInviteItem(FriendInviteModel invite) {
    final isReceivedPending = invite.direction == 'received' && invite.status == 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: isReceivedPending
            ? null
            : () => context.push('/friend/detail/${invite.userId == invite.friendId ? invite.friendId : invite.userId}'),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              UserAvatar(
                id: invite.userId == invite.friendId ? invite.friendId : invite.userId,
                name: invite.nickname,
                imageUrl: invite.avatar,
                size: 48,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.nickname ?? invite.phone,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getStatusText(invite),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatTime(invite.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(invite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64.w,
            color: AppTheme.textTertiaryColor,
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无通知消息',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
