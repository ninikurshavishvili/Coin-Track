import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/coin.dart';
import '../models/ticker.dart';
import '../services/coinpaprika_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final coinPaprikaServiceProvider = Provider<CoinPaprikaService>((ref) {
  return CoinPaprikaService(ref.watch(apiClientProvider));
});

final tickersProvider = StreamProvider<List<Ticker>>((ref) async* {
  final service = ref.watch(coinPaprikaServiceProvider);

  while (true) {
    yield await service.getTickers(limit: 100);
    await Future<void>.delayed(const Duration(seconds: 45));
  }
});

final tickerMapProvider = Provider<AsyncValue<Map<String, Ticker>>>((ref) {
  return ref.watch(tickersProvider).whenData((tickers) {
    return {for (final ticker in tickers) ticker.id: ticker};
  });
});

final tickerProvider = FutureProvider.family<Ticker, String>((ref, coinId) {
  return ref.watch(coinPaprikaServiceProvider).getTicker(coinId);
});

final coinMetadataProvider =
    FutureProvider.family<CoinMetadata, String>((ref, coinId) {
  return ref.watch(coinPaprikaServiceProvider).getCoinMetadata(coinId);
});

enum ChartRange {
  oneDay('1D', 1),
  sevenDays('7D', 7),
  thirtyDays('30D', 30),
  ninetyDays('90D', 90),
  oneYear('1Y', 365);

  const ChartRange(this.label, this.days);

  final String label;
  final int days;
}

class OhlcvRequest {
  const OhlcvRequest({
    required this.coinId,
    required this.range,
  });

  final String coinId;
  final ChartRange range;

  @override
  bool operator ==(Object other) {
    return other is OhlcvRequest &&
        other.coinId == coinId &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(coinId, range);
}

final ohlcvProvider =
    FutureProvider.family<List<OhlcvPoint>, OhlcvRequest>((ref, request) async {
  final service = ref.watch(coinPaprikaServiceProvider);
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);

  if (request.range == ChartRange.oneDay) {
    final today = await service.getTodayOhlcv(request.coinId);
    if (today != null) return [today];
  }

  final history = await service.getHistoricalOhlcv(
    coinId: request.coinId,
    start: end.subtract(Duration(days: request.range.days)),
    end: end,
  );

  if (request.range == ChartRange.oneDay && history.isNotEmpty) {
    final today = await service.getTodayOhlcv(request.coinId);
    if (today != null) return [...history, today];
  }

  return history;
});
