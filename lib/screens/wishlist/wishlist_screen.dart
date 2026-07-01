import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ticker.dart';
import '../../providers/tickers_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/coin_list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/states.dart';
import '../coin_detail/coin_detail_screen.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(watchlistProvider);
    final tickersAsync = ref.watch(tickersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: ids.isEmpty
          ? EmptyState(
              icon: Icons.star_outline_rounded,
              message: 'No coins yet - tap the star on any coin to add it here',
              actionLabel: 'Find Coins',
              onAction: onExplore,
            )
          : tickersAsync.when(
              loading: () => const LoadingList(count: 5),
              error: (error, _) => ErrorState(
                message: 'Could not refresh your watchlist.',
                onRetry: () => ref.invalidate(tickersProvider),
              ),
              data: (tickers) {
                final saved =
                    tickers.where((ticker) => ids.contains(ticker.id)).toList()
                      ..sort((a, b) => a.rank.compareTo(b.rank));

                if (saved.isEmpty) {
                  return EmptyState(
                    icon: Icons.sync_problem_rounded,
                    message: 'Saved coins are not in the current market feed.',
                    actionLabel: 'Refresh',
                    onAction: () => ref.invalidate(tickersProvider),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tickersProvider);
                    await ref.read(tickersProvider.future);
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _SummaryCard(tickers: saved)),
                      const SliverToBoxAdapter(
                        child: SectionHeader(title: 'Saved Coins'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          112,
                        ),
                        sliver: SliverList.separated(
                          itemCount: saved.length,
                          separatorBuilder: (_, _) => const Divider(indent: 64),
                          itemBuilder: (context, index) {
                            final ticker = saved[index];
                            return Dismissible(
                              key: ValueKey(ticker.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.lg,
                                ),
                                color: AppColors.errorContainer,
                                child: const Icon(Icons.delete_rounded),
                              ),
                              onDismissed: (_) {
                                ref
                                    .read(watchlistProvider.notifier)
                                    .remove(ticker.id);
                              },
                              child: CoinListTile(
                                ticker: ticker,
                                isFavorite: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CoinDetailScreen(
                                      coinId: ticker.id,
                                      initialTicker: ticker,
                                    ),
                                  ),
                                ),
                                onToggleFavorite: () {
                                  ref
                                      .read(watchlistProvider.notifier)
                                      .remove(ticker.id);
                                },
                              ),
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.tickers});

  final List<Ticker> tickers;

  @override
  Widget build(BuildContext context) {
    final average =
        tickers.fold<num>(
          0,
          (sum, ticker) => sum + (ticker.quote.percentChange24h ?? 0),
        ) /
        tickers.length;
    final mockValue = tickers.fold<num>(
      0,
      (sum, ticker) => sum + ((ticker.quote.price ?? 0) * 0.05),
    );
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mock portfolio',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatters.price(mockValue),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          ChangePill(value: average),
        ],
      ),
    );
  }
}
