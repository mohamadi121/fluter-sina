import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/affiliate/bloc/affiliate_cubit.dart';
import 'package:asood/features/affiliate/data/affiliate_api_service.dart';
import 'package:asood/locator.dart';

/// Products available for affiliate marketing.
class AffiliateProductsScreen extends StatefulWidget {
  const AffiliateProductsScreen({super.key});

  @override
  State<AffiliateProductsScreen> createState() =>
      _AffiliateProductsScreenState();
}

class _AffiliateProductsScreenState extends State<AffiliateProductsScreen> {
  late final AffiliateCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AffiliateCubit(api: locator<AffiliateApiService>())
      ..loadAvailable();
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
        title: const Text('همکاری در فروش'),
      ),
      body: BlocBuilder<AffiliateCubit, AffiliateState>(
        bloc: _cubit,
        builder: (context, state) {
          switch (state.status) {
            case AffiliateStatus.loading:
            case AffiliateStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case AffiliateStatus.failure:
              return Center(
                child: Text(state.error ?? 'خطا در دریافت محصولات'),
              );
            case AffiliateStatus.loaded:
            case AffiliateStatus.creating:
              if (state.products.isEmpty) {
                return const Center(
                  child: Text('محصولی برای همکاری موجود نیست'),
                );
              }
              return RefreshIndicator(
                onRefresh: _cubit.loadAvailable,
                child: ListView.builder(
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final p = state.products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.sell_outlined),
                        title: Text(p['name']?.toString() ?? 'محصول'),
                        subtitle: Text(
                          p['description']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          p['main_price']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colora.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
