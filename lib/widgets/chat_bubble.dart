import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/assistant_chat_provider.dart';
import '../theme/app_theme.dart';
import 'avatars/ai_avatar.dart';

/// 聊天气泡组件
///
/// 用户消息：主色渐变背景 + 白色文字 + 不对称圆角
/// AI 消息：毛玻璃背景 + 精致阴影 + 不对称圆角
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
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16.h,
          left: isUser ? 64.w : 0,
          right: isUser ? 0 : 64.w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI 头像
            if (!isUser) ...[
              AIAvatar(size: 36.w),
              SizedBox(width: 8.w),
            ],

            // 失败图标
            if (message.status == MessageStatus.failed && !isUser)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 18.w,
                ),
              ),

            Flexible(
              child: GestureDetector(
                onLongPress: () => _showActionSheet(context),
                child: isUser
                    ? _buildUserBubble(context)
                    : _buildAIBubble(context, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(4.r),
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: _buildMessageText(Colors.white),
    );
  }

  Widget _buildAIBubble(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(4.r),
        topRight: Radius.circular(16.r),
        bottomLeft: Radius.circular(16.r),
        bottomRight: Radius.circular(16.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.surfaceColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? AppTheme.borderColor.withValues(alpha: 0.3)
                  : AppTheme.borderColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.04 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildMessageText(AppTheme.textPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildMessageText(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.content.isEmpty &&
            isStreaming &&
            !message.isUser)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingIndicator(),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
              if (isStreaming &&
                  !message.isUser &&
                  message.status != MessageStatus.failed)
                _BlinkingCursor(textColor: textColor),
            ],
          ),
      ],
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(Icons.copy, color: AppTheme.textSecondaryColor),
                title: Text(
                  '复制',
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                ),
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
                  leading: Icon(Icons.forward, color: AppTheme.textSecondaryColor),
                  title: Text(
                    '转发到群',
                    style: TextStyle(color: AppTheme.textPrimaryColor),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onForward?.call();
                  },
                ),
              if (message.status == MessageStatus.failed)
                ListTile(
                  leading: Icon(Icons.refresh, color: AppTheme.errorColor),
                  title: Text(
                    '重试',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
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

/// 三点弹跳打字指示器
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });

    // 依次启动动画
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -4 * _controllers[i].value),
                child: child,
              );
            },
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (i < 2) SizedBox(width: 4.w),
        ],
      ],
    );
  }
}

/// 闪烁光标
class _BlinkingCursor extends StatefulWidget {
  final Color textColor;

  const _BlinkingCursor({required this.textColor});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _visible = !_visible);
        _startBlinking();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 300),
      child: Text(
        '▍',
        style: TextStyle(
          fontSize: 14.sp,
          color: widget.textColor,
        ),
      ),
    );
  }
}
