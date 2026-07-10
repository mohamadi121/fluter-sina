import 'package:flutter_test/flutter_test.dart';

import 'package:asood/features/chat/data/models/chat_message_model.dart';

void main() {
  test('parses REST shape (sender + created_at + reply_to_content)', () {
    final m = ChatMessageModel.fromJson({
      'id': 'a1',
      'sender': 7,
      'sender_username': 'ali',
      'content': 'سلام',
      'message_type': 'text',
      'created_at': '2026-07-01T10:00:00Z',
      'reply_to_content': 'قبلی',
      'reply_to_sender': 'reza',
    });

    expect(m.id, 'a1');
    expect(m.senderId, 7);
    expect(m.content, 'سلام');
    expect(m.sentAt, isNotNull);
    expect(m.replyToContent, 'قبلی');
    expect(m.isMine(7), isTrue);
    expect(m.isMine(9), isFalse);
    expect(m.isMine(null), isFalse);
  });

  test('parses WebSocket shape (sender_id + sent_at + nested reply_to)', () {
    final m = ChatMessageModel.fromJson({
      'id': 'b2',
      'sender_id': 3,
      'sender_username': 'sara',
      'content': 'hi',
      'message_type': 'text',
      'sent_at': '2026-07-01T11:00:00Z',
      'status': 'sent',
      'reply_to': {'content': 'x', 'sender_username': 'ali'},
    });

    expect(m.senderId, 3);
    expect(m.status, 'sent');
    expect(m.replyToContent, 'x');
    expect(m.replyToSender, 'ali');
  });
}
