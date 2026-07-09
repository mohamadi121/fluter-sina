import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/custom_textfield.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/bloc/discount_cubit.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/data/discount_api_service.dart';
import 'package:asood/locator.dart';

/// Owner discount management for a market: create a percentage code with
/// an expiry, list existing codes, delete them.
class TakhfifScreen extends StatefulWidget {
  const TakhfifScreen({super.key, required this.marketId});

  final String marketId;

  @override
  State<TakhfifScreen> createState() => _TakhfifScreenState();
}

class _TakhfifScreenState extends State<TakhfifScreen> {
  final percentageController = TextEditingController();
  final daysController = TextEditingController();
  final limitController = TextEditingController();

  late final DiscountCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DiscountCubit(api: locator<DiscountApiService>())..load();
  }

  @override
  void dispose() {
    percentageController.dispose();
    daysController.dispose();
    limitController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _create() {
    final percentage = int.tryParse(percentageController.text.trim());
    final days = int.tryParse(daysController.text.trim());
    if (percentage == null || percentage < 1 || percentage > 100) {
      _snack('درصد تخفیف باید بین ۱ تا ۱۰۰ باشد');
      return;
    }
    if (days == null || days < 1) {
      _snack('مدت اعتبار (روز) را وارد کنید');
      return;
    }
    _cubit.create(
      contentType: 'market',
      objectId: widget.marketId,
      percentage: percentage,
      expiry: DateTime.now().add(Duration(days: days)),
      limitation: int.tryParse(limitController.text.trim()),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: DefaultAppBar(),
        body: BlocConsumer<DiscountCubit, DiscountState>(
          listener: (context, state) {
            if (state.status == DiscountStatus.saved) {
              percentageController.clear();
              daysController.clear();
              limitController.clear();
              _snack('کد تخفیف ساخته شد');
            } else if (state.status == DiscountStatus.failure &&
                state.error != null) {
              _snack(state.error!);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCreateCard(state),
                  const SizedBox(height: 20),
                  const Text(
                    'کدهای تخفیف فعال',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  if (state.status == DiscountStatus.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.discounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('کد تخفیفی ثبت نشده است')),
                    )
                  else
                    ...state.discounts.map((d) => _buildDiscountTile(d)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreateCard(DiscountState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colora.scaffold,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.4),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ساخت کد تخفیف جدید',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: percentageController,
            text: 'درصد تخفیف',
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: daysController,
            text: 'مدت اعتبار (روز)',
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: limitController,
            text: 'سقف تعداد استفاده (اختیاری)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPress: _create,
            color: Colora.primaryColor,
            textColor: Colora.scaffold,
            text:
                state.status == DiscountStatus.saving
                    ? '...در حال ثبت'
                    : 'ساخت کد تخفیف',
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTile(Map<String, dynamic> discount) {
    final code = discount['code']?.toString() ?? '—';
    final percentage = discount['percentage']?.toString() ?? '?';
    final expiry = discount['expiry']?.toString().split('T').first ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('$code — $percentage٪'),
        subtitle: Text('انقضا: $expiry'),
        leading: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _cubit.delete(discount['id'].toString()),
        ),
      ),
    );
  }
}
