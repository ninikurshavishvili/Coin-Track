import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme/app_colors.dart';
import '../models/coin.dart';
import '../models/ticker.dart';
import 'sparkline_chart.dart';

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({
    super.key,
    required this.logoUrl,
    required this.symbol,
    this.size = 44,
  });

  final String logoUrl;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _FallbackAvatar(symbol: symbol, size: size),
        placeholder: (_, _) => _FallbackAvatar(symbol: symbol, size: size),
      ),
    );
  }
}

class CoinListTile extends StatelessWidget {
  const CoinListTile({
    super.key,
    required this.ticker,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.showSparkline = true,
  });

  final Ticker ticker;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool showSparkline;

  @override
  Widget build(BuildContext context) {
    final change = ticker.quote.percentChange24h ?? 0;
    final positive = change >= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CoinAvatar(logoUrl: ticker.logoUrl, symbol: ticker.symbol),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            ),
            if (showSparkline) ...[
              SizedBox(
                width: 68,
                child: SparklineChart(
                  values: _syntheticSparkline(ticker),
                  isPositive: positive,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.price(ticker.quote.price),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ChangePill(value: change),
              ],
            ),
            IconButton(
              tooltip: isFavorite
                  ? 'Remove from watchlist'
                  : 'Add to watchlist',
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<num> _syntheticSparkline(Ticker ticker) {
    final price = ticker.quote.price ?? 0;
    if (price <= 0) return const [];
    final change = (ticker.quote.percentChange24h ?? 0) / 100;
    final start = price / (1 + change);
    return [
      start,
      (start * 0.995 + price * 0.005),
      (start * 0.85 + price * 0.15),
      (start * 0.68 + price * 0.32),
      (start * 0.55 + price * 0.45),
      (start * 0.34 + price * 0.66),
      (start * 0.18 + price * 0.82),
      price,
    ];
  }
}

class SearchCoinRow extends StatelessWidget {
  const SearchCoinRow({
    super.key,
    required this.coin,
    required this.ticker,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Coin coin;
  final Ticker? ticker;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final change = ticker?.quote.percentChange24h;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CoinAvatar(logoUrl: coin.logoUrl, symbol: coin.symbol),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    coin.symbol.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.price(ticker?.quote.price),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (change != null) ChangePill(value: change),
              ],
            ),
            IconButton(
              tooltip: isFavorite
                  ? 'Remove from watchlist'
                  : 'Add to watchlist',
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.value});

  final num value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppColors.secondaryFixedDim : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        AppFormatters.signedPercent(value),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.symbol, required this.size});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = symbol.isEmpty
        ? '?'
        : symbol.characters.take(3).toString().toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHighest,
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
