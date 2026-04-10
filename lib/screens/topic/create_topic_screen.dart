import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/topic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class CreateTopicScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const CreateTopicScreen({
    super.key,
    this.initialType,
  });

  @override
  ConsumerState<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends ConsumerState<CreateTopicScreen> {
  final _linkController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'link'; // 'link' or 'image'
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    // 检查用户配额
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    if (user.dailyTopicQuota >= user.maxDailyTopicQuota) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日发话题配额已用完，明天再来吧')),
      );
      return;
    }

    // 验证输入
    if (_selectedType == 'link') {
      final link = _linkController.text.trim();
      if (link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入链接')),
        );
        return;
      }
      if (!_isValidUrl(link)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的链接')),
        );
        return;
      }
    } else {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择图片')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 上传图片到服务器（如果是图片类型）
      String? imageUrl;
      if (_selectedType == 'image' && _selectedImage != null) {
        // imageUrl = await _uploadImage(_selectedImage!);
        imageUrl = 'https://example.com/uploaded_image.jpg'; // 占位
      }

      await ref.read(topicServiceProvider).createTopic(
        sourceType: _selectedType,
        sourceUrl: _selectedType == 'link' ? _linkController.text.trim() : null,
        imageUrl: imageUrl,
        content: _selectedType == 'link' 
            ? _linkController.text.trim() 
            : _contentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('话题发布成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final remainingQuota = (user?.maxDailyTopicQuota ?? 10) - (user?.dailyTopicQuota ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发话题'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('发布'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 配额提示
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: remainingQuota > 0
                    ? AppTheme.primaryLightColor.withOpacity(0.1)
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    remainingQuota > 0 ? Icons.info_outline : Icons.warning,
                    size: 20.w,
                    color: remainingQuota > 0 ? AppTheme.primaryColor : AppTheme.errorColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      remainingQuota > 0
                          ? '今日还可发布 $remainingQuota 个话题'
                          : '今日发布配额已用完，明天再来吧',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: remainingQuota > 0
                            ? AppTheme.primaryColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // 类型选择
            Text(
              '选择发布类型',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    icon: Icons.link,
                    title: '粘贴链接',
                    subtitle: '文章、视频等',
                    isSelected: _selectedType == 'link',
                    onTap: () => setState(() => _selectedType = 'link'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _TypeOption(
                    icon: Icons.image,
                    title: '上传图片',
                    subtitle: '分享图片',
                    isSelected: _selectedType == 'image',
                    onTap: () => setState(() => _selectedType = 'image'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // 输入区域
            if (_selectedType == 'link') ...[
              Text(
                '粘贴链接',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _linkController.clear(),
                  ),
                ),
                keyboardType: TextInputType.url,
                enabled: remainingQuota > 0,
              ),
              SizedBox(height: 16.h),
              Text(
                '支持微信公众号文章、知乎、B站、抖音等平台链接',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textTertiaryColor,
                ),
              ),
            ] else ...[
              Text(
                '上传图片',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              if (_selectedImage == null)
                InkWell(
                  onTap: remainingQuota > 0 ? _pickImage : null,
                  child: Container(
                    height: 200.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48.w,
                          color: remainingQuota > 0
                              ? AppTheme.textTertiaryColor
                              : AppTheme.textTertiaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          '点击选择图片',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: remainingQuota > 0
                                ? AppTheme.textSecondaryColor
                                : AppTheme.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        _selectedImage!,
                        height: 200.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8.w,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16.h),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: '添加描述（可选）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                maxLines: 3,
                enabled: remainingQuota > 0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.w,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
