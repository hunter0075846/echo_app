import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../friend/friend_list_screen.dart';
import 'topic_square_tab.dart';
import 'group_list_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _pages = [
    const TopicSquareTab(),
    const GroupListTab(),
    const FriendListScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceColor.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                backgroundColor: Colors.transparent,
                elevation: 0,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  _buildNavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: '话题广场',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: '群聊',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: '好友',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: '我的',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(activeIcon),
          SizedBox(height: 2.h),
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}
