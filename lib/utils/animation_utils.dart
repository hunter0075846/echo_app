import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';

/// 动效工具集
///
/// 提供列表交错进入、聊天消息滑入、页面过渡、触觉反馈等封装。
class EchoAnimations {
  EchoAnimations._();

  /// 列表项交错进入动画
  ///
  /// 使用方式：在 ListView.builder 的 itemBuilder 中包裹子项
  /// ```dart
  /// return EchoAnimations.staggeredItem(
  ///   index: index,
  ///   child: MyListItem(),
  /// );
  /// ```
  static Widget staggeredItem({
    required int index,
    required Widget child,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return child
        .animate(delay: delay * index)
        .fadeIn(duration: EchoDurations.normal)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: EchoDurations.normal,
          curve: EchoCurves.easeOut,
        );
  }

  /// 网格项交错进入动画
  static Widget staggeredGridItem({
    required int index,
    required int crossAxisCount,
    required Widget child,
    Duration delay = const Duration(milliseconds: 60),
  }) {
    final row = index ~/ crossAxisCount;
    final col = index % crossAxisCount;
    final staggerDelay = delay * (row + col);

    return child
        .animate(delay: staggerDelay)
        .fadeIn(duration: EchoDurations.normal)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: EchoDurations.normal,
          curve: EchoCurves.spring,
        );
  }

  /// 聊天消息进入动画
  ///
  /// 用户消息从右侧滑入，AI 消息从左侧滑入
  static Widget chatMessage({
    required bool isUser,
    required Widget child,
  }) {
    return child
        .animate()
        .fadeIn(duration: EchoDurations.fast)
        .slideX(
          begin: isUser ? 0.1 : -0.1,
          end: 0,
          duration: EchoDurations.normal,
          curve: EchoCurves.easeOut,
        );
  }

  /// 骨架屏到内容的交叉淡入
  static Widget skeletonCrossfade({
    required bool isLoading,
    required Widget skeleton,
    required Widget content,
  }) {
    return AnimatedCrossFade(
      firstChild: skeleton,
      secondChild: content,
      crossFadeState:
          isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: EchoDurations.normal,
      layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(key: bottomKey, child: bottomChild),
            Positioned(key: topKey, child: topChild),
          ],
        );
      },
    );
  }

  /// 页面进入动画组合
  static Widget pageEnter({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: EchoDurations.normal)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: EchoDurations.slow,
          curve: EchoCurves.easeOut,
        );
  }

  /// 空态/错误态进入动画
  static Widget stateEnter({required Widget child}) {
    return child
        .animate()
        .fadeIn(duration: EchoDurations.slow)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: EchoDurations.slow,
          curve: EchoCurves.spring,
        );
  }

  /// 按钮按压缩放动画
  static Widget buttonPress({required Widget child}) {
    return child.animate(target: 0).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.96, 0.96),
          duration: EchoDurations.fast,
          curve: EchoCurves.easeInOut,
        );
  }

  /// 抖动动画（用于错误提示）
  static Widget shake({required Widget child}) {
    return child
        .animate()
        .shake(duration: EchoDurations.normal, hz: 4);
  }

  /// 脉冲呼吸动画（用于 AI 头像等）
  static Widget pulse({required Widget child}) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.04, 1.04),
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
        );
  }
}

/// 触觉反馈工具
class EchoHaptics {
  EchoHaptics._();

  /// 轻触反馈（按钮点击、消息发送等）
  static void light() => HapticFeedback.lightImpact();

  /// 中等反馈（破坏性操作、重要确认）
  static void medium() => HapticFeedback.mediumImpact();

  /// 重反馈（严重错误、强烈提醒）
  static void heavy() => HapticFeedback.heavyImpact();

  /// 选择反馈（切换开关、选中项）
  static void selection() => HapticFeedback.selectionClick();

  /// 振动反馈（错误、警告）
  static void vibrate() => HapticFeedback.vibrate();
}

/// 供 go_router 使用的自定义页面过渡
class EchoPageTransitions {
  EchoPageTransitions._();

  /// 淡入 + 轻微上滑（默认页面过渡）
  static CustomTransitionPage<T> fadeUp<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: EchoCurves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: EchoCurves.easeOut),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: EchoDurations.normal,
      reverseTransitionDuration: EchoDurations.fast,
    );
  }

  /// 共享轴过渡（用于列表到详情）
  static CustomTransitionPage<T> sharedAxis<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: EchoCurves.easeInOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: EchoCurves.easeOut),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: EchoDurations.normal,
      reverseTransitionDuration: EchoDurations.fast,
    );
  }

  /// 缩放淡入（用于模态页面、对话框）
  static CustomTransitionPage<T> scaleFade<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: EchoCurves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: EchoCurves.spring),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: EchoDurations.normal,
      reverseTransitionDuration: EchoDurations.fast,
    );
  }
}
