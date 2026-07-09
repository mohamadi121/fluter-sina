import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/custom_textfield.dart';
import 'package:asood/features/market/presentation/blocs/edit_market/edit_market_cubit.dart';

/// Basic market info tab: name / description / slogan / national code.
/// Contract: PUT owner/market/update/{pk}/ (MarketUpdateSerializer).
class BasicInfo extends StatefulWidget {
  const BasicInfo({super.key});

  @override
  State<BasicInfo> createState() => _BasicInfoState();
}

class _BasicInfoState extends State<BasicInfo> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final sloganController = TextEditingController();
  final nationalCodeController = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    sloganController.dispose();
    nationalCodeController.dispose();
    super.dispose();
  }

  void _hydrateFrom(EditMarketState state) {
    if (_hydrated || state.market.isEmpty) {
      return;
    }
    _hydrated = true;
    nameController.text = state.market['name']?.toString() ?? '';
    descriptionController.text = state.market['description']?.toString() ?? '';
    sloganController.text = state.market['slogan']?.toString() ?? '';
    nationalCodeController.text =
        state.market['national_code']?.toString() ?? '';
  }

  void _save(BuildContext context, EditMarketState state) {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('نام فروشگاه را وارد کنید')));
      return;
    }
    context.read<EditMarketCubit>().saveBasic({
      'type': state.market['type'],
      'business_id': state.market['business_id'],
      'sub_category': state.market['sub_category'],
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'slogan': sloganController.text.trim(),
      'national_code': nationalCodeController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditMarketCubit, EditMarketState>(
      builder: (context, state) {
        _hydrateFrom(state);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: nameController,
                text: 'نام فروشگاه',
                isRequired: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descriptionController,
                text: 'توضیحات',
                maxLine: 4,
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: sloganController, text: 'شعار'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nationalCodeController,
                text: 'کد ملی',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPress: () => _save(context, state),
                color: Colora.primaryColor,
                textColor: Colora.scaffold,
                text:
                    state.status == EditMarketStatus.saving
                        ? '...در حال ذخیره'
                        : 'ذخیره اطلاعات',
              ),
            ],
          ),
        );
      },
    );
  }
}
