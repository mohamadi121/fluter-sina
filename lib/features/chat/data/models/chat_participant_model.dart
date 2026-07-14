class ChatParticipantModel {
  final int id;
  final int userId;
  final String displayName;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? joinedAt;

  const ChatParticipantModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.joinedAt,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user']),
      displayName: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
    );
  }

  String get name {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : displayName;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
