import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coin.dart';
import 'tickers_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final coinsProvider = FutureProvider<List<Coin>>((ref) {
  return ref.watch(coinPaprikaServiceProvider).getCoins();
});

final searchResultsProvider = FutureProvider<List<Coin>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  await Future<void>.delayed(const Duration(milliseconds: 200));

  final coins = await ref.watch(coinsProvider.future);
  if (query.isEmpty) {
    return coins.take(40).toList();
  }

  return coins
      .where((coin) {
        final name = coin.name.toLowerCase();
        final symbol = coin.symbol.toLowerCase();
        return name.contains(query) || symbol.contains(query);
      })
      .take(60)
      .toList();
});

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
      return RecentSearchesNotifier();
    });

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier({
    List<String> initialSearches = const ['BTC', 'ETH', 'SOL', 'PEPE'],
    bool loadSavedSearches = true,
  }) : super(initialSearches) {
    if (loadSavedSearches) {
      _load();
    }
  }

  static const _key = 'cointrack_recent_searches';

  Future<void> add(String value) async {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return;

    state = [
      normalized,
      ...state.where((item) => item != normalized),
    ].take(5).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored != null && stored.isNotEmpty) {
      state = stored.take(5).toList();
    }
  }
}
