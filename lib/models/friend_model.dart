class FriendModel {
  final String id;
  final String friendId;
  final String phone;
  final String? nickname;
  final String? avatar;
  final DateTime createdAt;

  const FriendModel({
    required this.id,
    required this.friendId,
    required this.phone,
    this.nickname,
    this.avatar,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      friendId: json['friendId'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendId': friendId,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FriendRequestModel {
  final String id;
  final String userId;
  final String phone;
  final String? nickname;
  final String? avatar;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.userId,
    required this.phone,
    this.nickname,
    this.avatar,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ConversationModel {
  final String userId;
  final String phone;
  final String? nickname;
  final String? avatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.userId,
    required this.phone,
    this.nickname,
    this.avatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      userId: json['userId'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      lastMessage: json['lastMessage'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}