import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/echo_button.dart';
import '../../widgets/echo_text_field.dart';
import '../../widgets/gradient_scaffold.dart';
import '../debug/log_viewer_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) return '手机号格式不正确';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return '请输入密码';
    if (value.length < 6) return '密码至少 6 位';
    if (value.length > 72) return '密码最多 72 位';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (!_isRegister) return null;
    if (v == null || v.isEmpty) return '请再次输入密码';
    if (v != _passwordController.text) return '两次输入的密码不一致';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final notifier = ref.read(authStateProvider.notifier);

      if (_isRegister) {
        await notifier.register(phone, password);
      } else {
        await notifier.login(phone, password);
      }

      if (!mounted) return;

      final errorInfo = ref.read(authStateProvider.notifier).lastErrorInfo;
      if (_isRegister && errorInfo != null && errorInfo.isPhoneTaken) {
        setState(() {
          _isRegister = false;
          _confirmPasswordController.clear();
        });
        return;
      }

      final state = ref.read(authStateProvider);
      if (state.hasValue && state.value != null) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          context.go(from);
        } else {
          context.go('/');
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final errorInfo = ref.watch(authStateProvider.notifier).lastErrorInfo;
    final isLoading = _isSubmitting || authState.isLoading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report_outlined, color: theme.echoTextTertiary),
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
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 24.h),
                    // 标题区域
                    _buildTitle(theme, colorScheme),
                    SizedBox(height: 48.h),
                    if (errorInfo != null && _shouldShowBanner(errorInfo)) ...[
                      _ErrorBanner(message: errorInfo.message),
                      SizedBox(height: 24.h),
                    ],
                    EchoTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      textInputAction: TextInputAction.next,
                      topLabel: _isRegister ? 'YOUR PHONE' : 'YOUR PHONE',
                      hintText: '请输入手机号',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: _validatePhone,
                    ),
                    SizedBox(height: 20.h),
                    EchoTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction:
                          _isRegister ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isRegister) _submit();
                      },
                      topLabel: 'YOUR PASSWORD',
                      hintText: '请输入密码（至少6位）',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: _validatePassword,
                    ),
                    if (_isRegister) ...[
                      SizedBox(height: 20.h),
                      EchoTextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        topLabel: 'CONFIRM PASSWORD',
                        hintText: '请再次输入密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
                        ),
                        validator: _validateConfirmPassword,
                      ),
                    ],
                    SizedBox(height: 40.h),
                    EchoButton.primary(
                      label: _isRegister ? '注册' : '登录',
                      icon: Icons.arrow_forward,
                      isLoading: isLoading,
                      isFullWidth: true,
                      onPressed: _submit,
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegister = !_isRegister;
                                  _confirmPasswordController.clear();
                                  ref
                                      .read(authStateProvider.notifier)
                                      .clearError();
                                });
                              },
                        child: Text(
                          _isRegister ? '已有账号？去登录' : '没有账号？去注册',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: 打开用户协议
                        },
                        child: Text(
                          '${_isRegister ? "注册" : "登录"}即表示同意《用户协议》和《隐私政策》',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.echoTextTertiary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _isRegister ? '创建你的' : '欢迎回到',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.echoTextPrimary,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          '回响',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'AI驱动的热门话题广场',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.echoTextSecondary,
          ),
        ),
      ],
    );
  }

  bool _shouldShowBanner(AuthErrorInfo info) {
    if (info.isPhoneTaken) return true;
    if (info.isInvalidCredentials) return true;
    if (info.isRateLimited) return true;
    if (info.statusCode == null) return true;
    if (info.statusCode! >= 500) return true;
    return false;
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18.w, color: AppTheme.errorColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.sp, color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
