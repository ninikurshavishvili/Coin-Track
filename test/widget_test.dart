import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coin_track/main.dart';
import 'package:coin_track/models/coin.dart';
import 'package:coin_track/models/ticker.dart';
import 'package:coin_track/providers/search_provider.dart';
import 'package:coin_track/providers/tickers_provider.dart';
import 'package:coin_track/providers/watchlist_provider.dart';

void main() {
  testWidgets('CoinTrack app renders the shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tickersProvider.overrideWith((ref) => Stream.value(const <Ticker>[])),
          searchResultsProvider.overrideWith((ref) async => const <Coin>[]),
          recentSearchesProvider.overrideWith(
            (ref) => RecentSearchesNotifier(
              initialSearches: const <String>[],
              loadSavedSearches: false,
            ),
          ),
          watchlistProvider.overrideWith(
            (ref) => WatchlistNotifier(loadSavedIds: false),
          ),
        ],
        child: const CoinTrackApp(),
      ),
    );

    expect(find.text('CoinTrack'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
