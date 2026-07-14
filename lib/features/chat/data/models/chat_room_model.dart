/// A chat room (`ChatRoomSerializer`).
class ChatRoomModel {
  final String id;
  final String name;
  final String? description;
  final String? roomType;
  final String? status;
  final int? participantCount;
  final int unreadCount;
  final bool isOnline;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? currentUserRole;
  final Map<String, bool> capabilities;

  const ChatRoomModel({
    required this.id,
    required this.name,
    this.description,
    this.roomType,
    this.status,
    this.participantCount,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastMessage,
    this.lastMessageAt,
    this.currentUserRole,
    this.capabilities = const {},
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['last_message'];
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      roomType: json['room_type']?.toString(),
      status: json['status']?.toString(),
      participantCount: _asInt(json['participant_count']),
      unreadCount: _asInt(json['unread_count']) ?? 0,
      isOnline: json['is_online'] == true,
      lastMessage:
          lastMessage is Map
              ? lastMessage['content']?.toString()
              : lastMessage?.toString(),
      lastMessageAt: _asDate(json['last_message_at']),
      currentUserRole: json['current_user_role']?.toString(),
      capabilities:
          json['capabilities'] is Map
              ? Map<String, bool>.from(
                (json['capabilities'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value == true),
                ),
              )
              : const {},
    );
  }

  bool capability(String name) => capabilities[name] == true;

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _asDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
