import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/customer/presentation/blocs/public_markets/public_markets_cubit.dart';
import 'package:asood/locator.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late final PublicMarketsCubit _marketsCubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _marketsCubit = PublicMarketsCubit(api: locator())..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _marketsCubit.close();
    super.dispose();
  }

  void _search() => _marketsCubit.load(search: _searchController.text.trim());

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colora.primaryColor,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: Dimensions.height * 0.11),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'جستجوی فروشگاه...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _search,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<PublicMarketsCubit, PublicMarketsState>(
                      bloc: _marketsCubit,
                      builder: (context, state) {
                        if (state.status == PublicMarketsStatus.loading ||
                            state.status == PublicMarketsStatus.initial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.status == PublicMarketsStatus.failure) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(state.error ?? 'خطا در دریافت فروشگاه‌ها'),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _search,
                                  child: const Text('تلاش دوباره'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (state.markets.isEmpty) {
                          return const Center(child: Text('فروشگاهی یافت نشد'));
                        }
                        return ListView.builder(
                          itemCount: state.markets.length,
                          itemBuilder: (context, index) {
                            final market = state.markets[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                onTap:
                                    () => context.push(
                                      AppRoutes.marketPreview,
                                      extra: market,
                                    ),
                                leading: const Icon(Icons.storefront),
                                title: Text(market.name?.toString() ?? ''),
                                subtitle: Text(
                                  market.subCategoryTitle?.toString() ?? '',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const NewAppBar(title: 'رهیابی خرید'),
            ],
          ),
        ),
      ),
    );
  }
}
