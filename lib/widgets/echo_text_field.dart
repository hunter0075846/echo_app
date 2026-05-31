import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/animation_utils.dart';

/// 统一文本输入框组件
///
/// 带一致的装饰样式、白色背景、大圆角、错误抖动动画、以及主题适配。
class EchoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? topLabel;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool autofocus;
  final String? Function(String?)? validator;
  final bool enabled;

  const EchoTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.topLabel,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      readOnly: readOnly,
      autofocus: autofocus,
      enabled: enabled,
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: theme.echoTextTertiary,
                  size: 20.w,
                ),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: theme.echoTextTertiary,
                  size: 20.w,
                ),
                child: suffixIcon!,
              )
            : null,
      ),
    );

    if (errorText != null) {
      field = field
          .animate()
          .shake(duration: EchoDurations.normal, hz: 4);
    }

    if (topLabel != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topLabel!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.echoTextTertiary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          field,
        ],
      );
    }

    return field;
  }
}

/// 多行文本输入框（带发送按钮）
class EchoChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onAddImage;
  final String hintText;
  final bool isLoading;

  const EchoChatInput({
    super.key,
    required this.controller,
    this.onSend,
    this.onAddImage,
    this.hintText = '输入消息...',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EchoSpacing.sm,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onAddImage != null)
              IconButton(
                onPressed: () {
                  EchoHaptics.light();
                  onAddImage!();
                },
                icon: Icon(
                  Icons.image_outlined,
                  color: theme.echoTextSecondary,
                ),
              ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: EchoSpacing.md,
                    vertical: 10.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EchoRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EchoRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EchoRadius.full),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: EchoSpacing.sm),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isLoading
                      ? theme.echoTextTertiary
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(10.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: colorScheme.onPrimary,
                        size: 20.w,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (isLoading || controller.text.trim().isEmpty) return;
    EchoHaptics.light();
    onSend?.call();
  }
}
