import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/ai_avatar.dart';
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
      // 注册时命中 409：回到登录模式，提示用户直接登录
      if (_isRegister && errorInfo != null && errorInfo.isPhoneTaken) {
        setState(() {
          _isRegister = false;
          _confirmPasswordController.clear();
        });
        return;
      }

      // 登录/注册成功：根据 from 参数返回原页面
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report_outlined, color: AppTheme.textTertiaryColor),
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Center(
                      child: Column(
                        children: [
                          AIAvatar(size: 80.w, animated: true),
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
                    Text(
                      _isRegister ? '注册账号' : '账号登录',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    if (errorInfo != null && _shouldShowBanner(errorInfo)) ...[
                      _ErrorBanner(message: errorInfo.message),
                      SizedBox(height: 16.h),
                    ],
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                      decoration: const InputDecoration(
                        hintText: '请输入手机号',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: _isRegister
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      textInputAction:
                          _isRegister ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isRegister) _submit();
                      },
                      validator: _validatePassword,
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
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                    if (_isRegister) ...[
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: _validateConfirmPassword,
                        decoration: InputDecoration(
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
                        ),
                      ),
                    ],
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isRegister ? '注册' : '登录'),
                      ),
                    ),
                    SizedBox(height: 16.h),
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
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.primaryColor,
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
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textTertiaryColor,
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

  // 字段错误（如 401 凭证错）已经通过表单 validator 显示，不重复 banner；
  // 仅在网络错误、限流、服务端错误等"非字段级"错误时显示顶部 banner。
  bool _shouldShowBanner(AuthErrorInfo info) {
    if (info.isPhoneTaken) return true; // 409：注册命中已存在号，需提示用户切到登录
    if (info.isInvalidCredentials) return true; // 401 没有 inline 字段，需要 banner
    if (info.isRateLimited) return true;
    if (info.statusCode == null) return true; // 网络错误
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
        borderRadius: BorderRadius.circular(8.r),
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
