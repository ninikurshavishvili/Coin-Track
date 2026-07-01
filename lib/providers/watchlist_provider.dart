import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, Set<String>>(
  (ref) {
    return WatchlistNotifier();
  },
);

class WatchlistNotifier extends StateNotifier<Set<String>> {
  WatchlistNotifier({
    Set<String> initialIds = const <String>{},
    bool loadSavedIds = true,
  }) : super(initialIds) {
    if (loadSavedIds) {
      _load();
    }
  }

  static const _key = 'cointrack_watchlist_ids';

  bool contains(String coinId) => state.contains(coinId);

  Future<void> toggle(String coinId) async {
    final next = {...state};
    if (!next.remove(coinId)) {
      next.add(coinId);
    }
    state = next;
    await _save();
  }

  Future<void> add(String coinId) async {
    state = {...state, coinId};
    await _save();
  }

  Future<void> remove(String coinId) async {
    state = {...state}..remove(coinId);
    await _save();
  }

  Future<void> clear() async {
    state = <String>{};
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList()..sort());
  }
}
