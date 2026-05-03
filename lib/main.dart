import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/log_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';
import 'widgets/device_preview_wrapper.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await logService.initialize();
  // 启动时同步等待登录态恢复，避免首屏路由竞态
  await AuthService().init();

  runApp(
    const ProviderScope(
      child: EchoApp(),
    ),
  );
}

class EchoApp extends ConsumerWidget {
  const EchoApp({super.key});

  static bool _updateChecked = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    Widget app = ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '回响',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: router,
          builder: (context, child) {
            if (!_updateChecked) {
              _updateChecked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final navContext = rootNavigatorKey.currentContext;
                if (navContext != null && navContext.mounted) {
                  _checkUpdate(navContext);
                }
              });
            }
            return DevicePreviewWrapper(
              child: child!,
            );
          },
        );
      },
    );

    // Web端固定MediaQuery尺寸为设计稿尺寸，避免浏览器窗口影响ScreenUtil计算
    if (kIsWeb) {
      app = MediaQuery(
        data: const MediaQueryData(size: Size(375, 812)),
        child: app,
      );
    }

    return app;
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final info = await UpdateService.checkUpdate();
    if (info != null && context.mounted) {
      await UpdateDialog.show(context, info);
    }
  }
}
