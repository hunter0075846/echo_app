class UserModel {
  final String id;
  final String phone;
  final String? nickname;
  final String? avatar;
  final String? gender;
  final DateTime? birthday;
  final int dailyTopicQuota;
  final int maxDailyTopicQuota;
  final DateTime? quotaResetAt;
  final int anonymousMessageCount;
  final DateTime? anonymousQuotaResetAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.nickname,
    this.avatar,
    this.gender,
    this.birthday,
    this.dailyTopicQuota = 0,
    this.maxDailyTopicQuota = 10,
    this.quotaResetAt,
    this.anonymousMessageCount = 0,
    this.anonymousQuotaResetAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
      dailyTopicQuota: json['dailyTopicQuota'] as int? ?? 0,
      maxDailyTopicQuota: json['maxDailyTopicQuota'] as int? ?? 10,
      quotaResetAt: json['quotaResetAt'] != null ? DateTime.parse(json['quotaResetAt'] as String) : null,
      anonymousMessageCount: json['anonymousMessageCount'] as int? ?? 0,
      anonymousQuotaResetAt: json['anonymousQuotaResetAt'] != null ? DateTime.parse(json['anonymousQuotaResetAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'dailyTopicQuota': dailyTopicQuota,
      'maxDailyTopicQuota': maxDailyTopicQuota,
      'quotaResetAt': quotaResetAt?.toIso8601String(),
      'anonymousMessageCount': anonymousMessageCount,
      'anonymousQuotaResetAt': anonymousQuotaResetAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? nickname,
    String? avatar,
    String? gender,
    DateTime? birthday,
    int? dailyTopicQuota,
    int? maxDailyTopicQuota,
    DateTime? quotaResetAt,
    int? anonymousMessageCount,
    DateTime? anonymousQuotaResetAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      dailyTopicQuota: dailyTopicQuota ?? this.dailyTopicQuota,
      maxDailyTopicQuota: maxDailyTopicQuota ?? this.maxDailyTopicQuota,
      quotaResetAt: quotaResetAt ?? this.quotaResetAt,
      anonymousMessageCount: anonymousMessageCount ?? this.anonymousMessageCount,
      anonymousQuotaResetAt: anonymousQuotaResetAt ?? this.anonymousQuotaResetAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
