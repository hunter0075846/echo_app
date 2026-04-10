import 'user_model.dart';

class TopicModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;
  final UserModel author;
  final int viewCount;
  final int commentCount;
  final int likeCount;
  final int forwardCount;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TopicModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.author,
    this.viewCount = 0,
    this.commentCount = 0,
    this.likeCount = 0,
    this.forwardCount = 0,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
      viewCount: json['viewCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      forwardCount: json['forwardCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'author': author.toJson(),
      'viewCount': viewCount,
      'commentCount': commentCount,
      'likeCount': likeCount,
      'forwardCount': forwardCount,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TopicModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? sourceUrl,
    UserModel? author,
    int? viewCount,
    int? commentCount,
    int? likeCount,
    int? forwardCount,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      author: author ?? this.author,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      forwardCount: forwardCount ?? this.forwardCount,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TopicCommentModel {
  final String id;
  final String topicId;
  final UserModel author;
  final String content;
  final String? parentId;
  final int likeCount;
  final DateTime? createdAt;

  const TopicCommentModel({
    required this.id,
    required this.topicId,
    required this.author,
    required this.content,
    this.parentId,
    this.likeCount = 0,
    this.createdAt,
  });

  factory TopicCommentModel.fromJson(Map<String, dynamic> json) {
    return TopicCommentModel(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      parentId: json['parentId'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'author': author.toJson(),
      'content': content,
      'parentId': parentId,
      'likeCount': likeCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  TopicCommentModel copyWith({
    String? id,
    String? topicId,
    UserModel? author,
    String? content,
    String? parentId,
    int? likeCount,
    DateTime? createdAt,
  }) {
    return TopicCommentModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      author: author ?? this.author,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
