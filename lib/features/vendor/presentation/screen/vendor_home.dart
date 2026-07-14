import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/helper/snack_bar_util.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/logging/app_logger.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:asood/features/vendor/presentation/widgets/dashboard_carousel.dart';
import 'package:asood/features/vendor/presentation/widgets/item_box_with_title.dart';
import 'package:asood/features/vendor/presentation/widgets/simple_itembox.dart';

const Map<String, List<Map<String, Object>>> dashboardMenuConfig = {
  'firstMenu': [
    {
      'title': 'میز کار',
      'image': Icon(Icons.work_rounded, size: 60, color: Colors.white),
      'page': AppRoutes.createWorkSpace,
    },
    {
      'title': 'استعلام بها',
      'image': Icon(Icons.price_change_rounded, size: 60, color: Colors.white),
      'page': AppRoutes.inquiryRequests,
    },
  ],
  'secondMenu': [
    {
      'title': 'امور مالی',
      'image': Icon(Icons.account_balance, size: 60, color: Colors.white),
      'page': AppRoutes.finance,
    },
    {
      'title': 'رهیابی خرید',
      'image': Icon(Icons.shopping_bag, size: 60, color: Colors.white),
      'page': AppRoutes.customerDashboard,
    },
    {
      'title': 'اشتراک گذاری',
      'image': Icon(Icons.share, size: 60, color: Colors.white),
    },
    {
      'title': 'علاقه مندی',
      'image': Icon(Icons.favorite, size: 60, color: Colors.white),
      'page': AppRoutes.bookmarks,
    },
  ],
};

Future<void> _openWebsite(BuildContext context) async {
  try {
    final opened = await launchUrl(
      Uri.parse('https://asoud.ir/'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showSnackBar(context, 'باز کردن وب‌سایت ناموفق بود');
    }
  } catch (error, stackTrace) {
    AppLogger.error('vendor-home', 'website launch failed', error, stackTrace);
    if (context.mounted) {
      showSnackBar(context, 'باز کردن وب‌سایت ناموفق بود');
    }
  }
}

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WorkspaceBloc>().add(LoadStores());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colora.primaryColor,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: Dimensions.height * 0.12,
                  bottom: 16,
                ),
                child: const Column(
                  children: [
                    DashboardCarouselWidget(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.khorisontal,
                      ),
                      child: DashboardServicesWidget(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.khorisontal,
                      ),
                      child: DashboardAdditionalWidget(),
                    ),
                  ],
                ),
              ),
              const NewAppBar(title: 'خانه'),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 1,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.push(AppRoutes.vendorProfile);
                case 1:
                  break;
                case 2:
                  context.push(AppRoutes.shoppingCart);
                case 3:
                  _openWebsite(context);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'پروفایل',
              ),
              NavigationDestination(icon: Icon(Icons.home), label: 'خانه'),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                label: 'سبد',
              ),
              NavigationDestination(
                icon: Icon(Icons.share_outlined),
                label: 'اشتراک',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardAdditionalWidget extends StatelessWidget {
  const DashboardAdditionalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = dashboardMenuConfig['secondMenu']!;
    return _DashboardCard(
      title: 'امکانات:',
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ItemBoxTitle(
            onTap: () {
              final page = item['page'];
              if (page is String) {
                context.push(page);
              } else {
                _openWebsite(context);
              }
            },
            title: item['title']! as String,
            child: item['image']! as Widget,
          );
        },
      ),
    );
  }
}

class DashboardServicesWidget extends StatelessWidget {
  const DashboardServicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = dashboardMenuConfig['firstMenu']!;
    return BlocConsumer<WorkspaceBloc, WorkspaceState>(
      listener: (context, state) {
        if (state.status == CWSStatus.failure) {
          showSnackBar(context, 'بارگذاری کسب‌وکارها ناموفق بود');
        }
      },
      builder: (context, state) {
        return _DashboardCard(
          title: 'کسب‌وکار:',
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return SimpleItemBox(
                onTap: () {
                  if (index == 0) {
                    if (state.status == CWSStatus.initial ||
                        state.status == CWSStatus.loading) {
                      return;
                    }
                    if (state.status == CWSStatus.failure) {
                      context.read<WorkspaceBloc>().add(LoadStores());
                      return;
                    }
                    context.push(
                      state.storesList.isEmpty
                          ? AppRoutes.createWorkSpace
                          : AppRoutes.markets,
                    );
                    return;
                  }
                  context.push(item['page']! as String);
                },
                title: item['title']! as String,
                child: item['image']! as Widget,
              );
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: ATextStyle.lightBlue16.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
