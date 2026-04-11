import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web 端手机视图模拟器
/// 在大屏幕上显示手机框架，内容限制在手机尺寸内
class DevicePreviewWrapper extends StatelessWidget {
  final Widget child;
  final Size phoneSize;

  const DevicePreviewWrapper({
    super.key,
    required this.child,
    this.phoneSize = const Size(375, 812),
  });

  @override
  Widget build(BuildContext context) {
    // 非 Web 平台直接返回原内容
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 如果屏幕宽度小于手机宽度 + 边距，直接显示
        if (constraints.maxWidth < phoneSize.width + 100) {
          return child;
        }

        // 大屏幕显示手机框架
        return Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // 手机外框
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: phoneSize.width,
                height: phoneSize.height,
                color: Colors.white,
                child: Column(
                  children: [
                    // 状态栏区域（刘海屏效果）
                    Container(
                      width: double.infinity,
                      height: 44,
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 实际内容区域 - 使用 MediaQuery 限制尺寸
                    Expanded(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: Size(phoneSize.width, phoneSize.height - 44 - 34),
                          padding: EdgeInsets.zero,
                          viewPadding: const EdgeInsets.only(top: 44),
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: child,
                      ),
                    ),
                    // 底部指示条
                    Container(
                      width: double.infinity,
                      height: 34,
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          width: 134,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
