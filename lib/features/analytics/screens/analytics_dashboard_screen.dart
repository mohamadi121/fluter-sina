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
  final _formatter = NumberFormat('#,###');

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
              final d = state.data;
              return RefreshIndicator(
                onRefresh: _cubit.load,
                child: GridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _tile('سفارش‌ها', _num(d['total_orders'])),
                    _tile('درآمد', '${_num(d['total_revenue'])} ت'),
                    _tile('کاربران', _num(d['total_users'])),
                    _tile('کاربران فعال', _num(d['active_users'])),
                    _tile('محصولات فروخته‌شده', _num(d['products_sold'])),
                    _tile('نرخ تبدیل', '${_pct(d['conversion_rate'])}٪'),
                    _tile('میانگین سفارش', '${_num(d['avg_order_value'])} ت'),
                    _tile('بازارها', _num(d['total_markets'])),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  String _num(dynamic v) {
    if (v is num) return _formatter.format(v);
    if (v is String) {
      final parsed = num.tryParse(v);
      return parsed != null ? _formatter.format(parsed) : v;
    }
    return '0';
  }

  String _pct(dynamic v) {
    final n = v is num ? v : num.tryParse('$v') ?? 0;
    return n.toStringAsFixed(1);
  }

  Widget _tile(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colora.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colora.primaryColor,
              fontSize: 22,
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
    );
  }
}
