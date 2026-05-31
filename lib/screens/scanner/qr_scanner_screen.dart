import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/friend_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final FriendService _friendService = FriendService();
  final GroupService _groupService = GroupService();
  final ApiService _api = ApiService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || !mounted) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      if (value.startsWith('echo://friend/')) {
        final userId = value.substring('echo://friend/'.length);
        if (userId.isNotEmpty) {
          _handleFriendQr(userId);
          return;
        }
      } else if (value.startsWith('echo://group/')) {
        final code = value.substring('echo://group/'.length);
        if (code.isNotEmpty) {
          _handleGroupQr(code.toUpperCase());
          return;
        }
      }
    }
  }

  Future<void> _handleFriendQr(String userId) async {
    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final response = await _api.get('/users/$userId');
      final user = response.data as Map<String, dynamic>;

      if (!mounted) return;

      final nickname = user['nickname'] as String?;
      final phone = user['phone'] as String?;
      final displayName = nickname ?? phone ?? '未知用户';
      final initial = displayName.substring(0, 1).toUpperCase();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('添加好友'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36.r,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 28.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (phone != null) ...[
                SizedBox(height: 4.h),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('添加好友'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _friendService.sendFriendRequestByUserId(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友请求已发送')),
        );
        context.pop();
        return;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  Future<void> _handleGroupQr(String code) async {
    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final group = await _groupService.getGroupByInviteCode(code);

      if (!mounted) return;

      final name = group['name'] as String? ?? '未知群聊';
      final currentMembers = group['currentMembers'] as int? ?? 0;
      final maxMembers = group['maxMembers'] as int? ?? 0;
      final initial = name.substring(0, 1).toUpperCase();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('加入群聊'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36.r,
                backgroundColor: AppTheme.accentColor,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 28.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$currentMembers / $maxMembers 人',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textTertiaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('加入群聊'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _groupService.joinGroupByCode(code);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入群聊成功')),
        );
        context.pop();
        return;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan frame overlay
          Center(
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          // Corner accents
          Center(
            child: SizedBox(
              width: 250.w,
              height: 250.w,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryColor, width: 3),
                          left: BorderSide(color: AppTheme.primaryColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryColor, width: 3),
                          right: BorderSide(color: AppTheme.primaryColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryColor, width: 3),
                          left: BorderSide(color: AppTheme.primaryColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryColor, width: 3),
                          right: BorderSide(color: AppTheme.primaryColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '将二维码放入框内，即可自动扫描',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
