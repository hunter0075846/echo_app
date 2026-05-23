import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/group/ai_assistant_screen.dart';
import '../screens/group/group_bots_screen.dart';
import '../screens/group/group_chat_screen.dart';
import '../screens/group/memory_timeline_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/openclaw/openclaw_chat_screen.dart';
import '../screens/openclaw/openclaw_detail_screen.dart';
import '../screens/openclaw/openclaw_list_screen.dart';
import '../screens/openclaw/openclaw_setup_screen.dart';
import '../screens/profile/about_screen.dart';
import '../screens/profile/privacy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/terms_screen.dart';
import '../screens/chat/private_chat_screen.dart';
import '../screens/friend/friend_list_screen.dart';
import '../screens/scanner/qr_scanner_screen.dart';
import '../screens/topic/create_topic_screen.dart';
import '../screens/topic/topic_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // 启动初始化未完成时，先不做跳转，让 splash/loading 占位
      if (authState is AsyncLoading) return null;

      final isLoggedIn = authState.hasValue && authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) {
        // 保留来源路径，登录成功后跳回去
        final from = state.matchedLocation == '/'
            ? null
            : Uri.encodeComponent(state.uri.toString());
        return from == null ? '/login' : '/login?from=$from';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/topic/create',
        builder: (context, state) => CreateTopicScreen(
          initialType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (context, state) => TopicDetailScreen(
          topicId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (context, state) => GroupChatScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/group/:id/memories',
        builder: (context, state) => MemoryTimelineScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/group/:id/ai-chat',
        builder: (context, state) => AiAssistantScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/group/:id/bots',
        builder: (context, state) => GroupBotsScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      // OpenClaw 路由
      GoRoute(
        path: '/openclaw',
        builder: (context, state) => const OpenClawListScreen(),
      ),
      GoRoute(
        path: '/openclaw/setup',
        builder: (context, state) => OpenClawSetupScreen(
          connectionId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/openclaw/chat',
        builder: (context, state) => OpenClawChatScreen(
          connectionId: state.uri.queryParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/openclaw/:id/edit',
        builder: (context, state) => OpenClawDetailScreen(
          connectionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendListScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PrivateChatScreen(
            userId: state.pathParameters['userId']!,
            nickname: extra?['nickname'] as String?,
            avatar: extra?['avatar'] as String?,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              '页面出错了',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '未知错误',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
