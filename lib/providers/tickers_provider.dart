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

final coinMetadataProvider = FutureProvider.family<CoinMetadata, String>((
  ref,
  coinId,
) {
  return ref.watch(coinPaprikaServiceProvider).getCoinMetadata(coinId);
});

class CoinDetailData {
  const CoinDetailData({required this.ticker, required this.metadata});

  final Ticker ticker;
  final CoinMetadata metadata;
}

final coinDetailProvider = FutureProvider.family<CoinDetailData, String>((
  ref,
  coinId,
) async {
  final service = ref.watch(coinPaprikaServiceProvider);
  final results = await Future.wait<Object>([
    service.getTicker(coinId),
    service.getCoinMetadata(coinId),
  ]);

  return CoinDetailData(
    ticker: results[0] as Ticker,
    metadata: results[1] as CoinMetadata,
  );
});

enum ChartRange {
  oneHour('1H', null, true),
  oneDay('1D', 1, false),
  oneWeek('1W', 7, false),
  oneMonth('1M', 30, false),
  oneYear('1Y', 365, false),
  all('ALL', null, false);

  const ChartRange(this.label, this.days, this.requiresIntraday);

  final String label;
  final int? days;
  final bool requiresIntraday;
}

class OhlcvRequest {
  const OhlcvRequest({required this.coinId, required this.range});

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

final ohlcvProvider = FutureProvider.family<List<OhlcvPoint>, OhlcvRequest>((
  ref,
  request,
) async {
  final service = ref.watch(coinPaprikaServiceProvider);
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);

  if (request.range.requiresIntraday) {
    return const <OhlcvPoint>[];
  }

  if (request.range == ChartRange.oneDay) {
    final start = end.subtract(const Duration(days: 1));
    final history = await service.getHistoricalOhlcv(
      coinId: request.coinId,
      start: start,
      end: end,
    );
    final today = await service.getTodayOhlcv(request.coinId);
    if (today != null) return [...history, today];
    return history;
  }

  final days = request.range.days;
  final start = days == null
      ? ((await ref.watch(tickerProvider(request.coinId).future)).firstDataAt ??
            end.subtract(const Duration(days: 3650)))
      : end.subtract(Duration(days: days));
  final history = await service.getHistoricalOhlcv(
    coinId: request.coinId,
    start: start,
    end: end,
  );

  return history;
});
