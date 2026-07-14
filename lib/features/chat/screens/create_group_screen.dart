import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/chat/blocs/chat_membership_cubit.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/locator.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final ChatMembershipCubit _cubit;
  final _name = TextEditingController();
  final _mobiles = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _limit = 100;

  @override
  void initState() {
    super.initState();
    _cubit = ChatMembershipCubit(repository: locator<ChatRepository>());
  }

  @override
  void dispose() {
    _cubit.close();
    _name.dispose();
    _mobiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('ساخت گروه'),
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
        builder:
            (context, state) => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'نام گروه'),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'نام گروه لازم است'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mobiles,
                    maxLines: 4,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'شماره اعضا (هر شماره در یک خط)',
                      helperText:
                          'اختیاری؛ فقط شماره موبایل دقیق پذیرفته می‌شود.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('سقف اعضای این گروه: ${_limit.round()} نفر'),
                  Slider(
                    value: _limit,
                    min: 2,
                    max: 100,
                    divisions: 98,
                    label: _limit.round().toString(),
                    onChanged: (value) => setState(() => _limit = value),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: state.busy ? null : _create,
                    icon:
                        state.busy
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.group_add),
                    label: const Text('ساخت گروه'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final mobiles =
        _mobiles.text
            .split(RegExp(r'[\n,\s]+'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
    final room = await _cubit.createGroup(
      name: _name.text.trim(),
      maxParticipants: _limit.round(),
      memberMobiles: mobiles,
    );
    if (room != null && mounted) Navigator.pop(context, room);
  }
}
