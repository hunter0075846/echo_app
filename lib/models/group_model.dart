import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String? avatar;
  final String? description;
  final String ownerId;
  final int maxMembers;
  final int currentMembers;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.avatar,
    this.description,
    required this.ownerId,
    this.maxMembers = 10,
    this.currentMembers = 0,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      maxMembers: json['maxMembers'] as int? ?? 10,
      currentMembers: json['currentMembers'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'description': description,
      'ownerId': ownerId,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? avatar,
    String? description,
    String? ownerId,
    int? maxMembers,
    int? currentMembers,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GroupMemberModel {
  final String id;
  final String groupId;
  final UserModel user;
  final String role;
  final DateTime? joinedAt;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.user,
    this.role = 'member',
    this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'user': user.toJson(),
      'role': role,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  GroupMemberModel copyWith({
    String? id,
    String? groupId,
    UserModel? user,
    String? role,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      user: user ?? this.user,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String type;
  final String content;
  final String? mediaUrl;
  final bool isAnonymous;
  final bool isDeleted;
  final DateTime? createdAt;

  const GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.isAnonymous = false,
    this.isDeleted = false,
    this.createdAt,
  });

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      type: json['type'] as String,
      content: json['content'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type,
      'content': content,
      'mediaUrl': mediaUrl,
      'isAnonymous': isAnonymous,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? type,
    String? content,
    String? mediaUrl,
    bool? isAnonymous,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupTopicCardModel {
  final String id;
  final String groupId;
  final String topicId;
  final String topicTitle;
  final String? topicImage;
  final String? guideText;
  final int participantCount;
  final bool isExpired;
  final DateTime? expiredAt;
  final DateTime? createdAt;

  const GroupTopicCardModel({
    required this.id,
    required this.groupId,
    required this.topicId,
    required this.topicTitle,
    this.topicImage,
    this.guideText,
    this.participantCount = 0,
    this.isExpired = false,
    this.expiredAt,
    this.createdAt,
  });

  factory GroupTopicCardModel.fromJson(Map<String, dynamic> json) {
    return GroupTopicCardModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      topicId: json['topicId'] as String,
      topicTitle: json['topicTitle'] as String,
      topicImage: json['topicImage'] as String?,
      guideText: json['guideText'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
      isExpired: json['isExpired'] as bool? ?? false,
      expiredAt: json['expiredAt'] != null ? DateTime.parse(json['expiredAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'topicImage': topicImage,
      'guideText': guideText,
      'participantCount': participantCount,
      'isExpired': isExpired,
      'expiredAt': expiredAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  GroupTopicCardModel copyWith({
    String? id,
    String? groupId,
    String? topicId,
    String? topicTitle,
    String? topicImage,
    String? guideText,
    int? participantCount,
    bool? isExpired,
    DateTime? expiredAt,
    DateTime? createdAt,
  }) {
    return GroupTopicCardModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      topicImage: topicImage ?? this.topicImage,
      guideText: guideText ?? this.guideText,
      participantCount: participantCount ?? this.participantCount,
      isExpired: isExpired ?? this.isExpired,
      expiredAt: expiredAt ?? this.expiredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
