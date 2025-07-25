import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/helper/snack_bar_util.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/create_workspace/presentation/bloc/create_workspace_bloc.dart';
import 'package:asood/features/create_workspace/presentation/screen/tab_screens/basic_info.dart';
import 'package:asood/features/create_workspace/presentation/screen/tab_screens/contacts_info.dart';
import 'package:asood/features/create_workspace/presentation/screen/tab_screens/location_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateWorkSpaceScreen extends StatefulWidget {
  const CreateWorkSpaceScreen({super.key});

  @override
  State<CreateWorkSpaceScreen> createState() => _CreateWorkSpaceScreenState();
}

class _CreateWorkSpaceScreenState extends State<CreateWorkSpaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final newIndex = _tabController.index;
    if (newIndex != _activeTabIndex) {
      _activeTabIndex = newIndex;
      context.read<CreateWorkSpaceBloc>().add(
        ChangeWorkspaceTabView(activeTabIndex: newIndex),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// on back button if user presses to get pre tab
  void onBack(BuildContext context) {
    var bloc = context.read<CreateWorkSpaceBloc>();
    int index = bloc.state.activeTabIndex;
    if (index > 0) {
      bloc.add(ChangeWorkspaceTabView(activeTabIndex: index - 1));
    } else if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // context.pushReplacement(AppRoutes.vendorHome);
        context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CreateWorkSpaceBloc>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        onBack(context);
      },
      child: Container(
        color: Colora.primaryColor,
        child: SafeArea(
          child: Scaffold(
            body: BlocConsumer<CreateWorkSpaceBloc, CreateWorkSpaceState>(
              listener: (context, state) {
                if (_tabController.index != state.activeTabIndex) {
                  _tabController.index = state.activeTabIndex;
                }

                if (state.status == CWSStatus.failure) {
                  showSnackBar(context, "مشکلی پیش آمده مجددا تلاش کنید");
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Appbar Space
                          const SizedBox(height: 100),
                          _buildTabBar(state),
                          SizedBox(height: 10),
                          SizedBox(
                            height: Dimensions.height * 0.795,
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                BasicInfo(),
                                ContactsInfo(bloc: bloc),
                                LocationInfo(bloc: bloc),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const NewAppBar(title: 'ثبت دفتر کار'),
                    SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(CreateWorkSpaceState state) {
    return IgnorePointer(
      ignoring: true,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.transparent,
        tabs: [
          _buildTab(state, 'مشخصات پایه', 0),
          _buildTab(state, 'مشخصات ارتباطی', 1),
          _buildTab(state, 'مشخصات مکانی', 2),
        ],
      ),
    );
  }

  Widget _buildTab(CreateWorkSpaceState state, String label, int index) {
    final isActive = state.activeTabIndex == index;
    final tabColor = isActive ? Colora.primaryColor : Colors.white;
    final textColor = isActive ? Colors.white : Colora.primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        height: Dimensions.height * 0.1,
        width: Dimensions.width * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: tabColor,
          border: Border.all(color: Colora.primaryColor, width: 2),
        ),
        child: Center(
          child: FittedBox(
            child: Text(label, style: TextStyle(color: textColor)),
          ),
        ),
      ),
    );

    // return Container(
    //   width: Dimensions.width * 0.3,
    //   padding: const EdgeInsets.symmetric(vertical: 10.0),
    //   margin: const EdgeInsets.symmetric(vertical: 10.0),
    //   decoration: BoxDecoration(
    //     color: tabColor,
    //     borderRadius: BorderRadius.circular(50),
    //     border: Border.all(color: Colora.primaryColor, width: 2),
    //   ),
    //   child: Center(
    //     child: FittedBox(
    //       child: Text(label, style: TextStyle(color: textColor)),
    //     ),
    //   ),
    // );
  }
}
