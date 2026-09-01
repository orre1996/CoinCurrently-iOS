# CoinCurrently

iOS, Apple Watch, and widget app for following crypto markets, news, and a personal portfolio.

The iOS app lives in `CryptoTracker`. Watch and widget extensions reuse the same domain types and repositories where they need shared data.

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

## Targets

| Target | Role |
| --- | --- |
| CoinCurrently | iOS app (`CryptoTracker`) |
| CryptoWidgetExtension | Widgets |
| CoinCurrentlyWatch | watchOS app |
| CoinCurrentlyTests | Swift Testing suites, mostly repositories |

`CryptoTracker` is a synchronized Xcode group, so new files under that folder join the iOS target automatically. Watch and widget still compile shared Swift files through explicit project references.

## Local setup

1. Open `CoinCurrently.xcodeproj` in Xcode.
2. Copy `Config/Secrets.example.plist` to `Config/Secrets.plist` and fill in local values. That file is gitignored.
3. Add `Config/Secrets.plist` to the CoinCurrently, CryptoWidgetExtension, and CoinCurrentlyWatch targets if Xcode does not already include it.
4. Leave `DEVELOPMENT_TEAM` empty in the project unless you are signing locally. Do not commit a team ID or real keys.

See [LICENSE](LICENSE) for terms.
