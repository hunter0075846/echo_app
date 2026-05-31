/// OpenClaw 连接模型
class OpenClawConnectionModel {
  final String id;
  final String? name;
  final String? avatar;
  final String status; // pending, connected, disconnected
  final String? deviceName;
  final DateTime? connectedAt;
  final DateTime? lastPingAt;
  final DateTime createdAt;

  const OpenClawConnectionModel({
    required this.id,
    this.name,
    this.avatar,
    required this.status,
    this.deviceName,
    this.connectedAt,
    this.lastPingAt,
    required this.createdAt,
  });

  factory OpenClawConnectionModel.fromJson(Map<String, dynamic> json) {
    return OpenClawConnectionModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      status: json['status'] as String,
      deviceName: json['deviceName'] as String? ?? json['device_name'] as String?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      lastPingAt: json['lastPingAt'] != null
          ? DateTime.parse(json['lastPingAt'] as String)
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
    );
  }

  String get displayName => name ?? '我的OpenClaw';
  bool get isConnected => status == 'connected';
  bool get isPending => status == 'pending';
}
