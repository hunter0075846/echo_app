class PrivateMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String type;
  final String content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime createdAt;

  const PrivateMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.type = 'text',
    required this.content,
    this.mediaUrl,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type,
      'content': content,
      'mediaUrl': mediaUrl,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}