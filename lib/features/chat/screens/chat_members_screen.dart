import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/chat/blocs/chat_membership_cubit.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/models/chat_participant_model.dart';
import 'package:asood/features/chat/data/models/chat_room_model.dart';
import 'package:asood/locator.dart';

class ChatMembersScreen extends StatefulWidget {
  const ChatMembersScreen({super.key, required this.room});

  final ChatRoomModel room;

  @override
  State<ChatMembersScreen> createState() => _ChatMembersScreenState();
}

class _ChatMembersScreenState extends State<ChatMembersScreen> {
  late final ChatMembershipCubit _cubit;

  bool get _isOwner => widget.room.currentUserRole == 'owner';
  bool get _isAdmin => widget.room.currentUserRole == 'admin';

  @override
  void initState() {
    super.initState();
    _cubit = ChatMembershipCubit(repository: locator<ChatRepository>())
      ..load(widget.room.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('اعضای گفتگو'),
        actions: [
          if (_isOwner || _isAdmin)
            IconButton(
              tooltip: 'افزودن عضو',
              onPressed: _showAddMember,
              icon: const Icon(Icons.person_add_alt_1),
            ),
        ],
      ),
      body: BlocConsumer<ChatMembershipCubit, ChatMembershipState>(
        bloc: _cubit,
        listenWhen:
            (previous, current) =>
                previous.error != current.error && current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          if (state.status == ChatMembershipStatus.loading &&
              state.participants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ChatMembershipStatus.failure) {
            return Center(
              child: ElevatedButton(
                onPressed: () => _cubit.load(widget.room.id),
                child: const Text('تلاش دوباره'),
              ),
            );
          }
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final participant in state.participants)
                    _participantTile(participant),
                ],
              ),
              if (state.busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'خروج از گروه',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _participantTile(ChatParticipantModel participant) {
    final actions = <PopupMenuEntry<String>>[];
    if (_isOwner && participant.role != 'owner') {
      actions.add(
        PopupMenuItem(
          value: participant.role == 'admin' ? 'member' : 'admin',
          child: Text(
            participant.role == 'admin' ? 'تبدیل به عضو' : 'تبدیل به مدیر',
          ),
        ),
      );
      actions.add(
        const PopupMenuItem(value: 'transfer', child: Text('انتقال مالکیت')),
      );
      actions.add(
        const PopupMenuItem(value: 'remove', child: Text('حذف از گروه')),
      );
    } else if (_isAdmin && participant.role == 'member') {
      actions.add(
        const PopupMenuItem(value: 'remove', child: Text('حذف از گروه')),
      );
    }
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(participant.name),
      subtitle: Text(_roleLabel(participant.role)),
      trailing:
          actions.isEmpty
              ? null
              : PopupMenuButton<String>(
                itemBuilder: (_) => actions,
                onSelected: (action) => _perform(action, participant),
              ),
    );
  }

  Future<void> _showAddMember() async {
    final mobileController = TextEditingController();
    var role = 'member';
    final submitted = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('افزودن عضو'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'شماره موبایل دقیق',
                        ),
                      ),
                      if (_isOwner)
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          items: const [
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('عضو'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('مدیر'),
                            ),
                          ],
                          onChanged:
                              (value) => setDialogState(
                                () => role = value ?? 'member',
                              ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('انصراف'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('افزودن'),
                    ),
                  ],
                ),
          ),
    );
    final mobile = mobileController.text.trim();
    mobileController.dispose();
    if (submitted == true && mobile.isNotEmpty) {
      await _cubit.add(mobileNumber: mobile, role: role);
    }
  }

  Future<void> _perform(String action, ChatParticipantModel participant) async {
    if (action == 'remove') {
      await _cubit.remove(participant.userId);
    } else if (action == 'transfer') {
      final confirmed = await _confirm(
        'مالکیت گروه به ${participant.name} منتقل شود؟',
      );
      if (confirmed && await _cubit.transfer(participant.userId) && mounted) {
        Navigator.pop(context, true);
      }
    } else {
      await _cubit.changeRole(participant.userId, action);
    }
  }

  Future<void> _leave() async {
    final confirmed = await _confirm('از این گروه خارج می‌شوید؟');
    if (confirmed && await _cubit.leave() && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('خیر'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('بله'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'مالک';
      case 'admin':
        return 'مدیر';
      default:
        return 'عضو';
    }
  }
}
