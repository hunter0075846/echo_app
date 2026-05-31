import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '隐私政策',
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
              title: '1. 我们收集的信息',
              content:
                  '为提供服务，我们收集以下信息：\n'
                  '• 账号信息：手机号（注册与登录）、昵称、头像。\n'
                  '• 设备信息：设备型号、操作系统版本、应用版本号，用于兼容性适配和问题排查。\n'
                  '• 您发布的内容：话题、评论、群聊消息、匿名发言内容。匿名发言虽对群成员匿名展示，但后台会记录与账号的关联用于内容审核。\n'
                  '• AI 对话记录：您与 AI 助手、自定义 Agent 的交互内容，会发送至第三方 AI 服务提供商处理。\n'
                  '• OpenClaw 连接信息：远程终端设备的连接标识、操作日志。',
            ),
            _buildSection(
              title: '2. AI 服务的数据处理',
              content:
                  'AI 助手和自定义 Agent 功能由第三方 AI 服务提供商（OpenAI、DeepSeek、通义千问等）提供技术支持。您输入的提示词、对话历史及上下文会被加密传输至相应提供商的服务器进行处理。我们不会将您的手机号、身份信息与 AI 对话内容进行关联后提供给第三方。请勿在 AI 对话中输入密码、银行卡号、身份证号等敏感个人信息。',
            ),
            _buildSection(
              title: '3. 信息的使用',
              content:
                  '我们使用您的信息用于：提供和维护服务、内容审核与安全风控、账号安全保护、AI 功能响应、问题排查与性能优化。我们不会将您的个人信息用于与上述目的无关的其他用途，也不会向第三方出售您的个人信息。',
            ),
            _buildSection(
              title: '4. 信息的共享与披露',
              content:
                  '除以下情形外，我们不会与第三方共享您的个人信息：\n'
                  '• 第三方 AI 服务提供商：仅共享必要的对话内容以提供 AI 功能。\n'
                  '• 法律法规要求：应司法机关、行政机关或其他有权机关的合法要求。\n'
                  '• 保护合法权益：为防止欺诈、保障人身财产安全等必要情形。',
            ),
            _buildSection(
              title: '5. 数据的存储与安全',
              content:
                  '您的数据存储在安全的服务器上，采用加密传输（HTTPS）和数据库加密等措施保护。本地仅通过安全存储保存登录凭证。聊天记录、话题内容等会保留至您主动删除或账号注销为止。AI 对话记录在第三方提供商处的保留期限遵循其各自的政策。',
            ),
            _buildSection(
              title: '6. 您的权利',
              content:
                  '您对个人信息拥有以下权利：\n'
                  '• 访问与更正：可在个人资料页面修改昵称、头像等信息。\n'
                  '• 删除：您可删除自己发布的话题和评论。\n'
                  '• 注销账号：注销后您的账号信息将被删除或匿名化处理，群聊中已发送的消息因涉及其他用户权益可能继续保留。\n'
                  '• 撤回同意：您可随时停止使用特定功能。',
            ),
            _buildSection(
              title: '7. OpenClaw 与远程终端',
              content:
                  'OpenClaw 功能涉及与远程终端设备的 WebSocket 连接。连接过程中会传输设备操作指令和响应数据。您应确保仅连接您拥有合法管理权限的设备。我们不会主动访问或监控您的远程设备内容，但会为连接稳定性保存必要的连接日志。',
            ),
            _buildSection(
              title: '8. 未成年人保护',
              content:
                  '回响主要面向成年用户。如您未满 18 周岁，请在监护人指导下使用，并确保监护人已阅读并同意本政策。我们不会明知而收集未成年人的个人信息，如发现误收集将及时删除。',
            ),
            _buildSection(
              title: '9. 政策更新',
              content:
                  '我们可能会根据产品功能变化或法律法规要求更新本隐私政策。重大变更将在应用内显著位置提示，您继续使用服务即视为接受更新后的政策。',
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
