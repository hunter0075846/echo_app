import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/user_avatar.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  final FriendService _friendService = FriendService();
  List<FriendModel> _friends = [];
  List<FriendRequestModel> _requests = [];
  bool _isLoading = true;
  bool _showAddDialog = false;
  String _phoneInput = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      _friends = await _friendService.getFriends();
      _requests = await _friendService.getFriendRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendRequest() async {
    if (_phoneInput.isEmpty) return;
    try {
      await _friendService.sendFriendRequest(_phoneInput);
      setState(() {
        _showAddDialog = false;
        _phoneInput = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友请求已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest(String userId) async {
    try {
      await _friendService.acceptFriendRequest(userId);
      await _loadFriends();
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

  Future<void> _handleRejectRequest(String userId) async {
    try {
      await _friendService.rejectFriendRequest(userId);
      await _loadFriends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  String _formatPhone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _showAddDialog = true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (_requests.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      '好友请求 (${_requests.length})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  ..._requests.map((request) => _buildRequestItem(request)),
                  SizedBox(height: 16.h),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    '我的好友 (${_friends.length})',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (_friends.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: Column(
                        children: [
                          Icon(Icons.people, size: 64.w, color: AppTheme.textTertiaryColor),
                          SizedBox(height: 16.h),
                          Text(
                            '暂无好友',
                            style: TextStyle(color: AppTheme.textTertiaryColor),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '点击右上角添加好友',
                            style: TextStyle(fontSize: 12.sp, color: AppTheme.textTertiaryColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._friends.map((friend) => _buildFriendItem(friend)),
              ],
            ),
      bottomSheet: _showAddDialog
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '添加好友',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                    ),
                    onChanged: (value) => _phoneInput = value,
                    autofocus: true,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _showAddDialog = false),
                          child: const Text('取消'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSendRequest,
                          child: const Text('发送请求'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildRequestItem(FriendRequestModel request) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            UserAvatar(
              id: request.userId,
              name: request.nickname,
              imageUrl: request.avatar,
              size: 48,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.nickname ?? _formatPhone(request.phone),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '请求添加你为好友',
                    style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Row(
              children: [
                TextButton(
                  onPressed: () => _handleRejectRequest(request.userId),
                  child: Text('拒绝', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () => _handleAcceptRequest(request.userId),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: const Text('接受'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(FriendModel friend) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () {
          context.push('/chat/${friend.friendId}', extra: {
            'userId': friend.friendId,
            'nickname': friend.nickname,
            'avatar': friend.avatar,
          });
        },
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              UserAvatar(
                id: friend.friendId,
                name: friend.nickname,
                imageUrl: friend.avatar,
                size: 48,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.nickname ?? _formatPhone(friend.phone),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '好友',
                      style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirm(context, friend);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 8.w),
                        const Text('删除好友', style: TextStyle(color: AppTheme.errorColor)),
                      ],
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

  void _showDeleteConfirm(BuildContext context, FriendModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 ${friend.nickname ?? _formatPhone(friend.phone)} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _friendService.deleteFriend(friend.friendId);
                await _loadFriends();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除好友')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}