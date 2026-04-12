import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/topic/topic_detail_screen.dart';
import '../screens/topic/create_topic_screen.dart';
import '../screens/group/group_chat_screen.dart';
import '../screens/group/memory_timeline_screen.dart';
import '../screens/group/ai_assistant_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/about_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 安全地检查登录状态，处理错误情况
      final isLoggedIn = authState.hasValue && authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login';
      
      // 如果有错误且不在登录页，保持在当前页面（不跳转）
      if (authState.hasError && !isAuthRoute) {
        return null;
      }
      
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
