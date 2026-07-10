import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/chat/blocs/chat_room_bloc.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/chat_socket.dart';
import 'package:asood/features/chat/data/models/chat_message_model.dart';
import 'package:asood/locator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.roomId, required this.roomName});

  final String roomId;
  final String roomName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRoomBloc _bloc;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = ChatRoomBloc(
      repository: locator<ChatRepository>(),
      socket: locator<ChatSocket>(),
    )..add(LoadRoom(widget.roomId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Older messages load when scrolled near the top.
    if (_scrollController.position.pixels <= 80) {
      _bloc.add(const LoadMoreMessages());
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _bloc.add(SendChatMessage(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: BlocBuilder<ChatRoomBloc, ChatRoomState>(
          bloc: _bloc,
          buildWhen:
              (a, b) =>
                  a.connection != b.connection ||
                  a.otherTyping != b.otherTyping,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.roomName, style: const TextStyle(fontSize: 16)),
                Text(
                  _subtitle(state),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatRoomBloc, ChatRoomState>(
              bloc: _bloc,
              listenWhen: (a, b) => a.error != b.error && b.error != null,
              listener: (context, state) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.error!)));
              },
              builder: (context, state) {
                if (state.status == ChatRoomStatus.loading ||
                    state.status == ChatRoomStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == ChatRoomStatus.failure) {
                  return Center(
                    child: Text(state.error ?? 'خطا در بارگذاری گفتگو'),
                  );
                }
                if (state.messages.isEmpty) {
                  return const Center(child: Text('هنوز پیامی نیست'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return _MessageBubble(
                      message: message,
                      mine: message.isMine(state.currentUserId),
                    );
                  },
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  String _subtitle(ChatRoomState state) {
    if (state.otherTyping) {
      return 'در حال نوشتن...';
    }
    switch (state.connection) {
      case ChatConnection.live:
        return 'آنلاین';
      case ChatConnection.connecting:
        return 'در حال اتصال...';
      case ChatConnection.offline:
        return 'آفلاین';
    }
  }

  Widget _buildComposer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'پیام...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colora.primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time =
        message.sentAt != null
            ? DateFormat('HH:mm').format(message.sentAt!.toLocal())
            : '';
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? Colora.primaryColor : Colora.lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine && message.senderUsername != null)
              Text(
                message.senderUsername!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (message.replyToContent != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.replyToContent!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(color: mine ? Colors.white : Colors.black87),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 9,
                color: mine ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
