import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ticker.dart';
import '../../providers/tickers_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/coin_list_tile.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/states.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({super.key, required this.coinId, this.initialTicker});

  final String coinId;
  final Ticker? initialTicker;

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  ChartRange _range = ChartRange.thirtyDays;

  @override
  Widget build(BuildContext context) {
    final tickerAsync = ref.watch(tickerProvider(widget.coinId));
    final ticker = tickerAsync.valueOrNull ?? widget.initialTicker;
    final watchlist = ref.watch(watchlistProvider);
    final isFavorite = watchlist.contains(widget.coinId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: ticker == null
            ? const Text('Coin')
            : Row(
                children: [
                  CoinAvatar(
                    logoUrl: ticker.logoUrl,
                    symbol: ticker.symbol,
                    size: 30,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${ticker.name} ${ticker.symbol.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove from watchlist' : 'Add to watchlist',
            onPressed: () {
              ref.read(watchlistProvider.notifier).toggle(widget.coinId);
            },
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: tickerAsync.when(
        loading: () =>
            ticker == null ? const _DetailSkeleton() : _content(ticker),
        error: (error, _) {
          if (ticker != null) return _content(ticker);
          return ErrorState(
            message: 'Could not load this coin.',
            onRetry: () => ref.invalidate(tickerProvider(widget.coinId)),
          );
        },
        data: _content,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: FilledButton.icon(
            onPressed: () {
              ref.read(watchlistProvider.notifier).toggle(widget.coinId);
            },
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            ),
            label: Text(
              isFavorite ? 'Remove from Watchlist' : 'Add to Watchlist',
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(Ticker ticker) {
    final change = ticker.quote.percentChange24h ?? 0;
    final ohlcvAsync = ref.watch(
      ohlcvProvider(OhlcvRequest(coinId: widget.coinId, range: _range)),
    );
    final metadataAsync = ref.watch(coinMetadataProvider(widget.coinId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tickerProvider(widget.coinId));
        ref.invalidate(
          ohlcvProvider(OhlcvRequest(coinId: widget.coinId, range: _range)),
        );
        await ref.read(tickerProvider(widget.coinId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          112,
        ),
        children: [
          Text(
            AppFormatters.price(ticker.quote.price),
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 38, height: 46 / 38),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: ChangePill(value: change),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RangeSelector(
            range: _range,
            onChanged: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: AppSpacing.md),
          ohlcvAsync.when(
            loading: () => const SkeletonBox(height: 260),
            error: (error, _) => SizedBox(
              height: 260,
              child: ErrorState(
                message: 'Could not load chart history.',
                onRetry: () => ref.invalidate(
                  ohlcvProvider(
                    OhlcvRequest(coinId: widget.coinId, range: _range),
                  ),
                ),
              ),
            ),
            data: (points) =>
                _PriceChart(points: points, fallbackPositive: change >= 0),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              StatCard(
                label: 'Market Cap',
                value: AppFormatters.compactCurrency(ticker.quote.marketCap),
              ),
              StatCard(
                label: '24h Volume',
                value: AppFormatters.compactCurrency(ticker.quote.volume24h),
              ),
              StatCard(
                label: 'Circulating',
                value: AppFormatters.compact(ticker.circulatingSupply),
                subtitle: ticker.symbol.toUpperCase(),
              ),
              StatCard(
                label: 'All-Time High',
                value: AppFormatters.price(ticker.quote.athPrice),
                subtitle: AppFormatters.date(ticker.quote.athDate),
              ),
            ],
          ),
          metadataAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: SkeletonBox(height: 96),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (metadata) {
              final description = metadata.description?.trim();
              if (description == null || description.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(
                  description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onChanged});

  final ChartRange range;
  final ValueChanged<ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final value in ChartRange.values)
          ChoiceChip(
            label: Text(value.label),
            selected: range == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.points, required this.fallbackPositive});

  final List<OhlcvPoint> points;
  final bool fallbackPositive;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return Container(
        height: 260,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: SparklineChart(
          values: points.map((point) => point.close).toList(),
          isPositive: fallbackPositive,
          height: 180,
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].close.toDouble()),
    ];
    final closes = points.map((point) => point.close.toDouble()).toList();
    final minY = closes.reduce((a, b) => a < b ? a : b);
    final maxY = closes.reduce((a, b) => a > b ? a : b);
    final positive = closes.last >= closes.first;
    final color = positive ? AppColors.secondaryFixedDim : AppColors.error;
    final padding = (maxY - minY).abs() * 0.08;

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.length - 1,
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (items) {
                return items.map((item) {
                  final point = points[item.x.toInt()];
                  return LineTooltipItem(
                    AppFormatters.price(point.close),
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(color: AppColors.onSurface),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.32),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 46, width: 180),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 24, width: 84, borderRadius: AppRadius.full),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 260),
          SizedBox(height: AppSpacing.lg),
          Expanded(child: LoadingList(count: 3)),
        ],
      ),
    );
  }
}
