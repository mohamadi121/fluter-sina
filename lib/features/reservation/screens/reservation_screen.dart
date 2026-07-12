import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/reservation/blocs/reservation_bloc.dart';
import 'package:asood/features/reservation/data/reservation_api_service.dart';
import 'package:asood/locator.dart';

/// Booking flow: pick a service -> specialist -> reserve-time -> confirm.
class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key, required this.marketId});

  final String marketId;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late final ReservationBloc _bloc;
  String? _selectedServiceId;
  String? _selectedSpecialistId;

  @override
  void initState() {
    super.initState();
    _bloc = ReservationBloc(api: locator<ReservationApiService>())
      ..add(LoadServices(widget.marketId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colora.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('رزرو نوبت'),
        ),
        body: BlocConsumer<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state.status == ReservationStatus.booked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('نوبت با موفقیت رزرو شد'),
                ),
              );
            } else if (state.status == ReservationStatus.failure &&
                state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state.status == ReservationStatus.loading ||
                state.status == ReservationStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'خدمات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (state.services.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('خدمتی ثبت نشده است'),
                  )
                else
                  ...state.services.map(
                    (s) => RadioListTile<String>(
                      value: s['id'].toString(),
                      groupValue: _selectedServiceId,
                      title: Text(s['name']?.toString() ?? 'خدمت'),
                      activeColor: Colora.primaryColor,
                      onChanged: (v) {
                        setState(() {
                          _selectedServiceId = v;
                          _selectedSpecialistId = null;
                        });
                        if (v != null) {
                          _bloc.add(LoadSpecialists(v));
                        }
                      },
                    ),
                  ),
                if (_selectedServiceId != null) ...[
                  const Divider(),
                  const Text(
                    'متخصص',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (state.specialists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('متخصصی برای این خدمت ثبت نشده است'),
                    )
                  else
                    ...state.specialists.map(
                      (specialist) => RadioListTile<String>(
                        value: specialist['id'].toString(),
                        groupValue: _selectedSpecialistId,
                        title: Text(
                          specialist['field']?.toString() ??
                              specialist['user']?.toString() ??
                              'متخصص',
                        ),
                        activeColor: Colora.primaryColor,
                        onChanged: (v) {
                          setState(() => _selectedSpecialistId = v);
                          if (v != null) {
                            _bloc.add(LoadReserveTimes(_selectedServiceId!));
                          }
                        },
                      ),
                    ),
                ],
                if (_selectedSpecialistId != null) ...[
                  const Divider(),
                  const Text(
                    'زمان‌های آزاد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (state.reserveTimes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('زمان آزادی موجود نیست'),
                    )
                  else
                    ...state.reserveTimes.map(
                      (t) => Card(
                        child: ListTile(
                          title: Text('${t['day'] ?? ''}  ${t['start'] ?? ''}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colora.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                state.status == ReservationStatus.booking
                                    ? null
                                    : () => _bloc.add(
                                      CreateReservation(
                                        reserveTimeId: t['id'].toString(),
                                        specialistId: _selectedSpecialistId!,
                                      ),
                                    ),
                            child: const Text('رزرو'),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
