# CoinTrack

CoinTrack is a dark, mobile-first Flutter app for tracking cryptocurrency market data, exploring coin details, and saving favorite assets to a local watchlist.

The app uses CoinPaprika market data, Riverpod state management, and a custom Material 3 visual style with glassy cards, chart previews, and responsive loading/error states.

## Preview

Add your screenshots manually by replacing the image paths below.

| Home | Coin Detail | Search |
| --- | --- | --- |
| ![Home screen](docs/images/home.png) | ![Coin detail screen](docs/images/coin-detail.png) | ![Search screen](docs/images/search.png) |

| Watchlist | Profile |
| --- | --- |
| ![Watchlist screen](docs/images/watchlist.png) | ![Profile screen](docs/images/profile.png) |

## Features

- Top cryptocurrency market list with gainers and losers filters
- Coin detail screen with price, change badge, chart, market stats, and about text
- Watchlist with local persistence using `shared_preferences`
- Search with recent searches and trending coins
- CoinPaprika API integration through `dio`
- Riverpod providers for API data, search, and watchlist state
- Dark Material 3 theme with custom colors and typography
- Mock chart/data fallback when live chart data is unavailable

## Tech Stack

- Flutter
- Dart
- Riverpod
- Dio
- CoinPaprika API
- fl_chart
- cached_network_image
- shared_preferences
- intl
- google_fonts

## Project Structure

```text
lib/
  core/
    network/        API client setup
    theme/          colors, typography, app theme
    formatters.dart number/date formatting helpers
  models/           coin, ticker, OHLCV models
  providers/        Riverpod providers and notifiers
  screens/          app screens
  services/         CoinPaprika service layer
  widgets/          reusable UI components
test/
  widget_test.dart
```

## Getting Started

Install Flutter, then run:

```bash
flutter pub get
flutter run
```

Run checks:

```bash
flutter analyze
flutter test
```

Build examples:

```bash
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## API

CoinTrack uses the public CoinPaprika API:

- `GET /tickers`
- `GET /tickers/{coin_id}`
- `GET /coins`
- `GET /coins/{coin_id}`
- `GET /coins/{coin_id}/ohlcv/historical`
- `GET /coins/{coin_id}/ohlcv/today`

Base URL:

```text
https://api.coinpaprika.com/v1
```

## Known Limitations

- Portfolio and holdings are not implemented yet
- Currency switching is not implemented yet
- Theme switching is not implemented yet
- CoinPaprika free data is daily OHLCV, so true intraday charts are mocked/estimated
- Market lists do not have pagination yet
- Offline cache is limited; most market data is fetched live
- Authentication and cloud sync are not included

## Screenshots

Suggested screenshot paths:

```text
docs/images/home.png
docs/images/coin-detail.png
docs/images/search.png
docs/images/watchlist.png
docs/images/profile.png
```

Create the folder when you add images:

```bash
mkdir -p docs/images
```

## License

Add your license here.
