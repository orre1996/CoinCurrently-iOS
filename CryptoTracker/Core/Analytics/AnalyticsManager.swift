//
//  AnalyticsManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-05-04.
//

import Foundation
#if os(iOS)
import Aptabase
#endif

protocol AnalyticsEvent {
    static var eventName: String { get }
    var parameters: [String: Any]? { get }
}

enum AptabaseConfigurator {
    nonisolated(unsafe) private static var isConfigured = false

    static func configureIfNeeded() {
#if os(iOS)
        guard !isRunningTests, !isConfigured else { return }
        isConfigured = true
        Aptabase.shared.initialize(appKey: AppSecrets.aptabaseAppKey)
        AnalyticsManager.shared.log(AppStarted())
#endif
    }
}

struct AppStarted: AnalyticsEvent {
    static let eventName = "app_started"

    var parameters: [String: Any]? { nil }
}

final class AnalyticsManager: @unchecked Sendable {
    static let shared = AnalyticsManager()

    private init() {}

    func log<E: AnalyticsEvent>(_ event: E) {
#if os(iOS)
        guard !isRunningTests else { return }
        Aptabase.shared.trackEvent(E.eventName, with: event.parameters ?? [:])
#endif
    }
}

/// Main ``TabView`` bottom-tab switches (see ``NavigationViewModel``).
struct TabSwitched: AnalyticsEvent {
    static let eventName = "tab_switched"

    let fromTab: ScreenLabel
    let toTab: ScreenLabel

    var parameters: [String: Any]? {
        [
            "from_tab": fromTab.rawValue,
            "to_tab": toTab.rawValue
        ]
    }
}

/// Inner ``PageSelectorView`` segment switches.
struct TabChanged: AnalyticsEvent {
    static let eventName = "tab_changed"

    let fromScreen: ScreenLabel
    let selectedTabName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "selected_tab": selectedTabName
        ]
    }
}

struct TimeframeChanged: AnalyticsEvent {
    static let eventName = "timeframe_changed"

    let fromScreen: ScreenLabel
    let days: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "days": days
        ]
    }
}

struct Navigate: AnalyticsEvent {
    static let eventName = "navigate"

    let fromScreen: ScreenLabel
    let toScreen: ScreenLabel
    var coinName: String? = nil
    var nftName: String? = nil
    var sectorName: String? = nil
    var exchangeName: String? = nil
    var derivativeName: String? = nil
    var treasuryName: String? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "to_screen": toScreen.rawValue
        ]
        if let coinName {
            payload["coin_name"] = coinName
        }
        if let nftName {
            payload["nft_name"] = nftName
        }
        if let sectorName {
            payload["sector_name"] = sectorName
        }
        if let exchangeName {
            payload["exchange_name"] = exchangeName
        }
        if let derivativeName {
            payload["derivative_name"] = derivativeName
        }
        if let treasuryName {
            payload["treasury_name"] = treasuryName
        }
        return payload
    }
}

struct SearchPerformed: AnalyticsEvent {
    static let eventName = "search"

    let fromScreen: ScreenLabel
    let query: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "search_term": query
        ]
    }
}

struct SearchHistoryItemAdded: AnalyticsEvent {
    static let eventName = "search_history_item_added"

    let fromScreen: ScreenLabel
    let itemName: String?
    var query: String? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "item_name": itemName ?? ""
        ]
        if let query, !query.isEmpty {
            payload["query"] = query
        }
        return payload
    }
}

struct SheetOpened: AnalyticsEvent {
    static let eventName = "sheet_opened"

    let fromScreen: ScreenLabel
    let sheet: SheetLabel

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "sheet": sheet.rawValue
        ]
        return payload
    }
}

enum CompareCoinChangeSelection: String {
    case main
    case compare
}

struct ChangeCompareCoin: AnalyticsEvent {
    static let eventName = "change_compare_coin"

    let fromScreen: ScreenLabel
    let selection: CompareCoinChangeSelection
    let coinName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "selection": selection.rawValue,
            "coin_name": coinName
        ]
    }
}

struct ChartTypeChanged: AnalyticsEvent {
    static let eventName = "chart_type_changed"

    let fromScreen: ScreenLabel
    let chartType: ChartTypes

    var parameters: [String: Any]? {
        let typeLabel: String
        switch chartType {
        case .price:
            typeLabel = "price"
        case .volume:
            typeLabel = "volume"
        case .mktCap:
            typeLabel = "market_cap"
        }
        return [
            "from_screen": fromScreen.rawValue,
            "chart_type": typeLabel
        ]
    }
}

struct ChartCandleModeChanged: AnalyticsEvent {
    static let eventName = "chart_candle_mode_changed"

    let fromScreen: ScreenLabel
    let isCandleChart: Bool

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "mode": isCandleChart ? "candlestick" : "line"
        ]
    }
}

struct ChartFiatNativeModeChanged: AnalyticsEvent {
    static let eventName = "chart_fiat_native_mode_changed"

    let fromScreen: ScreenLabel
    /// After toggle: fiat (e.g. USD) vs native NFT collection currency for the chart.
    let isChartFiat: Bool

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "mode": isChartFiat ? "fiat" : "native"
        ]
    }
}

struct WebViewOpened: AnalyticsEvent {
    static let eventName = "web_view_opened"

    let fromScreen: ScreenLabel
    let url: String

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "url": url
        ]
        return payload
    }
}

enum SourcePlatform: String {
    case ios
    case android
}

struct SourceLinkOpened: AnalyticsEvent {
    static let eventName = "source_link_opened"

    let fromScreen: ScreenLabel
    let platform: SourcePlatform

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "platform": platform.rawValue
        ]
    }
}

struct ScrollToTopPressed: AnalyticsEvent {
    static let eventName = "scroll_to_top"

    let fromScreen: ScreenLabel
    /// Detail screens: selected segment title from ``PageSelectorView`` (see ``Int`` detail-tab helpers).
    var selectedTabName: String? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "from_screen": fromScreen.rawValue
        ]
        if let selectedTabName {
            payload["selected_tab"] = selectedTabName
        }
        return payload
    }
}

struct ViewMoreExpanded: AnalyticsEvent {
    static let eventName = "view_more_expanded"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct ViewMoreCollapsed: AnalyticsEvent {
    static let eventName = "view_more_collapsed"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct PortfolioDataHide: AnalyticsEvent {
    static let eventName = "portfolio_data_hide"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct PortfolioDataShow: AnalyticsEvent {
    static let eventName = "portfolio_data_show"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct EnabledBigMoveAlerts: AnalyticsEvent {
    static let eventName = "enabled_big_move_alerts"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct DisabledBigMoveAlerts: AnalyticsEvent {
    static let eventName = "disabled_big_move_alerts"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct OpenNotificationSettingsPressed: AnalyticsEvent {
    static let eventName = "open_notification_settings_pressed"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct ClearFilters: AnalyticsEvent {
    static let eventName = "clear_filters"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct TransactionTypeFilterAdded: AnalyticsEvent {
    static let eventName = "transaction_type_filter_added"

    let fromScreen: ScreenLabel
    let transactionType: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "transaction_type": transactionType
        ]
    }
}

struct TransactionTypeFilterRemoved: AnalyticsEvent {
    static let eventName = "transaction_type_filter_removed"

    let fromScreen: ScreenLabel
    let transactionType: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "transaction_type": transactionType
        ]
    }
}

struct TransactionTypeFilterCleared: AnalyticsEvent {
    static let eventName = "transaction_type_filter_cleared"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct CoinFilterAdded: AnalyticsEvent {
    static let eventName = "coin_filter_added"

    let fromScreen: ScreenLabel
    let coinName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName
        ]
    }
}

struct CoinFilterRemoved: AnalyticsEvent {
    static let eventName = "coin_filter_removed"

    let fromScreen: ScreenLabel
    let coinName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName
        ]
    }
}

struct CoinFilterCleared: AnalyticsEvent {
    static let eventName = "coin_filter_cleared"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct WalletAddressCopied: AnalyticsEvent {
    static let eventName = "wallet_address_copied"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct WalletDeleted: AnalyticsEvent {
    static let eventName = "wallet_deleted"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct PortfolioTransactionDeleted: AnalyticsEvent {
    static let eventName = "portfolio_transaction_deleted"

    let fromScreen: ScreenLabel
    let coinName: String
    let kind: Kind

    enum Kind: String {
        case transaction
        case swap
    }

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "kind": kind.rawValue
        ]
        if !coinName.isEmpty {
            payload["coin_name"] = coinName
        }
        return payload
    }
}

struct WalletRenamed: AnalyticsEvent {
    static let eventName = "wallet_renamed"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct ResetApp: AnalyticsEvent {
    static let eventName = "reset_app"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue
        ]
        return payload
    }
}

struct ViewAll: AnalyticsEvent {
    static let eventName = "view_all"

    let fromScreen: ScreenLabel
    let filter: CarouselFilter

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "filter": filter.rawValue
        ]
        return payload
    }
}

enum PriceAlertInputType: String {
    case price
    case percent
}

struct PriceAlertAdded: AnalyticsEvent {
    static let eventName = "price_alert_added"

    let fromScreen: ScreenLabel
    let coinName: String
    let isRecurring: Bool
    let inputType: PriceAlertInputType

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName,
            "is_recurring": isRecurring,
            "input_type": inputType.rawValue
        ]
        return payload
    }
}

struct TransactionAdded: AnalyticsEvent {
    static let eventName = "transaction_added"

    let fromScreen: ScreenLabel
    let coinName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName
        ]
    }
}

struct TransactionEdited: AnalyticsEvent {
    static let eventName = "transaction_edited"

    let fromScreen: ScreenLabel
    let coinName: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName
        ]
    }
}

struct DateFilterOptionSelected: AnalyticsEvent {
    static let eventName = "date_filter_option_selected"

    let fromScreen: ScreenLabel
    let option: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "option": option
        ]
    }
}

enum DateFilterCustomField: String {
    case start
    case end
}

struct DateFilterCustomFieldOpened: AnalyticsEvent {
    static let eventName = "date_filter_custom_field_opened"

    let fromScreen: ScreenLabel
    let field: DateFilterCustomField

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "field": field.rawValue
        ]
    }
}

struct DateFilterCustomCleared: AnalyticsEvent {
    static let eventName = "date_filter_custom_cleared"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct DateFilterCustomApplied: AnalyticsEvent {
    static let eventName = "date_filter_custom_applied"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct DatePickerValueConfirmed: AnalyticsEvent {
    static let eventName = "date_picker_value_confirmed"

    let fromScreen: ScreenLabel
    let pickerKind: String

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "picker_kind": pickerKind
        ]
    }
}

struct PriceAlertDeleted: AnalyticsEvent {
    static let eventName = "price_alert_deleted"

    let fromScreen: ScreenLabel
    let coinName: String

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "coin_name": coinName
        ]
        return payload
    }
}

struct HomeFilterSelected: AnalyticsEvent {
    static let eventName = "home_filter_selected"

    let fromScreen: ScreenLabel
    let filter: CarouselFilter

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "filter": filter.rawValue
        ]
        return payload
    }
}

struct SortOptionSelected: AnalyticsEvent {
    static let eventName = "sort_option_selected"

    let fromScreen: ScreenLabel
    let option: SortOption

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "option": option.rawValue
        ]
        return payload
    }
}

struct TabBarDoubleTapped: AnalyticsEvent {
    static let eventName = "tab_bar_double_tapped"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue
        ]
        return payload
    }
}

struct PriceChangeOptionSelected: AnalyticsEvent {
    static let eventName = "price_change_option_selected"

    let fromScreen: ScreenLabel
    let option: PriceChange

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "option": option.rawValue
        ]
        return payload
    }
}

struct ThemeSelected: AnalyticsEvent {
    static let eventName = "theme_selected"

    let fromScreen: ScreenLabel
    let theme: AppColorScheme

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "theme": theme.rawValue
        ]
        return payload
    }
}

struct StartTabSelected: AnalyticsEvent {
    static let eventName = "start_tab_selected"

    let fromScreen: ScreenLabel
    let tab: StartTab

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "tab": tab.rawValue
        ]
        return payload
    }
}

struct CurrencySelected: AnalyticsEvent {
    static let eventName = "currency_selected"

    let fromScreen: ScreenLabel
    let currency: String

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "currency": currency
        ]
        return payload
    }
}

struct LanguageSelected: AnalyticsEvent {
    static let eventName = "language_selected"

    let fromScreen: ScreenLabel
    let language: String

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "language": language
        ]
        return payload
    }
}

struct DeeplinkNavigate: AnalyticsEvent {
    static let eventName = "navigate_deeplink"

    let toScreen: ScreenLabel
    var coinName: String? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "entry": "deeplink",
            "to_screen": toScreen.rawValue
        ]
        if let coinName, !coinName.isEmpty {
            payload["coin_name"] = coinName
        }
        return payload
    }
}

struct FavoriteAdded: AnalyticsEvent {
    static let eventName = "favorite_added"

    let coinName: String
    let fromScreen: ScreenLabel
    var carouselFilter: CarouselFilter? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "coin_name": coinName,
            "from_screen": fromScreen.rawValue
        ]
        if let carouselFilter {
            payload["carousel_filter"] = carouselFilter.rawValue
        }
        return payload
    }
}

struct FavoriteRemoved: AnalyticsEvent {
    static let eventName = "favorite_removed"

    let coinName: String
    let fromScreen: ScreenLabel
    var carouselFilter: CarouselFilter? = nil

    var parameters: [String: Any]? {
        var payload: [String: Any] = [
            "coin_name": coinName,
            "from_screen": fromScreen.rawValue
        ]
        if let carouselFilter {
            payload["carousel_filter"] = carouselFilter.rawValue
        }
        return payload
    }
}

struct AppShareActivityCompleted: AnalyticsEvent {
    static let eventName = "app_share_activity"

    let fromScreen: ScreenLabel
    /// `UIActivity.ActivityType.rawValue`, or `"none"` when the sheet was dismissed without a type.
    let activityType: String
    let completed: Bool

    var parameters: [String: Any]? {
        [
            "from_screen": fromScreen.rawValue,
            "share_activity_type": activityType,
            "completed": completed
        ]
    }
}

struct EnabledFaceID: AnalyticsEvent {
    static let eventName = "enabled_face_id"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue
        ]
        return payload
    }
}

struct DisabledFaceID: AnalyticsEvent {
    static let eventName = "disabled_face_id"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue
        ]
        return payload
    }
}

struct EnabledColorBlindnessFilter: AnalyticsEvent {
    static let eventName = "enabled_color_blindness_filter"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct DisabledColorBlindnessFilter: AnalyticsEvent {
    static let eventName = "disabled_color_blindness_filter"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct EnabledWebSocket: AnalyticsEvent {
    static let eventName = "enabled_web_socket"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct DisabledWebSocket: AnalyticsEvent {
    static let eventName = "disabled_web_socket"

    let fromScreen: ScreenLabel

    var parameters: [String: Any]? {
        ["from_screen": fromScreen.rawValue]
    }
}

struct FeedbackSent: AnalyticsEvent {
    static let eventName = "feedback_sent"

    let fromScreen: ScreenLabel
    let rating: Int

    var parameters: [String: Any]? {
        let payload: [String: Any] = [
            "from_screen": fromScreen.rawValue,
            "rating": rating
        ]
        return payload
    }
}

