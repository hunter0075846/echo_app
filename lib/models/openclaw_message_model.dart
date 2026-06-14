/// OpenClaw 聊天记录模型
class OpenClawMessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final String status;
  final DateTime? readAt;

  const OpenClawMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = 'sent',
    this.readAt,
  });

  factory OpenClawMessageModel.fromJson(Map<String, dynamic> json) {
    return OpenClawMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? json['created_at'] as String),
      status: json['status'] as String? ?? 'sent',
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : (json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isUnread => isAssistant && status != 'read';

  OpenClawMessageModel copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    String? status,
    DateTime? readAt,
  }) {
    return OpenClawMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
    );
  }
}
