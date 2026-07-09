import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:asood/features/market/presentation/blocs/edit_market/edit_market_cubit.dart';
import 'package:asood/locator.dart';

import 'pages/basic_info.dart';
import 'pages/contacts_info.dart';
import 'pages/location_info.dart';

class EditStoreInfoScreen extends StatefulWidget {
  const EditStoreInfoScreen({super.key, required this.marketId});

  final String marketId;

  @override
  State<EditStoreInfoScreen> createState() => _EditStoreInfoScreenState();
}

class _EditStoreInfoScreenState extends State<EditStoreInfoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final EditMarketCubit _cubit;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _cubit = EditMarketCubit(repo: locator<CreateMarketRepository>())
      ..load(widget.marketId);
  }

  void _onTabChanged() {
    setState(() => _activeTabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: DefaultAppBar(),
        body: SafeArea(
          child: BlocConsumer<EditMarketCubit, EditMarketState>(
            listener: (context, state) {
              if (state.status == EditMarketStatus.saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('تغییرات ذخیره شد'),
                  ),
                );
              } else if (state.status == EditMarketStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error ?? 'خطا در ذخیره‌سازی'),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.status == EditMarketStatus.loading ||
                  state.status == EditMarketStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              return Container(
                height: Dimensions.height,
                width: Dimensions.width,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.transparent,
                        tabs: [
                          buildTab('مشخصات پایه', 0),
                          buildTab('مشخصات ارتباطی', 1),
                          buildTab('مشخصات مکانی', 2),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          BasicInfo(),
                          ContactsInfo(),
                          LocationInfo(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildTab(String label, int tabIndex) {
    final isActive = _activeTabIndex == tabIndex;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colora.primaryColor,
        borderRadius: BorderRadius.circular(50),
        border: isActive ? Border.all(color: Colora.primaryColor) : null,
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: isActive ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}
