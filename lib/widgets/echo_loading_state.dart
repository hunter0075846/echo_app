import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/design_tokens.dart';

/// 统一加载态组件
///
/// 提供 list / detail / chat / profile 四种场景的骨架屏。
/// 支持骨架屏到真实内容的交叉淡入过渡。
class EchoLoadingState extends StatelessWidget {
  final LoadingType type;
  final int itemCount;

  const EchoLoadingState({
    super.key,
    this.type = LoadingType.list,
    this.itemCount = 5,
  });

  const EchoLoadingState.list({super.key, this.itemCount = 5})
      : type = LoadingType.list;

  const EchoLoadingState.detail({super.key})
      : type = LoadingType.detail,
        itemCount = 1;

  const EchoLoadingState.chat({super.key})
      : type = LoadingType.chat,
        itemCount = 6;

  const EchoLoadingState.profile({super.key})
      : type = LoadingType.profile,
        itemCount = 1;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.list:
        return _ListSkeleton(itemCount: itemCount);
      case LoadingType.detail:
        return const _DetailSkeleton();
      case LoadingType.chat:
        return _ChatSkeleton(itemCount: itemCount);
      case LoadingType.profile:
        return const _ProfileSkeleton();
    }
  }
}

enum LoadingType { list, detail, chat, profile }

class _ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const _ShimmerWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.outline.withValues(alpha: 0.2),
      highlightColor: isDark
          ? colorScheme.surface.withValues(alpha: 0.8)
          : Colors.white,
      child: child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int itemCount;

  const _ListSkeleton({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: EchoSpacing.md,
        vertical: EchoSpacing.sm,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: EchoSpacing.sm),
          child: Padding(
            padding: EdgeInsets.all(EchoSpacing.md),
            child: _ShimmerWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _SkeletonBox(
                        width: 32,
                        height: 32,
                        borderRadius: 16,
                      ),
                      SizedBox(width: EchoSpacing.sm),
                      const _SkeletonBox(width: 80, height: 14),
                    ],
                  ),
                  SizedBox(height: EchoSpacing.sm),
                  const _SkeletonBox(
                    width: double.infinity,
                    height: 18,
                  ),
                  SizedBox(height: 6.h),
                  const _SkeletonBox(width: 200, height: 18),
                  SizedBox(height: EchoSpacing.sm),
                  const _SkeletonBox(
                    width: double.infinity,
                    height: 160,
                    borderRadius: 12,
                  ),
                  SizedBox(height: EchoSpacing.sm),
                  Row(
                    children: [
                      const _SkeletonBox(width: 60, height: 14),
                      SizedBox(width: EchoSpacing.md),
                      const _SkeletonBox(width: 60, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(EchoSpacing.md),
      child: _ShimmerWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBox(
              width: double.infinity,
              height: 220,
              borderRadius: 16,
            ),
            SizedBox(height: EchoSpacing.md),
            const _SkeletonBox(width: 200, height: 24),
            SizedBox(height: EchoSpacing.sm),
            const _SkeletonBox(width: 150, height: 16),
            SizedBox(height: EchoSpacing.md),
            const _SkeletonBox(
              width: double.infinity,
              height: 14,
            ),
            SizedBox(height: 6.h),
            const _SkeletonBox(
              width: double.infinity,
              height: 14,
            ),
            SizedBox(height: 6.h),
            const _SkeletonBox(width: 280, height: 14),
          ],
        ),
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  final int itemCount;

  const _ChatSkeleton({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: EchoSpacing.md,
        vertical: EchoSpacing.sm,
      ),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: EchoSpacing.sm,
              left: isUser ? 80.w : 0,
              right: isUser ? 0 : 80.w,
            ),
            child: _ShimmerWrapper(
              child: Container(
                width: (120 + (index * 30)).w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Padding(
        padding: EdgeInsets.all(EchoSpacing.md),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(EchoSpacing.lg),
                child: Row(
                  children: [
                    const _SkeletonBox(
                      width: 80,
                      height: 80,
                      borderRadius: 40,
                    ),
                    SizedBox(width: EchoSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SkeletonBox(width: 120, height: 20),
                          SizedBox(height: EchoSpacing.sm),
                          const _SkeletonBox(width: 100, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: EchoSpacing.md),
            for (int i = 0; i < 4; i++) ...[
              Card(
                child: ListTile(
                  leading: const _SkeletonBox(width: 24, height: 24),
                  title: const _SkeletonBox(width: 120, height: 16),
                ),
              ),
              SizedBox(height: EchoSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
