import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// 带渐变背景的 Scaffold 包装器
///
/// 自动为页面提供柔和的淡紫→暖米白渐变背景（或暗色模式下的深紫渐变）。
/// 内部使用 Scaffold(backgroundColor: transparent) 确保内容浮于渐变之上。
/// 所有页面应优先使用此组件替代原生 Scaffold。
class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final Drawer? drawer;
  final Drawer? endDrawer;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundColor != null
            ? null
            : isDark
                ? EchoGradients.darkBackground
                : EchoGradients.background,
        color: backgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        bottomSheet: bottomSheet,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
    );
  }
}
