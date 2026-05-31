import 'package:flutter/material.dart';

import 'ai_avatar.dart';
import 'agent_avatar.dart';
import 'openclaw_avatar.dart';
import 'user_avatar.dart';

/// 头像统一入口
///
/// 提供静态工厂方法，统一创建各类头像组件。
class EchoAvatar {
  EchoAvatar._();

  /// 用户头像（姓氏首字母 + 品牌渐变）
  static Widget user({
    Key? key,
    String? id,
    String? name,
    String? imageUrl,
    double size = 40,
    VoidCallback? onTap,
  }) =>
      UserAvatar(
        key: key,
        id: id,
        name: name,
        imageUrl: imageUrl,
        size: size,
        onTap: onTap,
      );

  /// AI 助手「小E」头像（圆形 + 脉冲动画）
  static Widget ai({
    Key? key,
    double size = 48,
    bool animated = false,
  }) =>
      AIAvatar(
        key: key,
        size: size,
        animated: animated,
      );

  /// OpenClaw 品牌形象（连接节点 + 状态环）
  static Widget openClaw({
    Key? key,
    double size = 48,
    String? status,
  }) =>
      OpenClawAvatar(
        key: key,
        size: size,
        status: status,
      );

  /// Agent 头像（品牌渐变 + emoji/图标）
  static Widget agent({
    Key? key,
    String? emoji,
    IconData? icon,
    double size = 48,
    String? label,
  }) =>
      AgentAvatar(
        key: key,
        emoji: emoji,
        icon: icon,
        size: size,
        label: label,
      );
}
