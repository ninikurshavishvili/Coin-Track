import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/coin.dart';
import '../../models/ticker.dart';
import '../../providers/tickers_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/coin_list_tile.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({super.key, required this.coinId, this.initialTicker});

  final String coinId;
  final Ticker? initialTicker;

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  ChartRange _range = ChartRange.oneMonth;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(coinDetailProvider(widget.coinId));
    final fallbackTicker = _fallbackTicker(widget.coinId);
    final ticker =
        detailAsync.valueOrNull?.ticker ??
        widget.initialTicker ??
        fallbackTicker;
    final metadata =
        detailAsync.valueOrNull?.metadata ?? _fallbackMetadata(ticker);
    final watchlist = ref.watch(watchlistProvider);
    final isFavorite = watchlist.contains(widget.coinId);

    return Scaffold(
      body: Stack(
        children: [
          const _Atmosphere(),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(coinDetailProvider(widget.coinId));
              ref.invalidate(
                ohlcvProvider(
                  OhlcvRequest(coinId: widget.coinId, range: _range),
                ),
              );
              await ref.read(coinDetailProvider(widget.coinId).future);
            },
            child: CustomScrollView(
              slivers: [
                _DetailTopBar(
                  ticker: ticker,
                  isFavorite: isFavorite,
                  onToggleFavorite: _toggleFavorite,
                ),
                SliverToBoxAdapter(
                  child: detailAsync.when(
                    loading: () => _DetailContent(
                      ticker: ticker,
                      metadata: metadata,
                      range: _range,
                      isFavorite: isFavorite,
                      onRangeChanged: _setRange,
                      onToggleFavorite: _toggleFavorite,
                      isPreview: widget.initialTicker == null,
                    ),
                    error: (error, _) {
                      return _DetailContent(
                        ticker: ticker,
                        metadata: metadata,
                        range: _range,
                        isFavorite: isFavorite,
                        onRangeChanged: _setRange,
                        onToggleFavorite: _toggleFavorite,
                        isPreview: true,
                      );
                    },
                    data: (detail) => _DetailContent(
                      ticker: detail.ticker,
                      metadata: detail.metadata,
                      range: _range,
                      isFavorite: isFavorite,
                      onRangeChanged: _setRange,
                      onToggleFavorite: _toggleFavorite,
                      isPreview: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setRange(ChartRange range) {
    setState(() => _range = range);
  }

  void _toggleFavorite() {
    ref.read(watchlistProvider.notifier).toggle(widget.coinId);
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.ticker,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Ticker? ticker;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: _RoundIconButton(
          tooltip: 'Back',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      titleSpacing: 0,
      title: ticker == null
          ? Text(
              'Coin',
              style: AppTypography.headlineLgMobile.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
          : Row(
              children: [
                CoinAvatar(
                  logoUrl: ticker!.logoUrl,
                  symbol: ticker!.symbol,
                  size: 34,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    ticker!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineLgMobile.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: _RoundIconButton(
            tooltip: isFavorite ? 'Remove from watchlist' : 'Add to watchlist',
            icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            iconColor: isFavorite
                ? AppColors.secondary
                : AppColors.onSurfaceVariant,
            onPressed: onToggleFavorite,
          ),
        ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.ticker,
    required this.metadata,
    required this.range,
    required this.isFavorite,
    required this.onRangeChanged,
    required this.onToggleFavorite,
    required this.isPreview,
  });

  final Ticker ticker;
  final CoinMetadata? metadata;
  final ChartRange range;
  final bool isFavorite;
  final ValueChanged<ChartRange> onRangeChanged;
  final VoidCallback onToggleFavorite;
  final bool isPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = ticker.quote.percentChange24h ?? 0;
    final ohlcvAsync = ref.watch(
      ohlcvProvider(OhlcvRequest(coinId: ticker.id, range: range)),
    );
    final mockPoints = _mockChartPoints(ticker, range);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PriceHero(ticker: ticker, change: change),
          if (isPreview) ...[
            const SizedBox(height: AppSpacing.sm),
            const Center(child: _PreviewBadge()),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ChartCard(
            range: range,
            points: ohlcvAsync,
            mockPoints: mockPoints,
            fallbackPositive: change >= 0,
            onRangeChanged: onRangeChanged,
            onRetry: () => ref.invalidate(
              ohlcvProvider(OhlcvRequest(coinId: ticker.id, range: range)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatsGrid(ticker: ticker),
          const SizedBox(height: AppSpacing.lg),
          _AboutSection(ticker: ticker, metadata: metadata),
          const SizedBox(height: AppSpacing.lg),
          _WatchlistActionButton(
            isFavorite: isFavorite,
            onPressed: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.ticker, required this.change});

  final Ticker ticker;
  final num change;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppFormatters.price(ticker.quote.price),
          textAlign: TextAlign.center,
          style: AppTypography.displayLg.copyWith(
            fontSize: 44,
            height: 52 / 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChangeBadge(value: change),
      ],
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.value});

  final num value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.secondaryFixedDim : AppColors.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              AppFormatters.signedPercent(value),
              style: AppTypography.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          'Preview data while live market loads',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.range,
    required this.points,
    required this.mockPoints,
    required this.fallbackPositive,
    required this.onRangeChanged,
    required this.onRetry,
  });

  final ChartRange range;
  final AsyncValue<List<OhlcvPoint>> points;
  final List<OhlcvPoint> mockPoints;
  final bool fallbackPositive;
  final ValueChanged<ChartRange> onRangeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Price Trend',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                range.requiresIntraday ? 'Mock preview' : 'Live / preview',
                style: AppTypography.caption.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RangeChips(range: range, onChanged: onRangeChanged),
          const SizedBox(height: AppSpacing.md),
          points.when(
            loading: () => _MockChartStack(
              points: mockPoints,
              fallbackPositive: fallbackPositive,
              label: 'Estimated preview',
            ),
            error: (error, _) => _MockChartStack(
              points: mockPoints,
              fallbackPositive: fallbackPositive,
              label: 'Estimated preview',
            ),
            data: (points) {
              if (points.length < 2) {
                return _MockChartStack(
                  points: mockPoints,
                  fallbackPositive: fallbackPositive,
                  label: 'Estimated preview',
                );
              }
              return _PriceChart(
                points: points,
                fallbackPositive: fallbackPositive,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.range, required this.onChanged});

  final ChartRange range;
  final ValueChanged<ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in ChartRange.values) ...[
            Tooltip(
              message: value.requiresIntraday
                  ? 'Estimated intraday preview'
                  : value.label,
              child: _RangeChip(
                range: value,
                selected: range == value,
                enabled: true,
                onTap: () => onChanged(value),
              ),
            ),
            if (value != ChartRange.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ChartRange range;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = !enabled
        ? AppColors.onSurfaceVariant.withValues(alpha: 0.42)
        : selected
        ? AppColors.secondary
        : AppColors.onSurfaceVariant;
    final background = selected
        ? AppColors.secondary.withValues(alpha: 0.10)
        : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        key: ValueKey('range-${range.label}'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.full),
        hoverColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        splashColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 7,
          ),
          child: Text(
            range.label,
            style: AppTypography.labelSm.copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.points, required this.fallbackPositive});

  final List<OhlcvPoint> points;
  final bool fallbackPositive;

  @override
  Widget build(BuildContext context) {
    final chartPoints = points.length < 2
        ? _flatPreviewPoints(fallbackPositive)
        : points;
    final closes = chartPoints.map((point) => point.close.toDouble()).toList();
    final minY = closes.reduce((a, b) => a < b ? a : b);
    final maxY = closes.reduce((a, b) => a > b ? a : b);
    final first = closes.first;
    final last = closes.last;
    final positive = last >= first;
    final color = positive ? AppColors.secondaryFixedDim : AppColors.error;
    final percent = first == 0 ? 0 : ((last - first) / first) * 100;

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LineChartPainter(
                values: closes,
                minY: minY,
                maxY: maxY,
                color: color,
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            child: Text(
              AppFormatters.price(maxY),
              style: AppTypography.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 5,
                ),
                child: Text(
                  AppFormatters.price(last),
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 8,
            child: Text(
              AppFormatters.price(minY),
              style: AppTypography.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 8,
            child: Text(
              '${percent >= 0 ? '+' : ''}${AppFormatters.percent(percent)}',
              style: AppTypography.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  final List<double> values;
  final double minY;
  final double maxY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(0, 34, size.width, size.height - 64);
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.26)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    final range = (maxY - minY).abs() < 0.000001 ? 1 : maxY - minY;

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chartRect.left
          : chartRect.left + (chartRect.width * i / (values.length - 1));
      final normalized = (values[i] - minY) / range;
      final y = chartRect.bottom - (normalized * chartRect.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartRect.bottom);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(chartRect.right, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.34),
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0),
        ],
      ).createShader(chartRect);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.color != color;
  }
}

class _MockChartStack extends StatelessWidget {
  const _MockChartStack({
    required this.points,
    required this.fallbackPositive,
    required this.label,
  });

  final List<OhlcvPoint> points;
  final bool fallbackPositive;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _PriceChart(points: points, fallbackPositive: fallbackPositive),
        Positioned(
          top: 0,
          right: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 5,
              ),
              child: Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<OhlcvPoint> _mockChartPoints(Ticker ticker, ChartRange range) {
  final price = (ticker.quote.price ?? 1).toDouble().clamp(
    0.000001,
    double.infinity,
  );
  final change = ((ticker.quote.percentChange24h ?? 0) / 100).toDouble();
  final seed = ticker.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
  final count = switch (range) {
    ChartRange.oneHour => 24,
    ChartRange.oneDay => 24,
    ChartRange.oneWeek => 14,
    ChartRange.oneMonth => 30,
    ChartRange.oneYear => 52,
    ChartRange.all => 72,
  };
  final interval = switch (range) {
    ChartRange.oneHour => const Duration(minutes: 3),
    ChartRange.oneDay => const Duration(hours: 1),
    ChartRange.oneWeek => const Duration(hours: 12),
    ChartRange.oneMonth => const Duration(days: 1),
    ChartRange.oneYear => const Duration(days: 7),
    ChartRange.all => const Duration(days: 30),
  };
  final rangeTrend = switch (range) {
    ChartRange.oneHour => change * 0.18,
    ChartRange.oneDay => change,
    ChartRange.oneWeek => change * 1.6,
    ChartRange.oneMonth => change * 2.4,
    ChartRange.oneYear => change * 5,
    ChartRange.all => change * 8,
  };
  final volatility = switch (range) {
    ChartRange.oneHour => 0.006,
    ChartRange.oneDay => 0.014,
    ChartRange.oneWeek => 0.028,
    ChartRange.oneMonth => 0.052,
    ChartRange.oneYear => 0.10,
    ChartRange.all => 0.16,
  };
  final now = DateTime.now();
  final start = price / math.max(0.2, 1 + rangeTrend);

  return [
    for (var i = 0; i < count; i++)
      OhlcvPoint(
        timeOpen: now.subtract(interval * (count - i - 1)),
        open: _mockClose(start, price, i, count, seed + 1, volatility),
        high: _mockClose(start, price, i, count, seed + 3, volatility) * 1.01,
        low: _mockClose(start, price, i, count, seed + 7, volatility) * 0.99,
        close: _mockClose(start, price, i, count, seed, volatility),
        volume: 0,
        marketCap: 0,
      ),
  ];
}

List<OhlcvPoint> _flatPreviewPoints(bool positive) {
  final now = DateTime.now();
  final start = positive ? 100.0 : 110.0;
  final end = positive ? 112.0 : 96.0;
  return [
    for (var i = 0; i < 16; i++)
      OhlcvPoint(
        timeOpen: now.subtract(Duration(hours: 16 - i)),
        open: _mockClose(start, end, i, 16, 11, 0.02),
        high: _mockClose(start, end, i, 16, 13, 0.02) * 1.01,
        low: _mockClose(start, end, i, 16, 17, 0.02) * 0.99,
        close: _mockClose(start, end, i, 16, 19, 0.02),
        volume: 0,
        marketCap: 0,
      ),
  ];
}

double _mockClose(
  double start,
  double end,
  int index,
  int count,
  int seed,
  double volatility,
) {
  final progress = count <= 1 ? 1.0 : index / (count - 1);
  final trend = start + ((end - start) * progress);
  final waveA = math.sin((index + seed) * 0.74) * volatility;
  final waveB = math.cos((index + seed) * 0.31) * volatility * 0.55;
  return math.max(0.000001, trend * (1 + waveA + waveB));
}

Ticker _fallbackTicker(String coinId) {
  final normalized = coinId.toLowerCase();
  if (normalized.contains('btc') || normalized.contains('bitcoin')) {
    return Ticker(
      id: coinId,
      name: 'Bitcoin',
      symbol: 'BTC',
      rank: 1,
      totalSupply: 21000000,
      maxSupply: 21000000,
      circulatingSupply: 19600000,
      firstDataAt: DateTime(2010, 7, 17),
      lastUpdated: DateTime.now(),
      quote: TickerQuote(
        price: 65432.10,
        volume24h: 35000000000,
        marketCap: 1200000000000,
        percentChange24h: 3.2,
        percentChange7d: 8.1,
        percentChange30d: 14.4,
        athPrice: 73737,
        athDate: DateTime(2024, 3, 14),
      ),
    );
  }

  final parts = coinId.split('-').where((part) => part.isNotEmpty).toList();
  final symbol = (parts.isNotEmpty ? parts.first : 'COIN').toUpperCase();
  final name = parts.length > 1
      ? parts.skip(1).map(_titleCase).join(' ')
      : _titleCase(symbol);
  final seed = coinId.codeUnits.fold<int>(0, (sum, code) => sum + code);
  final price = 2 + (seed % 9000) / 7;
  final change = ((seed % 1200) / 100) - 4;

  return Ticker(
    id: coinId,
    name: name,
    symbol: symbol,
    rank: (seed % 500) + 1,
    totalSupply: 100000000 + seed * 10000,
    circulatingSupply: 72000000 + seed * 7000,
    firstDataAt: DateTime(2018, 1, 1),
    lastUpdated: DateTime.now(),
    quote: TickerQuote(
      price: price,
      volume24h: price * 12000000,
      marketCap: price * (72000000 + seed * 7000),
      percentChange24h: change,
      percentChange7d: change * 1.8,
      percentChange30d: change * 3.1,
      athPrice: price * 1.72,
      athDate: DateTime(2024, 3, 14),
    ),
  );
}

CoinMetadata _fallbackMetadata(Ticker ticker) {
  final isBitcoin =
      ticker.id.toLowerCase().contains('btc') ||
      ticker.name.toLowerCase().contains('bitcoin');

  return CoinMetadata(
    id: ticker.id,
    name: ticker.name,
    symbol: ticker.symbol,
    description: isBitcoin
        ? 'Bitcoin is a decentralized digital currency that can be sent peer-to-peer without a central bank or single administrator. Live CoinPaprika data will replace this preview when available.'
        : '${ticker.name} market details are shown with a generated preview until live CoinPaprika data is available. Price, chart, and market stats update automatically when the API responds.',
    startedAt: ticker.firstDataAt,
  );
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final lower = value.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.ticker});

  final Ticker ticker;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.52,
      children: [
        _DetailStatCard(
          label: 'Market Cap',
          value: AppFormatters.compactCurrency(ticker.quote.marketCap),
        ),
        _DetailStatCard(
          label: '24h Volume',
          value: AppFormatters.compactCurrency(ticker.quote.volume24h),
        ),
        _DetailStatCard(
          label: 'Supply',
          value: AppFormatters.compact(
            ticker.circulatingSupply ?? ticker.totalSupply,
          ),
          subtitle: ticker.symbol.toUpperCase(),
        ),
        _DetailStatCard(
          label: 'All-Time High',
          value: AppFormatters.price(ticker.quote.athPrice),
          subtitle: AppFormatters.date(ticker.quote.athDate),
        ),
      ],
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.priceXl.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 23,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.ticker, required this.metadata});

  final Ticker ticker;
  final CoinMetadata? metadata;

  @override
  Widget build(BuildContext context) {
    final description = metadata?.description?.trim();
    final body = description == null || description.isEmpty
        ? 'No description available.'
        : description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${ticker.name}',
          style: AppTypography.headlineLgMobile.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _WatchlistActionButton extends StatefulWidget {
  const _WatchlistActionButton({
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  State<_WatchlistActionButton> createState() => _WatchlistActionButtonState();
}

class _WatchlistActionButtonState extends State<_WatchlistActionButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.isFavorite;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          decoration: BoxDecoration(
            color: isFavorite ? AppColors.secondaryContainer : null,
            gradient: isFavorite
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryContainer,
                      AppColors.secondaryContainer,
                    ],
                  ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color:
                    (isFavorite
                            ? AppColors.secondaryContainer
                            : AppColors.primaryContainer)
                        .withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFavorite
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_rounded,
                color: isFavorite
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isFavorite ? 'Added to Watchlist' : 'Add to Watchlist',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: isFavorite
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer.withValues(alpha: 0.68),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? AppColors.onSurface),
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: _Glow(
            color: AppColors.primaryContainer.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: 260,
          left: -110,
          child: _Glow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
