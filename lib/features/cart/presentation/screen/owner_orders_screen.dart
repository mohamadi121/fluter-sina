import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/cart/data/data_source/owner_order_api_service.dart';
import 'package:asood/features/cart/presentation/bloc/owner_orders_cubit.dart';
import 'package:asood/locator.dart';

/// Seller's incoming orders — list with accept/reject (verify).
class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  late final OwnerOrdersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = OwnerOrdersCubit(api: locator<OwnerOrderApiService>())..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  final _formatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colora.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('سفارش‌های دریافتی'),
      ),
      body: BlocBuilder<OwnerOrdersCubit, OwnerOrdersState>(
        bloc: _cubit,
        builder: (context, state) {
          switch (state.status) {
            case OwnerOrdersStatus.loading:
            case OwnerOrdersStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case OwnerOrdersStatus.failure:
              return Center(
                child: Text(state.error ?? 'خطا در دریافت سفارش‌ها'),
              );
            case OwnerOrdersStatus.loaded:
              if (state.orders.isEmpty) {
                return const Center(child: Text('سفارشی وجود ندارد'));
              }
              return RefreshIndicator(
                onRefresh: _cubit.load,
                child: ListView.builder(
                  itemCount: state.orders.length,
                  itemBuilder:
                      (context, index) =>
                          _buildOrderCard(context, state.orders[index]),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final total = order['total'];
    final isPaid = order['is_paid'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order['description']?.toString() ?? 'سفارش',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مبلغ: ${_formatter.format(_toNum(total))} تومان'),
                Chip(
                  label: Text(
                    isPaid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                      isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _verify(context, id, false),
                  child: const Text('رد', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colora.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _verify(context, id, true),
                  child: const Text('تأیید'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, String id, bool accept) async {
    final ok = await _cubit.verify(id: id, verified: accept);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'سفارش تأیید شد' : 'سفارش رد شد')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cubit.state.error ?? 'خطا')));
    }
  }

  num _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }
}
