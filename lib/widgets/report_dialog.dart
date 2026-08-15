import 'package:flutter/material.dart';

import '../services/report_service.dart';

/// 举报弹窗：选择原因并提交
///
/// 用法：showReportDialog(context, targetType: 'topic', targetId: id);
Future<void> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) {
  return showDialog(
    context: context,
    builder: (context) => _ReportDialog(targetType: targetType, targetId: targetId),
  );
}

class _ReportDialog extends StatefulWidget {
  final String targetType;
  final String targetId;

  const _ReportDialog({required this.targetType, required this.targetId});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = [
    '色情低俗',
    '暴力血腥',
    '政治敏感',
    '人身攻击',
    '垃圾广告',
    '其他',
  ];

  String _selected = _reasons.first;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ReportService().report(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selected,
      );
      if (mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('举报已提交，感谢反馈')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('举报失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('举报内容'),
      content: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (v) {
          if (v != null) setState(() => _selected = v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reasons
              .map((r) => RadioListTile<String>(
                    title: Text(r),
                    value: r,
                    dense: true,
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('提交'),
        ),
      ],
    );
  }
}
