import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/referral/bloc/referral_cubit.dart';
import 'package:asood/features/referral/data/referral_api_service.dart';
import 'package:asood/locator.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late final ReferralCubit _cubit;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ReferralCubit(api: locator<ReferralApiService>())..load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('دعوت دوستان'),
      ),
      body: BlocConsumer<ReferralCubit, ReferralState>(
        bloc: _cubit,
        listenWhen:
            (previous, current) =>
                previous.error != current.error && current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          if (state.status == ReferralStatus.loading ||
              state.status == ReferralStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.group_add_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${state.referralCount}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text('تعداد دوستان معرفی‌شده'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'کد معرف (شماره موبایل)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed:
                      state.status == ReferralStatus.submitting
                          ? null
                          : () async {
                            final applied = await _cubit.applyCode(
                              _codeController.text,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            if (applied) {
                              _codeController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('کد معرف با موفقیت ثبت شد'),
                                ),
                              );
                            }
                          },
                  child:
                      state.status == ReferralStatus.submitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('ثبت کد معرف'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
