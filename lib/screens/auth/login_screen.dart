import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../debug/log_viewer_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码至少6位')),
      );
      return;
    }

    try {
      if (_isRegister) {
        // 注册模式
        await ref.read(authStateProvider.notifier).register(phone, password);
      } else {
        // 登录模式
        await ref.read(authStateProvider.notifier).login(phone, password);
      }
    } catch (e) {
      // 确保在 UI 线程显示错误
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // 从 AuthNotifier 获取友好的错误信息
        final errorMsg = ref.read(authStateProvider.notifier).lastError ??
            (_isRegister ? '注册失败，请稍后重试' : '登录失败，请稍后重试');

        // 如果是 409 错误（已注册），自动切换到登录模式
        if (_isRegister && e.toString().contains('409')) {
          setState(() {
            _isRegister = false;
          });
        }

        // 显示 Toast 提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 调试日志入口
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.grey),
            tooltip: '查看日志',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogViewerScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // Logo和标题
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 40.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '回响',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'AI驱动的热门话题广场',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
                // 标题
                Text(
                  _isRegister ? '注册账号' : '账号登录',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 24.h),
                // 手机号输入
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    hintText: '请输入手机号',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                ),
                SizedBox(height: 16.h),
                // 密码输入
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '请输入密码（至少6位）',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // 登录/注册按钮
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isRegister ? '注册' : '登录'),
                  ),
                ),
                SizedBox(height: 16.h),
                // 切换登录/注册
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegister = !_isRegister;
                      });
                    },
                    child: Text(
                      _isRegister ? '已有账号？去登录' : '没有账号？去注册',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                // 用户协议
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: 打开用户协议
                    },
                    child: Text(
                      '${_isRegister ? "注册" : "登录"}即表示同意《用户协议》和《隐私政策》',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ),
                ),
                if (authState.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Center(
                      child: Text(
                        authState.error.toString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                // 底部留白，确保可以滚动到底部
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
