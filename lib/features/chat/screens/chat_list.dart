import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/chat/blocs/chat_list_cubit.dart';
import 'package:asood/features/chat/data/models/chat_room_model.dart';
import 'package:asood/features/chat/screens/chat_page.dart';
import 'package:asood/features/chat/screens/create_group_screen.dart';
import 'package:asood/features/chat/screens/support_tickets_screen.dart';
import 'package:asood/locator.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late final ChatListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<ChatListCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colora.primaryColor,
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'create-chat-group',
                backgroundColor: Colora.primaryColor,
                onPressed: () async {
                  final room = await Navigator.push<ChatRoomModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  );
                  if (room != null) await _cubit.load();
                },
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: const Text(
                  'گروه جدید',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'chat-support',
                backgroundColor: Colora.primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupportTicketsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: const Text(
                  'پشتیبانی',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: Dimensions.height * 0.12),
                child: BlocBuilder<ChatListCubit, ChatListState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    switch (state.status) {
                      case ChatListStatus.loading:
                      case ChatListStatus.initial:
                        return const Center(child: CircularProgressIndicator());
                      case ChatListStatus.failure:
                        return _ErrorView(
                          message: state.error ?? 'خطا در دریافت گفتگوها',
                          onRetry: _cubit.load,
                        );
                      case ChatListStatus.loaded:
                        if (state.rooms.isEmpty) {
                          return const Center(
                            child: Text('گفتگویی وجود ندارد'),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _cubit.load,
                          child: ListView.builder(
                            itemCount: state.rooms.length,
                            itemBuilder:
                                (context, index) => _RoomTile(
                                  room: state.rooms[index],
                                  onChanged: _cubit.load,
                                ),
                          ),
                        );
                    }
                  },
                ),
              ),
              const NewAppBar(title: 'گفتگوها'),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onChanged});

  final ChatRoomModel room;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatPage(
                    roomId: room.id,
                    roomName: room.name,
                    room: room,
                  ),
            ),
          );
          if (changed == true) await onChanged();
        },
        leading: CircleAvatar(
          backgroundColor: Colora.primaryColor,
          child: Text(
            room.name.isNotEmpty ? room.name.characters.first : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(room.name),
        subtitle: Text(
          room.lastMessage ?? room.description ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            room.unreadCount > 0
                ? CircleAvatar(
                  radius: 11,
                  backgroundColor: Colora.primaryColor,
                  child: Text(
                    '${room.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                )
                : null,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
        ],
      ),
    );
  }
}
