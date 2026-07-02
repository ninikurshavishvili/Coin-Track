class Ticker {
  const Ticker({
    required this.id,
    required this.name,
    required this.symbol,
    required this.rank,
    this.totalSupply,
    this.maxSupply,
    this.circulatingSupply,
    this.firstDataAt,
    this.lastUpdated,
    required this.quote,
  });

  factory Ticker.fromJson(Map<String, dynamic> json) {
    final quotes = json['quotes'] as Map<String, dynamic>? ?? {};
    final usd = quotes['USD'] as Map<String, dynamic>? ?? {};

    return Ticker(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      totalSupply: _num(json['total_supply']),
      maxSupply: _num(json['max_supply']),
      circulatingSupply: _num(json['circulating_supply']),
      firstDataAt: DateTime.tryParse(json['first_data_at'] as String? ?? ''),
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? ''),
      quote: TickerQuote.fromJson(usd),
    );
  }

  final String id;
  final String name;
  final String symbol;
  final int rank;
  final num? totalSupply;
  final num? maxSupply;
  final num? circulatingSupply;
  final DateTime? firstDataAt;
  final DateTime? lastUpdated;
  final TickerQuote quote;

  String get logoUrl => 'https://static.coinpaprika.com/coin/$id/logo.png';
}

class TickerQuote {
  const TickerQuote({
    this.price,
    this.volume24h,
    this.marketCap,
    this.percentChange24h,
    this.percentChange7d,
    this.percentChange30d,
    this.athPrice,
    this.athDate,
  });

  factory TickerQuote.fromJson(Map<String, dynamic> json) {
    return TickerQuote(
      price: _num(json['price']),
      volume24h: _num(json['volume_24h']),
      marketCap: _num(json['market_cap']),
      percentChange24h: _num(json['percent_change_24h']),
      percentChange7d: _num(json['percent_change_7d']),
      percentChange30d: _num(json['percent_change_30d']),
      athPrice: _num(json['ath_price']),
      athDate: DateTime.tryParse(json['ath_date'] as String? ?? ''),
    );
  }

  final num? price;
  final num? volume24h;
  final num? marketCap;
  final num? percentChange24h;
  final num? percentChange7d;
  final num? percentChange30d;
  final num? athPrice;
  final DateTime? athDate;
}

class OhlcvPoint {
  const OhlcvPoint({
    required this.timeOpen,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.marketCap,
  });

  factory OhlcvPoint.fromJson(Map<String, dynamic> json) {
    return OhlcvPoint(
      timeOpen:
          DateTime.tryParse(json['time_open'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      open: _num(json['open']) ?? 0,
      high: _num(json['high']) ?? 0,
      low: _num(json['low']) ?? 0,
      close: _num(json['close']) ?? 0,
      volume: _num(json['volume']) ?? 0,
      marketCap: _num(json['market_cap']) ?? 0,
    );
  }

  final DateTime timeOpen;
  final num open;
  final num high;
  final num low;
  final num close;
  final num volume;
  final num marketCap;
}

num? _num(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
