/// A chat message. Two backend shapes are merged here:
/// - REST (`room_messages`, `ChatMessageSerializer`): sender, sender_username,
///   content, message_type, created_at, reply_to_content, file_url, ...
/// - WebSocket (`chat_message` frame): sender_id, sender_username, content,
///   message_type, sent_at, status, reply_to{content,sender_username}.
class ChatMessageModel {
  final String id;
  final int? senderId;
  final String? senderUsername;
  final String content;
  final String messageType;
  final DateTime? sentAt;
  final String? status;
  final String? replyToContent;
  final String? replyToSender;
  final String? fileUrl;

  const ChatMessageModel({
    required this.id,
    this.senderId,
    this.senderUsername,
    required this.content,
    this.messageType = 'text',
    this.sentAt,
    this.status,
    this.replyToContent,
    this.replyToSender,
    this.fileUrl,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final replyTo = json['reply_to'];
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: _asInt(json['sender_id'] ?? json['sender']),
      senderUsername: json['sender_username']?.toString(),
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      sentAt: _asDate(json['sent_at'] ?? json['created_at']),
      status: json['status']?.toString(),
      replyToContent:
          (replyTo is Map ? replyTo['content'] : json['reply_to_content'])
              ?.toString(),
      replyToSender:
          (replyTo is Map
                  ? replyTo['sender_username']
                  : json['reply_to_sender'])
              ?.toString(),
      fileUrl: json['file_url']?.toString(),
    );
  }

  bool isMine(int? currentUserId) =>
      currentUserId != null && senderId == currentUserId;

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
