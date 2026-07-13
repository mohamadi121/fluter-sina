import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/models/market_model.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/features/bookmarks/bloc/bookmark_cubit.dart';
import 'package:asood/locator.dart';

/// Bookmarked markets list (GET user/market/bookmark/).
class MyBookmarks extends StatefulWidget {
  const MyBookmarks({super.key});

  @override
  State<MyBookmarks> createState() => _MyBookmarksState();
}

class _MyBookmarksState extends State<MyBookmarks> {
  late final BookmarkCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<BookmarkCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
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
              Padding(
                padding: EdgeInsets.only(top: Dimensions.height * 0.12),
                child: BlocConsumer<BookmarkCubit, BookmarkState>(
                  bloc: _cubit,
                  listener: (context, state) {
                    if (state.error != null) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(content: Text(state.error!)));
                    }
                  },
                  builder: (context, state) {
                    if (state.status == BookmarkStatus.loading ||
                        state.status == BookmarkStatus.initial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == BookmarkStatus.failure) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.error ?? 'خطا در دریافت علاقه‌مندی‌ها',
                              style: const TextStyle(
                                color: Colora.backgroundSwitch,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _cubit.load,
                              child: const Text('تلاش دوباره'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.markets.isEmpty) {
                      return const Center(
                        child: Text(
                          'شما هیچ مارکتی را ذخیره نکرده اید',
                          style: TextStyle(
                            color: Colora.backgroundSwitch,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.markets.length,
                      itemBuilder: (context, index) {
                        return _BookmarkTile(
                          market: state.markets[index],
                          isPending: state.pendingIds.contains(
                            state.markets[index].id.toString(),
                          ),
                          onRemove:
                              () => _cubit.toggle(
                                state.markets[index].id.toString(),
                              ),
                        );
                      },
                    );
                  },
                ),
              ),
              const NewAppBar(title: 'لیست علاقه مندی ها'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.market,
    required this.isPending,
    required this.onRemove,
  });

  final MarketModel market;
  final bool isPending;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final logo = market.logoImg?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colora.lightBlue,
      ),
      child: ListTile(
        onTap: () => context.push(AppRoutes.marketPreview, extra: market),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child:
                (logo != null && logo.isNotEmpty && logo != 'null')
                    ? CachedNetworkImage(
                      imageUrl: logo,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) => const Icon(Icons.store),
                    )
                    : const Icon(Icons.store, color: Colora.scaffold),
          ),
        ),
        title: Text(
          market.name?.toString() ?? '',
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.white),
          onPressed: isPending ? null : onRemove,
        ),
      ),
    );
  }
}
