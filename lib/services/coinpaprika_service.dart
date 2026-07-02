import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/coin.dart';
import '../models/ticker.dart';

class CoinPaprikaException implements Exception {
  const CoinPaprikaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CoinPaprikaService {
  CoinPaprikaService(this._client);

  final ApiClient _client;
  final _dayFormat = DateFormat('yyyy-MM-dd');
  List<Coin>? _coinsCache;
  final _metadataCache = <String, CoinMetadata>{};

  Future<List<Ticker>> getTickers({int limit = 100}) async {
    final data = await _getList('/tickers');
    final tickers = data.map(Ticker.fromJson).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return tickers.take(limit).toList();
  }

  Future<Ticker> getTicker(String coinId) async {
    final data = await _getMap('/tickers/$coinId');
    return Ticker.fromJson(data);
  }

  Future<List<Coin>> getCoins() async {
    final cached = _coinsCache;
    if (cached != null) return cached;

    final data = await _getList('/coins');
    final coins = data.map(Coin.fromJson).where((coin) {
      return coin.isActive && coin.rank > 0;
    }).toList()..sort((a, b) => a.rank.compareTo(b.rank));
    _coinsCache = coins;
    return coins;
  }

  Future<CoinMetadata> getCoinMetadata(String coinId) async {
    final cached = _metadataCache[coinId];
    if (cached != null) return cached;

    final data = await _getMap('/coins/$coinId');
    final metadata = CoinMetadata.fromJson(data);
    _metadataCache[coinId] = metadata;
    return metadata;
  }

  Future<List<OhlcvPoint>> getHistoricalOhlcv({
    required String coinId,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _getList(
      '/coins/$coinId/ohlcv/historical',
      queryParameters: {
        'start': _dayFormat.format(start),
        'end': _dayFormat.format(end),
      },
    );
    return data.map(OhlcvPoint.fromJson).toList();
  }

  Future<OhlcvPoint?> getTodayOhlcv(String coinId) async {
    try {
      final data = await _getMap('/coins/$coinId/ohlcv/today');
      return OhlcvPoint.fromJson(data);
    } on CoinPaprikaException {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw CoinPaprikaException(_friendlyMessage(error));
    }
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException catch (error) {
      throw CoinPaprikaException(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'CoinPaprika is unreachable. Check your connection and try again.';
    }
    final code = error.response?.statusCode;
    if (code != null) {
      return 'CoinPaprika returned status $code. Please try again.';
    }
    return 'Could not load market data. Please try again.';
  }
}
