import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/coin.dart';
import '../../models/ticker.dart';
import '../../providers/search_provider.dart';
import '../../providers/tickers_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/coin_list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/states.dart';
import '../coin_detail/coin_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final resultsAsync = ref.watch(searchResultsProvider);
    final tickerMapAsync = ref.watch(tickerMapProvider);
    final tickers = tickerMapAsync.valueOrNull ?? const <String, Ticker>{};
    final trending =
        (ref.watch(tickersProvider).valueOrNull ?? const <Ticker>[]).toList()
          ..sort(
            (a, b) => (b.quote.percentChange24h ?? 0).compareTo(
              a.quote.percentChange24h ?? 0,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const _SearchTitle(),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SearchBox(controller: _controller)),
          SliverToBoxAdapter(child: _RecentChips(controller: _controller)),
          SliverToBoxAdapter(
            child: _TrendingStrip(tickers: trending.take(10).toList()),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Market Results'),
          ),
          resultsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    SkeletonBox(),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(),
                  ],
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(
                message: 'Search data is unavailable.',
                onRetry: () => ref.invalidate(coinsProvider),
              ),
            ),
            data: (coins) {
              if (coins.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    message: 'No matching coins found.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  112,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ResultsContainer(
                    coins: coins,
                    tickers: tickers,
                    onOpen: _openCoin,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openCoin(Coin coin, Ticker? ticker) {
    ref.read(recentSearchesProvider.notifier).add(coin.symbol);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CoinDetailScreen(coinId: coin.id, initialTicker: ticker),
      ),
    );
  }
}

class _SearchBox extends ConsumerWidget {
  const _SearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        onSubmitted: (value) {
          ref.read(recentSearchesProvider.notifier).add(value);
        },
        decoration: const InputDecoration(
          hintText: 'Search coins',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _RecentChips extends ConsumerWidget {
  const _RecentChips({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final value = recent[index];
          return ActionChip(
            label: Text(value),
            onPressed: () {
              controller.text = value;
              ref.read(searchQueryProvider.notifier).state = value;
              ref.read(recentSearchesProvider.notifier).add(value);
            },
          );
        },
      ),
    );
  }
}

class _TrendingStrip extends StatelessWidget {
  const _TrendingStrip({required this.tickers});

  final List<Ticker> tickers;

  @override
  Widget build(BuildContext context) {
    if (tickers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending Now'),
        SizedBox(
          height: 118,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: tickers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final ticker = tickers[index];
              return Container(
                width: 188,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CoinAvatar(
                          logoUrl: ticker.logoUrl,
                          symbol: ticker.symbol,
                          size: 34,
                        ),
                        const Spacer(),
                        ChangePill(value: ticker.quote.percentChange24h ?? 0),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      ticker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ticker.symbol.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultsContainer extends ConsumerWidget {
  const _ResultsContainer({
    required this.coins,
    required this.tickers,
    required this.onOpen,
  });

  final List<Coin> coins;
  final Map<String, Ticker> tickers;
  final void Function(Coin coin, Ticker? ticker) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: coins.length,
        separatorBuilder: (_, _) => const Divider(indent: 72),
        itemBuilder: (context, index) {
          final coin = coins[index];
          final ticker = tickers[coin.id];
          return SearchCoinRow(
            coin: coin,
            ticker: ticker,
            isFavorite: watchlist.contains(coin.id),
            onTap: () => onOpen(coin, ticker),
            onToggleFavorite: () {
              ref.read(watchlistProvider.notifier).toggle(coin.id);
            },
          );
        },
      ),
    );
  }
}

class _SearchTitle extends StatelessWidget {
  const _SearchTitle();

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
