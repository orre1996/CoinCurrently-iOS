<p align="center">
  <img src="docs/banner.jpg" alt="CoinCurrently — Privacy by Default" width="100%">
</p>

<p align="center">
  A private crypto tracker for iOS, Apple Watch, and Android.<br>
  Follow markets, news, and a personal portfolio without an account, ads, or sign-up.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/coincurrently/id1543974454"><img src="docs/app-store-badge.svg" alt="Download on the App Store" height="40"></a>
  &nbsp;&nbsp;&nbsp;
  <a href="https://play.google.com/store/apps/details?id=com.cryptium.coincurrently"><img src="docs/google-play-badge.png" alt="Get it on Google Play" height="40"></a>
  <br>
  <a href="https://github.com/orre1996/CoinCurrentlyAndroid">Android repo</a>
  &nbsp;·&nbsp;
  <a href="https://coincurrently.app">coincurrently.app</a>
</p>

<p align="center">
  <img src="docs/preview.png" alt="CoinCurrently on iPhone: markets, a coin chart, and portfolio" width="820">
</p>

The iOS app lives in `CryptoTracker`. Watch and widget extensions reuse the same domain types and repositories where they need shared data.

## What it does

- Markets — coins, NFTs, exchanges, derivatives, and categories
- Personal portfolio
- Price alerts
- News (articles, videos, and podcasts)
- Home Screen and Lock Screen widgets
- Apple Watch

## Why this is open source

CoinCurrently is focused on privacy. The source is public so anyone can see what the app does with their data. The license is source-available, not OSI open source — see [License](#license).

## Privacy

CoinCurrently does not ask for an email or password. Portfolio holdings, transactions, and settings stay on the device.

The app uses a few third-party SDKs. None of them require a name, email, or phone number, so there is still no personal account.

- **[Aptabase](https://aptabase.com)** is a privacy-focused analytics service. The app sends named product events (for example which screen opened). It is not an advertising SDK and does not build a marketing profile.
- **[RevenueCat](https://www.revenuecat.com)** manages App Store subscriptions. Pro status comes from the store receipt through RevenueCat, not from Firebase.
- **[Firebase](https://firebase.google.com)** signs in anonymously — a random ID on the device, not an email. Price alerts need that so Firebase Cloud Messaging can issue an FCM token. The backend uses the token to send a push when a price hits; without it, the phone cannot receive alert notifications.

See the [Privacy Policy](https://coincurrently.app/privacy).

## Architecture

The app uses **MVVM + repositories**.

- A **repository** is the source of truth for a slice of data (news, toplist, portfolio, and so on). It fetches from the network, caches, and persists. Screens do not talk to the API directly.
- A **view model** reads from one or more repositories, then shapes that data for a specific screen: filtering, sorting, hover state, loading flags, and user actions.
- A **view** (SwiftUI screen) renders the view model and sends user events back. It should not own cache or networking.

```
View  →  ViewModel  →  Repository  →  NetworkManager / Settings / Core Data
              ↑               │
              └──── cached / mapped data
```

### Repositories

Repositories are Swift `actor`s, usually behind a protocol plus an `*Imp` implementation (`NewsRepository` / `NewsRepositoryImp`). Production code uses a shared instance; tests inject a mock `NetworkManager`.

A repository is responsible for:

- Loading and refreshing a domain (for example `getNews(type:count:)`)
- Holding the cached copy of that data
- Writing user or session state that belongs to that domain (selected news category, saved coins)
- Talking to `NetworkManager`, `SettingsManager`, and Core Data — not to SwiftUI

Several screens can share the same repository. Home, Market, and Coin Detail all read coin prices from the same source instead of each keeping their own list.

### View models

View models are `@MainActor` and typically `@Observable`. They:

- Ask repositories for data
- Keep screen-only state (selected tab, hover point, empty/loading)
- Map repository models into what the view needs (a short home carousel vs a full market list, filtered news, formatted P&L)
- Handle user actions, then write back through the repository when the change should be shared

They do not persist the app-wide cache. If Home and News both show news, the repository cache is what they share; each view model only keeps the slice its screen displays.

### Views

SwiftUI screens own a view model (`@State private var viewModel = NewsViewModelImp()`), observe it, and call `async` methods from `Task`s. Shared chrome (charts, list rows, sheets) lives in `SharedUI` so features stay focused on their own flow.

### Example: News

1. `NewsRepository` fetches and caches `[NewsItem]` per `NewsType`.
2. `NewsViewModel` loads that cache, then filters it for Articles / Videos / Podcasts and the selected category.
3. `NewsScreen` binds to those arrays and asks the view model to refresh when the user changes tab or filter.

## File structure

```
CryptoTracker/
  App/                 Entry point, tabs, navigation, Siri, deeplinks
  Core/                Shared infrastructure (not feature UI)
    Analytics/
    Config/            AppSecrets reader (values stay in gitignored Secrets.plist)
    Domain/            Shared models (Toplist, CurrencyDataModel, …)
    Networking/        Endpoint, NetworkManager
    Persistence/       Core Data, local storage
    Purchases/
    Settings/
    Utilities/
  SharedUI/            Reusable views, charts, modifiers, sheets
  Features/            One folder per product area
    Home/
    Market/            Toplist, Heatmap, NFTs, Exchanges, Derivatives, Categories
    CoinDetail/
    Portfolio/
    News/
    …

CoinCurrentlyTests/    Mirrors Core/ and Features/
CryptoWidget/          Home Screen and Lock Screen widgets
CoinCurrentlyWatch Extension/
```

A typical feature looks like:

```
Features/News/
  Screens/             NewsScreen
  ViewModels/          NewsViewModel
  Repositories/        NewsRepository
  Models/
  Views/
  Sheets/
```

Smaller features may keep a few files at the feature root. Shared types used by many features belong in `Core/Domain` or `SharedUI`, not in the first feature that happened to need them.

## Networking

Market data, news, and the fear and greed index each come from a different API. `NetworkManager` and `Endpoint` in `Core/Networking` own the requests; screens never call these APIs directly.

### CoinGecko

Crypto market data is based on [CoinGecko's API](https://www.coingecko.com/en/api). Without Pro, coin detail, OHLC, and market charts call the public API directly at `https://api.coingecko.com/api/v3` (`/coins/{id}`, `/coins/{id}/ohlc`, and `/coins/{id}/market_chart`). Those three calls do not use `API_BASE_URL`.

Every other market route is `{API_BASE_URL}/crypto/api/v3/...`. `API_BASE_URL` is your own backend. CoinGecko's public host does not serve the `/crypto` prefix, so `https://api.coingecko.com` cannot be used as `API_BASE_URL`.

Most of the proxied endpoints work on the free or Basic plans. These require the [Analyst plan](https://www.coingecko.com/en/api/pricing) (or higher):

- `/coins/list/new` — recently listed coins
- `/coins/top_gainers_losers` — top gainers and losers
- `/global/market_cap_chart` — historical global market cap and volume
- `/nfts/markets` — NFT collection market data
- `/nfts/{id}/market_chart` — NFT floor price, market cap, and volume history
- `/nfts/{id}/tickers` — NFT floor price and volume per marketplace
- CGSimplePrice WebSocket — live coin prices

### News

News (articles, videos, and podcasts) is based on [cryptonews-api.com](https://cryptonews-api.com). The app requests it as `{API_BASE_URL}/news`. The news key stays on the backend.

### Fear and Greed

The fear and greed index is requested directly from [alternative.me](https://alternative.me/crypto/fear-and-greed-index/). It does not use `API_BASE_URL`.

### CoinCurrently backend

The backend is not in this repo. It proxies CoinGecko and news so third-party keys stay off the client, and it hosts first-party routes for price alerts, big-mover notifications, wallet import, gas fees, referrals, redeem codes, user, and feedback. Those first-party routes send a bearer token.

Without that backend, the app can still show coin detail, OHLC, market charts (for users without Pro), and the fear and greed index. Toplists, search, trending, exchanges, categories, derivatives, news, NFTs, gainers and losers, gas fees, and alerts need `API_BASE_URL`.

## Pro

Subscriptions go through RevenueCat and StoreKit. Free users get markets, news, a small portfolio, and widgets. Pro unlocks live prices (WebSocket), extra price alerts, more portfolio transactions, wallet import, portfolio export, and some news filters (coin, exchange, NFT, technical analysis).

## Targets

| Target | Role |
| --- | --- |
| CoinCurrently | iOS app (`CryptoTracker`) |
| CryptoWidgetExtension | Widgets |
| CoinCurrentlyWatch | watchOS app |
| CoinCurrentlyTests | Swift Testing suites, mostly repositories |

`CryptoTracker` is a synchronized Xcode group, so new files under that folder join the iOS target automatically. Watch and widget still compile shared Swift files through explicit project references.

## Requirements

- iOS 18 and watchOS 10
- Xcode 16 or later

## Local setup

1. Open `CoinCurrently.xcodeproj` and run the **CoinCurrently** scheme. Set your own Development Team in Signing so Xcode can install the app. Leave `DEVELOPMENT_TEAM` empty in committed project files. Do not commit a team ID or real keys.
2. Copy `Config/Secrets.example.plist` to `Config/Secrets.plist`. The app crashes at launch if this file is missing from the bundle or if any key is empty. Placeholder values are enough to launch. The file is gitignored. Keys:
   - `API_BASE_URL` — your backend. Markets, news, and the first-party routes above need it. A placeholder lets the app launch; those screens fail until it points at a backend.
   - `BACKEND_API_KEY` — sent as `x-coin-currently-key`. A placeholder is enough for the public CoinGecko and fear-and-greed calls.
   - `REVENUECAT_PRODUCTION_API_KEY` and `REVENUECAT_TEST_API_KEY` — placeholders are enough unless you are testing purchases. Debug builds use the test key.
   - `APTABASE_APP_KEY` — a placeholder is enough unless you want analytics.
3. `Secrets.plist` is already referenced by the CoinCurrently, CryptoWidgetExtension, and CoinCurrentlyWatch targets. Widgets and Watch read the same file. If Xcode does not copy it into the bundle, add it to those targets' Copy Bundle Resources.
4. Copy `Config/GoogleService-Info.example.plist` to `GoogleService-Info.plist` in `CryptoTracker` and `CryptoWidget`. The iOS app configures Firebase at launch, so the file has to be in that bundle or the app will not start. The example placeholders are enough to launch. Replace them with a real Firebase project only for anonymous sign-in and price-alert push. Those files are gitignored. The watch app does not use Firebase.

## Tests

`CoinCurrentlyTests` uses Swift Testing. Suites mostly cover repositories and inject a mock `NetworkManager`. Run the **CoinCurrentlyTests** scheme in Xcode.

## Contributing

Pull requests are welcome. Match the existing MVVM + repository layout. Do not commit secrets, signing material, a team ID, or a live Firebase config. Keep `DEVELOPMENT_TEAM` empty in the project file.

## License

This repository is source-available under the [CoinCurrently Source-Available License](LICENSE). You may view, study, and use it for personal and educational purposes, and contributions are welcome. You may not republish it, ship a public fork, or publish a derived app to an app store.
