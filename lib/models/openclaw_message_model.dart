/// OpenClaw 聊天记录模型
class OpenClawMessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const OpenClawMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory OpenClawMessageModel.fromJson(Map<String, dynamic> json) {
    return OpenClawMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
