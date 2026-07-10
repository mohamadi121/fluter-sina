/// A notification (`NotificationSerializer`).
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.data = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['notification_type']?.toString(),
      // read_at present (non-null) means the notification has been read.
      isRead: json['read_at'] != null,
      createdAt: _asDate(json['created_at'] ?? json['sent_at']),
      data:
          json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : const {},
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }

  static DateTime? _asDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
