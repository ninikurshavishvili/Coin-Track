class Coin {
  const Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.rank,
    required this.isActive,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String symbol;
  final int rank;
  final bool isActive;

  String get logoUrl => 'https://static.coinpaprika.com/coin/$id/logo.png';
}

class CoinMetadata {
  const CoinMetadata({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
    this.startedAt,
  });

  factory CoinMetadata.fromJson(Map<String, dynamic> json) {
    return CoinMetadata(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      description: json['description'] as String?,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
    );
  }

  final String id;
  final String name;
  final String symbol;
  final String? description;
  final DateTime? startedAt;
}
