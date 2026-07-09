import 'package:asood/core/router/app_routers.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/customer/presentation/blocs/public_markets/public_markets_cubit.dart';
import 'package:asood/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:asood/core/constants/constants.dart';

import 'package:asood/core/widgets/order_card_widget.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _activeTabIndex; // To keep track of the active tab
  bool isStoreMenuVisible = false;
  bool isOrderMenuVisible = false;

  late final PublicMarketsCubit _marketsCubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _activeTabIndex = _tabController.index; // Set initial active tab index
    _marketsCubit = PublicMarketsCubit(api: locator())..load();
  }

  void _onTabChanged() {
    setState(() {
      _activeTabIndex = _tabController.index; // Update the active tab index
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _marketsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colora.primaryColor,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: Dimensions.height * 0.11),

                    // tab bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: null,
                        indicatorPadding: EdgeInsets.zero,
                        indicatorSize: TabBarIndicatorSize.label,

                        padding: EdgeInsets.zero,
                        dividerHeight: 0,
                        isScrollable: false,

                        indicatorColor:
                            Colors.transparent, // Remove indicator color
                        tabs: [
                          buildTab('لیست فروشگاه‌ها', 0),
                          buildTab('درخواست جدید', 1),
                          buildTab('آمار و خرید', 2),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: Dimensions.height * .795,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // buildTabStoreList(state),
                          buildTabStoreList(),

                          // buildTabOrderList(bloc),
                          buildTabOrderList(),

                          Container(
                            width: Dimensions.width,
                            height: Dimensions.height,
                            color: Colors.greenAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const NewAppBar(title: 'رهیابی خرید'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTab(String label, int tabIndex) {
    bool isActive = _activeTabIndex == tabIndex; // Check if tab is active
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 7.0),
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      width: Dimensions.width,
      decoration: BoxDecoration(
        color: isActive ? Colora.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colora.primaryColor, width: 2),
      ),
      child: Align(
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colora.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTabStoreList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => _marketsCubit.load(search: value.trim()),
            decoration: InputDecoration(
              hintText: 'جستجوی فروشگاه...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed:
                    () => _marketsCubit.load(
                      search: _searchController.text.trim(),
                    ),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == PublicMarketsStatus.failure) {
                return Center(
                  child: Text(state.error ?? 'خطا در دریافت فروشگاه‌ها'),
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
                      subtitle: Text(market.subCategoryTitle?.toString() ?? ''),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildTabOrderList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colora.primaryColor,
          ),
          child: const Text(
            "لیست فروشگاه‌های احمدی",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        const Divider(thickness: 1),
        const SizedBox(height: 5),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return OrderCard(index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget buildTabStatList() {
    return ListView(
      children: List.generate(
        10,
        (index) => ListTile(title: Text('آمار و خرید Item $index')),
      ),
    );
  }
}
