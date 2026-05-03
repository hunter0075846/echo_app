import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/assistant_chat_provider.dart';
import '../theme/app_theme.dart';

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final VoidCallback? onRetry;
  final VoidCallback? onForward;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onRetry,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16.h,
          left: message.isUser ? 64.w : 0,
          right: message.isUser ? 0 : 64.w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI 头像
            if (!message.isUser) ...[
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '安',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],

            // 失败图标
            if (message.status == MessageStatus.failed && !message.isUser)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 18.w,
                ),
              ),

            Flexible(
              child: GestureDetector(
                onLongPress: () => _showActionSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      if (!message.isUser)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content.isEmpty && isStreaming && !message.isUser
                            ? '...'
                            : message.content,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: message.isUser
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                      if (isStreaming &&
                          !message.isUser &&
                          message.status != MessageStatus.failed)
                        Text(
                          '▍',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制')),
                  );
                },
              ),
              if (!message.isUser &&
                  !message.isWelcome &&
                  message.status == MessageStatus.sent)
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('转发到群'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onForward?.call();
                  },
                ),
              if (message.status == MessageStatus.failed)
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.red),
                  title: const Text('重试', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRetry?.call();
                  },
                ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }
}
