import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/analytics/bloc/analytics_cubit.dart';
import 'package:asood/features/analytics/data/analytics_api_service.dart';
import 'package:asood/locator.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late final AnalyticsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AnalyticsCubit(api: locator<AnalyticsApiService>())..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('آمار و تحلیل'),
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        bloc: _cubit,
        builder: (context, state) {
          switch (state.status) {
            case AnalyticsStatus.loading:
            case AnalyticsStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case AnalyticsStatus.failure:
              return Center(child: Text(state.error ?? 'خطا در دریافت آمار'));
            case AnalyticsStatus.loaded:
              return _DashboardBody(data: state.data, onRefresh: _cubit.load);
          }
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data, required this.onRefresh});

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final tiles = <({String label, String value})>[
      (label: 'سفارش‌های پرداخت‌شده', value: _number(data['paid_orders'])),
      (label: 'درآمد ناخالص', value: '${_number(data['gross_revenue'])} تومان'),
      (label: 'خریداران یکتا', value: _number(data['unique_buyers'])),
      (label: 'تعداد فروش', value: _number(data['units_sold'])),
      (label: 'بازدید محصول', value: _number(data['product_views'])),
      (label: 'افزودن به سبد', value: _number(data['add_to_cart_count'])),
      (
        label: 'بازدیدکنندگان احرازشده',
        value: _number(data['authenticated_unique_product_viewers']),
      ),
      (label: 'نرخ تبدیل', value: '${_percent(data['conversion_rate'])}٪'),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          GrossRevenueDisclaimer(
            refundsDeducted: data['refunds_deducted'] == true,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: tileWidth,
                      height: 118,
                      child: _MetricTile(label: tile.label, value: tile.value),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// User-visible financial scope. This must stay adjacent to gross revenue.
class GrossRevenueDisclaimer extends StatelessWidget {
  const GrossRevenueDisclaimer({super.key, required this.refundsDeducted});

  final bool refundsDeducted;

  @override
  Widget build(BuildContext context) {
    if (refundsDeducted) return const SizedBox.shrink();
    return Container(
      key: const Key('gross-revenue-refund-disclaimer'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'درآمد نمایش‌داده‌شده ناخالص و پرداخت‌شده است؛ مبالغ بازپرداخت‌شده از آن کسر نشده است.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colora.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colora.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colora.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

final _numberFormat = NumberFormat('#,###.###');

String _number(dynamic value) {
  final number = value is num ? value : num.tryParse('$value');
  return number == null ? '۰' : _numberFormat.format(number);
}

String _percent(dynamic value) {
  final number = value is num ? value : num.tryParse('$value') ?? 0;
  return number.toStringAsFixed(1);
}
