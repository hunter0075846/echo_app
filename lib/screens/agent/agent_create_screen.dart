import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/agent_model.dart';
import '../../services/agent_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// 创建/编辑 AI Agent 页面
/// 最大限度简化配置，必填项只有：名称、API地址、API Key、模型
class AgentCreateScreen extends ConsumerStatefulWidget {
  final String? agentId;

  const AgentCreateScreen({
    super.key,
    this.agentId,
  });

  @override
  ConsumerState<AgentCreateScreen> createState() => _AgentCreateScreenState();
}

class _AgentCreateScreenState extends ConsumerState<AgentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  final _promptController = TextEditingController();
  double _temperature = 0.7;

  bool _isLoading = false;
  bool _obscureKey = true;

  AgentModel? _existingAgent;

  final List<Map<String, String>> _presets = [
    {
      'name': 'OpenAI',
      'url': 'https://api.openai.com/v1',
      'model': 'gpt-3.5-turbo',
    },
    {
      'name': 'DeepSeek',
      'url': 'https://api.deepseek.com/v1',
      'model': 'deepseek-chat',
    },
    {
      'name': '硅基流动',
      'url': 'https://api.siliconflow.cn/v1',
      'model': 'Qwen/Qwen2.5-7B-Instruct',
    },
    {
      'name': '阿里云百炼',
      'url': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      'model': 'qwen-turbo',
    },
    {
      'name': 'Moonshot',
      'url': 'https://api.moonshot.cn/v1',
      'model': 'moonshot-v1-8k',
    },
    {
      'name': '智谱AI',
      'url': 'https://open.bigmodel.cn/api/paas/v4',
      'model': 'glm-4-flash',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.agentId != null) {
      _loadAgent();
    }
  }

  Future<void> _loadAgent() async {
    setState(() => _isLoading = true);
    try {
      final service = AgentService(ApiService());
      final agent = await service.getAgent(widget.agentId!);
      setState(() {
        _existingAgent = agent;
        _nameController.text = agent.name;
        _descController.text = agent.description ?? '';
        _urlController.text = agent.baseUrl;
        _modelController.text = agent.model;
        _promptController.text = agent.systemPrompt ?? '';
        _temperature = agent.temperature;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = AgentService(ApiService());

      if (_existingAgent != null) {
        // 更新
        await service.updateAgent(
          _existingAgent!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          baseUrl: _urlController.text.trim(),
          apiKey: _keyController.text.trim().isEmpty
              ? null
              : _keyController.text.trim(),
          model: _modelController.text.trim(),
          systemPrompt: _promptController.text.trim().isEmpty
              ? null
              : _promptController.text.trim(),
          temperature: _temperature,
        );
      } else {
        // 创建
        await service.createAgent(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          baseUrl: _urlController.text.trim(),
          apiKey: _keyController.text.trim(),
          model: _modelController.text.trim(),
          systemPrompt: _promptController.text.trim().isEmpty
              ? null
              : _promptController.text.trim(),
          temperature: _temperature,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingAgent != null ? '更新成功' : '创建成功'),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _urlController.text = preset['url']!;
      _modelController.text = preset['model']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingAgent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑AI助手' : '添加AI助手'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // 快捷预设
            if (!isEdit) ...[
              Text(
                '快捷选择服务商',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _presets.map((preset) {
                  return ActionChip(
                    label: Text(preset['name']!),
                    onPressed: () => _applyPreset(preset),
                    backgroundColor: AppTheme.backgroundColor,
                    side: const BorderSide(color: AppTheme.borderColor),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
            ],

            // 名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '助手名称 *',
                hintText: '给你的AI助手起个名字，如"文案助手"',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入助手名称';
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // 描述
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '简单描述这个助手的用途',
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // API地址
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API地址 *',
                hintText: 'https://api.openai.com/v1',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入API地址';
                if (!v.startsWith('http')) return '地址需以 http 或 https 开头';
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // API Key
            TextFormField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: isEdit ? 'API Key（留空则保留原值）' : 'API Key *',
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureKey = !_obscureKey);
                  },
                ),
              ),
              validator: (v) {
                if (!isEdit && (v == null || v.trim().isEmpty)) {
                  return '请输入API Key';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // 模型
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型名称 *',
                hintText: 'gpt-3.5-turbo',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入模型名称';
                return null;
              },
            ),
            SizedBox(height: 24.h),

            // 高级选项
            ExpansionTile(
              title: const Text('高级选项'),
              children: [
                // 系统提示词
                TextFormField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: '系统提示词（可选）',
                    hintText: '设定助手的角色和行为，如"你是一位专业的文案写手"',
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16.h),

                // 温度
                Row(
                  children: [
                    Text(
                      '创造力: ${_temperature.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Expanded(
                      child: Slider(
                        value: _temperature,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        label: _temperature.toStringAsFixed(1),
                        onChanged: (v) {
                          setState(() => _temperature = v);
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '更确定',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                      Text(
                        '更随机',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? '保存修改' : '立即添加'),
              ),
            ),
            SizedBox(height: 16.h),

            // 提示文字
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.infoColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '所有配置仅保存在你的账号下，平台不会审核或限制你使用的AI服务。确保你使用的API地址和Key是有效的。',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
