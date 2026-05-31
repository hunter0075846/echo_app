import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'echo_button.dart';

/// 统一对话框组件
///
/// 替代各处重复的 AlertDialog 构造代码。
class EchoDialog {
  EchoDialog._();

  /// 显示确认对话框
  static Future<bool> confirm({
    required BuildContext context,
    String? title,
    required String content,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// 显示信息对话框
  static Future<void> alert({
    required BuildContext context,
    String? title,
    required String content,
    String confirmLabel = '知道了',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AlertDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String? title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const _ConfirmDialog({
    this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.headlineSmall,
            )
          : null,
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.echoTextSecondary,
        ),
      ),
      actions: [
        EchoButton.ghost(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        isDestructive
            ? EchoButton.destructive(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              )
            : EchoButton.primary(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              ),
      ],
    ).animate().scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: EchoDurations.normal,
          curve: EchoCurves.spring,
        );
  }
}

class _AlertDialog extends StatelessWidget {
  final String? title;
  final String content;
  final String confirmLabel;

  const _AlertDialog({
    this.title,
    required this.content,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.headlineSmall,
            )
          : null,
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.echoTextSecondary,
        ),
      ),
      actions: [
        EchoButton.primary(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ).animate().scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: EchoDurations.normal,
          curve: EchoCurves.spring,
        );
  }
}
