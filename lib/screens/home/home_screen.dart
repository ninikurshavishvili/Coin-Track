import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/ticker.dart';
import '../../providers/tickers_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/coin_list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/states.dart';
import '../coin_detail/coin_detail_screen.dart';

enum HomeFilter { all, gainers, losers }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  HomeFilter _filter = HomeFilter.all;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tickersAsync = ref.watch(tickersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const _BrandTitle(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainerHighest,
              child: Icon(Icons.person_rounded, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: tickersAsync.when(
        loading: () => const LoadingList(),
        error: (error, _) => ErrorState(
          message: 'Could not load top coins right now.',
          onRetry: () => ref.invalidate(tickersProvider),
        ),
        data: (tickers) {
          final visible = _filtered(tickers);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tickersProvider);
              await ref.read(tickersProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SegmentedTabs(filter: _filter, onChanged: _setFilter),
                ),
                const SliverToBoxAdapter(
                  child: SectionHeader(title: 'Top Coins'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    112,
                  ),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(indent: 64),
                    itemBuilder: (context, index) {
                      final ticker = visible[index];
                      final isFavorite = ref.watch(
                        watchlistProvider.select(
                          (ids) => ids.contains(ticker.id),
                        ),
                      );
                      return CoinListTile(
                        ticker: ticker,
                        isFavorite: isFavorite,
                        onTap: () => _openDetail(ticker),
                        onToggleFavorite: () {
                          ref
                              .read(watchlistProvider.notifier)
                              .toggle(ticker.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Ticker> _filtered(List<Ticker> tickers) {
    final copy = [...tickers];
    switch (_filter) {
      case HomeFilter.all:
        return copy..sort((a, b) => a.rank.compareTo(b.rank));
      case HomeFilter.gainers:
        return copy..sort(
          (a, b) => (b.quote.percentChange24h ?? 0).compareTo(
            a.quote.percentChange24h ?? 0,
          ),
        );
      case HomeFilter.losers:
        return copy..sort(
          (a, b) => (a.quote.percentChange24h ?? 0).compareTo(
            b.quote.percentChange24h ?? 0,
          ),
        );
    }
  }

  void _setFilter(HomeFilter filter) {
    setState(() => _filter = filter);
  }

  void _openDetail(Ticker ticker) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CoinDetailScreen(coinId: ticker.id, initialTicker: ticker),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.filter, required this.onChanged});

  final HomeFilter filter;
  final ValueChanged<HomeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<HomeFilter>(
        selected: {filter},
        onSelectionChanged: (selection) => onChanged(selection.first),
        segments: const [
          ButtonSegment(value: HomeFilter.all, label: Text('All Coins')),
          ButtonSegment(value: HomeFilter.gainers, label: Text('Gainers')),
          ButtonSegment(value: HomeFilter.losers, label: Text('Losers')),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(
            Icons.stacked_line_chart_rounded,
            size: 18,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const Text('CoinTrack'),
      ],
    );
  }
}
