/// AI Agent 模型（用户自主配置的第三方Agent）
class AgentModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String model;
  final String baseUrl;
  final String? systemPrompt;
  final double temperature;
  final int maxTokens;
  final bool isActive;
  final DateTime? createdAt;

  const AgentModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.model,
    required this.baseUrl,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 2000,
    this.isActive = true,
    this.createdAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      model: json['model'] as String? ?? 'gpt-3.5-turbo',
      baseUrl: json['baseUrl'] as String? ?? '',
      systemPrompt: json['systemPrompt'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 2000,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'model': model,
      'baseUrl': baseUrl,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AgentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    String? model,
    String? baseUrl,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Agent 聊天记录模型
class AgentChatMessageModel {
  final String id;
  final String agentId;
  final String role;
  final String content;
  final DateTime createdAt;

  const AgentChatMessageModel({
    required this.id,
    required this.agentId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AgentChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AgentChatMessageModel(
      id: json['id'] as String,
      agentId: json['agentId'] as String? ?? json['agent_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
