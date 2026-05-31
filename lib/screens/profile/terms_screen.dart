import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '用户协议',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '最后更新日期：2024年1月1日',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textTertiaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            _buildSection(
              title: '1. 服务说明',
              content:
                  '回响是一款社交应用，提供话题广场浏览与发布、私密群聊、匿名发言、AI 助手对话、自定义 Agent 及 OpenClaw 远程终端关联等功能。您使用回响服务即表示同意本协议全部条款。',
            ),
            _buildSection(
              title: '2. 账号注册',
              content:
                  '回响使用手机号作为唯一账号标识。注册时需提供有效的手机号码并完成验证。您应确保账号信息真实有效，不得冒用他人身份注册。账号仅限本人使用，不得转让、出借或共享。',
            ),
            _buildSection(
              title: '3. 内容发布规范',
              content:
                  '您在话题广场、群聊中发布的内容须遵守法律法规。禁止发布：危害国家安全、泄露国家秘密、煽动民族仇恨、传播淫秽色情、侵犯他人知识产权或隐私权、虚假诈骗信息等内容。匿名发言同样受此约束，后台保留追溯权利。',
            ),
            _buildSection(
              title: '4. AI 助手与 Agent',
              content:
                  'AI 助手和自定义 Agent 功能通过第三方 AI 服务提供商（如 OpenAI、DeepSeek、通义千问等）实现。您与 AI 的交互内容会被发送至相应提供商进行处理。请勿在 AI 对话中输入密码、银行卡号、身份证号等敏感个人信息。AI 生成的内容仅供参考，不构成专业建议。',
            ),
            _buildSection(
              title: '5. OpenClaw 远程终端',
              content:
                  'OpenClaw 功能允许您关联并远程访问终端设备。您应确保对远程设备拥有合法管理权限，不得利用该功能非法访问他人设备或系统。远程连接产生的操作记录将被保存。',
            ),
            _buildSection(
              title: '6. 群聊与群回忆',
              content:
                  '群聊内容对群内成员可见。群回忆功能会自动记录群内特定互动并生成摘要，供群成员回顾。您发送的消息可能被其他成员转发或截图，请谨慎发送敏感信息。',
            ),
            _buildSection(
              title: '7. 匿名发言',
              content:
                  '匿名发言功能以"有人说"身份展示您的观点，群内成员无法直接识别您的真实身份，但后台会记录匿名发言与账号的关联关系，用于内容审核和违规追溯。',
            ),
            _buildSection(
              title: '8. 知识产权',
              content:
                  '您在回响发布的内容（话题、评论、群聊消息等），知识产权归您所有。您授予回响非独占、免费、可转授权的权利，用于内容展示、存储、审核及推荐。回响应用的界面设计、代码、商标等知识产权归我们所有。',
            ),
            _buildSection(
              title: '9. 服务变更与终止',
              content:
                  '我们保留随时修改、暂停或终止部分或全部服务的权利。如您违反本协议，我们有权暂停或终止您的账号，并删除相关违规内容。',
            ),
            _buildSection(
              title: '10. 免责声明',
              content:
                  'AI 生成内容的准确性、完整性和适用性由您自行判断。对于因网络故障、第三方服务中断、不可抗力等导致的服务不可用，我们不承担责任，但会尽力恢复服务。',
            ),
            _buildSection(
              title: '11. 协议更新',
              content:
                  '我们可能会根据法律法规变化或产品功能调整更新本协议。更新后的协议将在应用内公布，继续使用服务即视为接受更新内容。',
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
