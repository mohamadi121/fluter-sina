import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/profile/bloc/profile_cubit.dart';
import 'package:asood/features/profile/data/profile_api_service.dart';
import 'package:asood/locator.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  late final ProfileCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _nationalCode = TextEditingController();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit(api: locator<ProfileApiService>())..load();
  }

  void _fill(Map<String, dynamic> data) {
    if (_filled) return;
    final profile = data['profile'];
    if (profile is Map) {
      _nationalCode.text = profile['national_code']?.toString() ?? '';
      _address.text = profile['address']?.toString() ?? '';
      _birthDate.text = profile['birth_date']?.toString() ?? '';
    }
    _filled = true;
  }

  @override
  void dispose() {
    _nationalCode.dispose();
    _address.dispose();
    _birthDate.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('پروفایل'),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded) {
            _fill(state.data);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.initial ||
              state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          _fill(state.data);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  initialValue: state.data['mobile_number']?.toString() ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nationalCode,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'کد ملی',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value != null && RegExp(r'^\d{10}$').hasMatch(value)
                              ? null
                              : 'کد ملی باید ۱۰ رقم باشد',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _address,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'آدرس',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthDate,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'تاریخ تولد (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      state.status == ProfileStatus.saving
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final saved = await _cubit.save({
                              'national_code': _nationalCode.text,
                              'address': _address.text,
                              'birth_date':
                                  _birthDate.text.isEmpty
                                      ? null
                                      : _birthDate.text,
                            });
                            if (!context.mounted) return;
                            if (saved) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('پروفایل ذخیره شد'),
                                ),
                              );
                            }
                          },
                  child:
                      state.status == ProfileStatus.saving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('ذخیره'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
