import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/bank_card/bloc/bank_info_cubit.dart';
import 'package:asood/features/bank_card/domain/bank_validators.dart';
import 'package:asood/locator.dart';

class BankCardListScreen extends StatefulWidget {
  const BankCardListScreen({super.key});

  @override
  State<BankCardListScreen> createState() => _BankCardListScreenState();
}

class _BankCardListScreenState extends State<BankCardListScreen> {
  late final BankInfoCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<BankInfoCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openEditor(
    BankInfoState state, [
    Map<String, dynamic>? existing,
  ]) async {
    if (state.banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فهرست بانک‌ها در دسترس نیست')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    var selectedBankId =
        existing?['bank_info_id']?.toString() ??
        state.banks.first['id'].toString();
    if (!state.banks.any((bank) => bank['id'].toString() == selectedBankId)) {
      selectedBankId = state.banks.first['id'].toString();
    }
    final fullName = TextEditingController(
      text: existing?['full_name']?.toString(),
    );
    final card = TextEditingController(
      text: existing?['card_number']?.toString(),
    );
    final account = TextEditingController(
      text: existing?['account_number']?.toString(),
    );
    final iban = TextEditingController(text: existing?['iban']?.toString());
    final branchId = TextEditingController(
      text: existing?['branch_id']?.toString(),
    );
    final branchName = TextEditingController(
      text: existing?['branch_name']?.toString(),
    );
    final description = TextEditingController(
      text: existing?['description']?.toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    existing == null
                        ? 'افزودن اطلاعات بانکی'
                        : 'ویرایش اطلاعات بانکی',
                  ),
                  content: SizedBox(
                    width: 520,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: selectedBankId,
                              decoration: const InputDecoration(
                                labelText: 'بانک',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  state.banks
                                      .map(
                                        (bank) => DropdownMenuItem(
                                          value: bank['id'].toString(),
                                          child: Text(
                                            bank['name']?.toString() ?? '',
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setDialogState(
                                    () =>
                                        selectedBankId =
                                            value ?? selectedBankId,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: fullName,
                              label: 'نام صاحب حساب',
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: card,
                              label: 'شماره کارت ۱۶ رقمی',
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator:
                                  (value) =>
                                      isValidBankCardNumber(value ?? '')
                                          ? null
                                          : 'شماره کارت یا رقم کنترل آن معتبر نیست',
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: account,
                              label: 'شماره حساب',
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator:
                                  (value) =>
                                      RegExp(
                                            r'^\d{1,32}$',
                                          ).hasMatch(value ?? '')
                                          ? null
                                          : 'شماره حساب معتبر وارد کنید',
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: iban,
                              label: 'شبا (اختیاری، IR + ۲۴ رقم)',
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                final normalized =
                                    (value ?? '')
                                        .replaceAll(' ', '')
                                        .toUpperCase();
                                if (normalized.isEmpty) return null;
                                return isValidIranianIban(normalized)
                                    ? null
                                    : 'ساختار یا رقم کنترل شبا معتبر نیست';
                              },
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: branchId,
                              label: 'کد شعبه',
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator:
                                  (value) =>
                                      int.tryParse(value ?? '') != null
                                          ? null
                                          : 'کد شعبه الزامی است',
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: branchName,
                              label: 'نام شعبه',
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: description,
                              label: 'توضیحات (اختیاری)',
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('انصراف'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await _cubit.save(
                          id: existing?['id']?.toString(),
                          body: {
                            'bank_info': selectedBankId,
                            'full_name': fullName.text.trim(),
                            'card_number': card.text,
                            'account_number': account.text,
                            'iban':
                                iban.text.trim().isEmpty
                                    ? null
                                    : iban.text
                                        .replaceAll(' ', '')
                                        .toUpperCase(),
                            'branch_id': int.parse(branchId.text),
                            'branch_name': branchName.text.trim(),
                            'description': description.text.trim(),
                          },
                        );
                        if (dialogContext.mounted && ok) {
                          Navigator.pop(dialogContext, true);
                        }
                      },
                      child: const Text('ذخیره'),
                    ),
                  ],
                ),
          ),
    );

    for (final controller in [
      fullName,
      card,
      account,
      iban,
      branchId,
      branchName,
      description,
    ]) {
      controller.dispose();
    }
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اطلاعات بانکی ذخیره شد')));
    }
  }

  TextFormField _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'این فیلد الزامی است' : null;

  Future<void> _delete(Map<String, dynamic> info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف اطلاعات بانکی'),
            content: const Text('این مورد برای همیشه حذف شود؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final deleted = await _cubit.delete(info['id'].toString());
    if (deleted && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اطلاعات بانکی حذف شد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BankInfoCubit, BankInfoState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder:
          (context, state) => Scaffold(
            appBar: DefaultAppBar(title: 'اطلاعات بانکی'),
            floatingActionButton:
                state.status == BankInfoStatus.loaded
                    ? FloatingActionButton.extended(
                      onPressed: () => _openEditor(state),
                      icon: const Icon(Icons.add),
                      label: const Text('افزودن'),
                    )
                    : null,
            body: _body(state),
          ),
    );
  }

  Widget _body(BankInfoState state) {
    if (state.status == BankInfoStatus.initial ||
        state.status == BankInfoStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == BankInfoStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error ?? 'دریافت اطلاعات بانکی ناموفق بود'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cubit.load,
              child: const Text('تلاش دوباره'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.status == BankInfoStatus.saving)
          const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              children:
                  state.bankInfos.isEmpty
                      ? const [
                        SizedBox(height: 180),
                        Center(child: Text('هنوز اطلاعات بانکی ثبت نشده است')),
                      ]
                      : state.bankInfos
                          .map((info) => _bankInfoCard(state, info))
                          .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bankInfoCard(BankInfoState state, Map<String, dynamic> info) {
    final id = info['id'].toString();
    final pending = state.pendingIds.contains(id);
    final cardNumber = info['card_number']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.account_balance)),
        title: Text(info['bank_info']?.toString() ?? 'بانک'),
        subtitle: Text(_spacedCard(cardNumber)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _row('صاحب حساب', info['full_name']),
          _row('شماره حساب', info['account_number']),
          if ((info['iban']?.toString() ?? '').isNotEmpty)
            _row('شبا', info['iban']),
          _row(
            'شعبه',
            '${info['branch_name'] ?? ''} (${info['branch_id'] ?? ''})',
          ),
          if ((info['description']?.toString() ?? '').isNotEmpty)
            _row('توضیحات', info['description']),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'کپی شماره کارت',
                onPressed:
                    () => Clipboard.setData(ClipboardData(text: cardNumber)),
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: 'ویرایش',
                onPressed: pending ? null : () => _openEditor(state, info),
                icon: const Icon(Icons.edit),
              ),
              pending
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : IconButton(
                    tooltip: 'حذف',
                    onPressed: () => _delete(info),
                    icon: const Icon(Icons.delete_outline),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value?.toString() ?? '')),
        ],
      ),
    );
  }

  String _spacedCard(String value) {
    final digits = value.replaceAll(' ', '');
    return RegExp(
      '.{1,4}',
    ).allMatches(digits).map((match) => match.group(0)).join(' ');
  }
}
