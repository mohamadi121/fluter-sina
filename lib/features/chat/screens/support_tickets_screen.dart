import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/chat/blocs/support_cubit.dart';
import 'package:asood/features/chat/screens/chat_page.dart';
import 'package:asood/locator.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  late final SupportCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SupportCubit(api: locator())..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تیکت جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'موضوع'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'توضیحات'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ثبت'),
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      subjectController.dispose();
      descriptionController.dispose();
      return;
    }

    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();
    subjectController.dispose();
    descriptionController.dispose();

    if (subject.isEmpty || description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موضوع و توضیحات را کامل کنید')),
        );
      }
      return;
    }

    final roomId = await _cubit.create(
      subject: subject,
      description: description,
    );
    if (roomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(roomId: roomId, roomName: subject),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('پشتیبانی'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colora.primaryColor,
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<SupportCubit, SupportState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.status == SupportStatus.loading ||
              state.status == SupportStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SupportStatus.failure && state.tickets.isEmpty) {
            return Center(child: Text(state.error ?? 'خطا در دریافت تیکت‌ها'));
          }
          if (state.tickets.isEmpty) {
            return const Center(child: Text('تیکتی ثبت نشده است'));
          }
          return RefreshIndicator(
            onRefresh: _cubit.load,
            child: ListView.builder(
              itemCount: state.tickets.length,
              itemBuilder: (context, index) {
                final ticket = state.tickets[index];
                return _TicketTile(
                  ticket: ticket,
                  onOpen: () {
                    final roomId = ticket['chat_room_id']?.toString();
                    if (roomId != null && roomId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatPage(
                                roomId: roomId,
                                roomName:
                                    ticket['subject']?.toString() ?? 'تیکت',
                              ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onOpen});

  final Map<String, dynamic> ticket;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = ticket['status']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onOpen,
        title: Text(ticket['subject']?.toString() ?? '—'),
        subtitle: Text(
          ticket['description']?.toString() ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(
            _statusLabel(status),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'resolved':
        return 'حل‌شده';
      case 'closed':
        return 'بسته';
      case 'in_progress':
        return 'در حال بررسی';
      default:
        return status;
    }
  }
}
