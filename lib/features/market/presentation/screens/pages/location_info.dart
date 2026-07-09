import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/custom_textfield.dart';
import 'package:asood/features/market/presentation/blocs/edit_market/edit_market_cubit.dart';

/// Market location tab.
/// Contract: PUT owner/market/location/update/{market_id}/
/// (fields: city, address, zip_code, latitude, longitude).
class LocationInfo extends StatefulWidget {
  const LocationInfo({super.key});

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final zipCodeController = TextEditingController();
  bool _hydrated = false;
  String? _latitude;
  String? _longitude;

  @override
  void dispose() {
    cityController.dispose();
    addressController.dispose();
    zipCodeController.dispose();
    super.dispose();
  }

  void _hydrateFrom(EditMarketState state) {
    final location = state.location;
    if (_hydrated || location == null) {
      return;
    }
    _hydrated = true;
    cityController.text = location['city']?.toString() ?? '';
    addressController.text = location['address']?.toString() ?? '';
    zipCodeController.text = location['zip_code']?.toString() ?? '';
    _latitude = location['latitude']?.toString();
    _longitude = location['longitude']?.toString();
  }

  void _save(BuildContext context) {
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('آدرس را وارد کنید')));
      return;
    }
    context.read<EditMarketCubit>().saveLocation({
      'city': cityController.text.trim(),
      'address': addressController.text.trim(),
      'zip_code': zipCodeController.text.trim(),
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
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
              CustomTextField(controller: cityController, text: 'شهر'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: addressController,
                text: 'آدرس',
                maxLine: 3,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: zipCodeController,
                text: 'کد پستی',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPress: () => _save(context),
                color: Colora.primaryColor,
                textColor: Colora.scaffold,
                text:
                    state.status == EditMarketStatus.saving
                        ? '...در حال ذخیره'
                        : 'ذخیره موقعیت',
              ),
            ],
          ),
        );
      },
    );
  }
}
