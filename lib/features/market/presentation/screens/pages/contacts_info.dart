import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/custom_textfield.dart';
import 'package:asood/features/market/presentation/blocs/edit_market/edit_market_cubit.dart';

/// Market contact tab.
/// Contract: PUT owner/market/contact/update/{market_id}/
/// (fields: first/second_mobile_number, telephone, fax, email, website_url).
class ContactsInfo extends StatefulWidget {
  const ContactsInfo({super.key});

  @override
  State<ContactsInfo> createState() => _ContactsInfoState();
}

class _ContactsInfoState extends State<ContactsInfo> {
  final firstMobileController = TextEditingController();
  final secondMobileController = TextEditingController();
  final telephoneController = TextEditingController();
  final faxController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    firstMobileController.dispose();
    secondMobileController.dispose();
    telephoneController.dispose();
    faxController.dispose();
    emailController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  void _hydrateFrom(EditMarketState state) {
    final contact = state.contact;
    if (_hydrated || contact == null) {
      return;
    }
    _hydrated = true;
    firstMobileController.text =
        contact['first_mobile_number']?.toString() ?? '';
    secondMobileController.text =
        contact['second_mobile_number']?.toString() ?? '';
    telephoneController.text = contact['telephone']?.toString() ?? '';
    faxController.text = contact['fax']?.toString() ?? '';
    emailController.text = contact['email']?.toString() ?? '';
    websiteController.text = contact['website_url']?.toString() ?? '';
  }

  void _save(BuildContext context) {
    if (firstMobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل اول الزامی است')),
      );
      return;
    }
    context.read<EditMarketCubit>().saveContact({
      'first_mobile_number': firstMobileController.text.trim(),
      'second_mobile_number': secondMobileController.text.trim(),
      'telephone': telephoneController.text.trim(),
      'fax': faxController.text.trim(),
      'email': emailController.text.trim(),
      'website_url': websiteController.text.trim(),
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
                controller: firstMobileController,
                text: 'شماره موبایل ۱',
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: secondMobileController,
                text: 'شماره موبایل ۲',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: telephoneController,
                text: 'تلفن ثابت',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: faxController,
                text: 'فکس',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                text: 'ایمیل',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: websiteController,
                text: 'وب‌سایت',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPress: () => _save(context),
                color: Colora.primaryColor,
                textColor: Colora.scaffold,
                text:
                    state.status == EditMarketStatus.saving
                        ? '...در حال ذخیره'
                        : 'ذخیره اطلاعات تماس',
              ),
            ],
          ),
        );
      },
    );
  }
}
