//
//  Endpoint.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-09.
//

import Foundation

// Market routes are "{API_BASE_URL}/crypto/api/v3/...". API_BASE_URL is your backend.
// Coin detail, OHLC, and market charts for users without Pro call
// https://api.coingecko.com/api/v3 directly.
var serverBaseUrl: String { AppSecrets.apiBaseURL }

enum Endpoint: Sendable {
    case toplist(itemsPerPage: Int, sortOption: SortOption, currency: CurrencyModel, platformId: String? = nil)
    case global
    case globalChart(days: String)
    case allCoins
    case allExchanges
    case trending
    case search(query: String)
    case fearAndGreed
    case allCategories(sortOption: SortOption)
    case allDerivatives(sortOption: SortOption)
    case image(url: String)
    case exchangeDerivatives(exchange: String)
    case coinsWithCurrencies(ids: [String], Currencies: [CurrencyModel] = CurrencyModel.allCurrencies)
    case candleStick(id: String, days: String, useFreeEndpoint: Bool = false, currency: CurrencyModel)
    case exchangeVolume(id: String, days: String)
    case exchange(id: String)
    case exchanges
    case coin(id: String, sparkline: Bool = false, useFreeEndpoint: Bool = false)
    case coinPriceVolume(id: String, days: String, useFreeEndpoint: Bool = false, interval: String?, currency: CurrencyModel)
    case multipleCoins(ids: [String], withSparkline: Bool = false, currency: CurrencyModel)
    case newCoins
    case nftToplist(platform: NFTPlatform, sortOption: SortOption)
    case nftPlatforms
    case nftDetail(id: String)
    case nftPriceVolume(id: String, days: String)
    case nftTickers(id: String)
    case winnersLosers(priceChange: PriceChange, currency: CurrencyModel)
    case gasFees(includeHistory: Bool)
    case getAlerts
    case createPriceAlert
    case deleteAlert
    case updateUser
    case triggerPriceAlert
    case triggerBigMover
    case subBigMover
    case ubsubBigMover
    case walletImport
    case feedback
    case subCoin
    case publicTreasury(entity: TreasuryEntity, coinId: String, page: Int = 1, perPage: Int = 250)
    case entitiesList(entity: TreasuryEntity, page: Int = 1, perPage: Int = 250)
    case treasuryDetail(entityId: String)
    case treasuryHoldingChart(entityId: String, coinId: String, days: String)
    case treasuryTransactionHistory(entityId: String, coinIds: String? = nil, page: Int = 1, perPage: Int = 100)
    case user(ignoreCache: Bool = false)
    
    func pathComponent() async -> String {
        let cryptoBaseURL = "\(serverBaseUrl)/crypto"

        switch self {
        case .toplist:
            return "\(cryptoBaseURL)/api/v3/coins/markets"
            
        case .global:
            return "\(cryptoBaseURL)/api/v3/global"
            
        case .globalChart:
            return "\(cryptoBaseURL)/api/v3/global/market_cap_chart"
            
        case .allCoins:
            return "\(cryptoBaseURL)/api/v3/coins/list"
            
        case .allExchanges:
            return "\(cryptoBaseURL)/api/v3/exchanges/list"
            
        case .trending:
            return "\(cryptoBaseURL)/api/v3/search/trending"
            
        case .search:
            return "\(cryptoBaseURL)/api/v3/search"
            
        case .fearAndGreed:
            return "https://api.alternative.me/fng/"
            
        case .allCategories:
            return "\(cryptoBaseURL)/api/v3/coins/categories"
            
        case .allDerivatives(_):
            return "\(cryptoBaseURL)/api/v3/derivatives/exchanges"
            
        case .image(let url):
            return url

        case .exchangeDerivatives(let exchange):
            return "\(cryptoBaseURL)/api/v3/derivatives/exchanges/\(exchange)"
            
        case .coinsWithCurrencies:
            return "\(cryptoBaseURL)/api/v3/simple/price"
            
        case .candleStick(let id, let days, _, _):
            if days == "max" {
                return "\(serverBaseUrl)/crypto/api/v3/coins/\(id)/ohlc"
            } else {
                return "\(cryptoBaseURL)/api/v3/coins/\(id)/ohlc"
            }
            
        case .exchangeVolume(let id, _):
            return "\(cryptoBaseURL)/api/v3/exchanges/\(id)/volume_chart"
            
        case .exchange(let id):
            return "\(cryptoBaseURL)/api/v3/exchanges/\(id)"
            
        case .exchanges:
            return "\(cryptoBaseURL)/api/v3/exchanges"
            
        case .coin(let id, _, _):
            let sanitizedId = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
            return "\(cryptoBaseURL)/api/v3/coins/\(sanitizedId)"
            
        case .coinPriceVolume(let id, let days, _, _, _):
            let sanitizedId = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
            if days == "max" {
                return "\(serverBaseUrl)/crypto/api/v3/coins/\(sanitizedId)/market_chart"
            } else {
                return "\(cryptoBaseURL)/api/v3/coins/\(sanitizedId)/market_chart"
            }

        case .multipleCoins:
            return "\(cryptoBaseURL)/api/v3/coins/markets"
            
        case .newCoins:
            return "\(serverBaseUrl)/crypto/api/v3/coins/list/new"
            
        case .nftToplist:
            return "\(serverBaseUrl)/crypto/api/v3/nfts/markets"
            
        case .nftPlatforms:
            return "\(serverBaseUrl)/crypto/api/v3/asset_platforms"
            
        case .nftPriceVolume(let id, _):
            return "\(serverBaseUrl)/crypto/api/v3/nfts/\(id)/market_chart"
            
        case .nftDetail(let id):
            return "\(cryptoBaseURL)/api/v3/nfts/\(id)"
            
        case .nftTickers(let id):
            return "\(cryptoBaseURL)/api/v3/nfts/\(id)/tickers"
            
        case .winnersLosers:
            return "\(serverBaseUrl)/crypto/api/v3/coins/top_gainers_losers"
            
        case .gasFees:
            return "\(serverBaseUrl)/gas"
            
        case .getAlerts:
            return "\(serverBaseUrl)/get-alerts"
            
        case .createPriceAlert:
            return "\(serverBaseUrl)/create-alert"
            
        case .deleteAlert:
            return "\(serverBaseUrl)/delete-alert"
            
        case .updateUser:
            return "\(serverBaseUrl)/update-user"
            
        case .triggerPriceAlert:
            return "\(serverBaseUrl)/price-alert-trigger"
            
        case .triggerBigMover:
            return "\(serverBaseUrl)/big-mover-trigger"
            
        case .subBigMover:
            return "\(serverBaseUrl)/sub-big-mover"
            
        case .ubsubBigMover:
            return "\(serverBaseUrl)/unsub-big-mover"
            
        case .walletImport:
            return "\(serverBaseUrl)/wallet-import"
            
        case .feedback:
            return "\(serverBaseUrl)/feedback"
            
        case .subCoin:
            return "\(serverBaseUrl)/premium/sub-coin"
            
        case .publicTreasury(let entity, let coinId, _, _):
            return "\(cryptoBaseURL)/api/v3/\(entity.rawValue)/public_treasury/\(coinId)"

        case .entitiesList:
            return "\(cryptoBaseURL)/api/v3/entities/list"

        case .treasuryDetail(let entityId):
            return "\(cryptoBaseURL)/api/v3/public_treasury/\(entityId)"

        case .treasuryHoldingChart(let entityId, let coinId, _):
            return "\(cryptoBaseURL)/api/v3/public_treasury/\(entityId)/\(coinId)/holding_chart"

        case .treasuryTransactionHistory(let entityId, _, _, _):
            return "\(cryptoBaseURL)/api/v3/public_treasury/\(entityId)/transaction_history"
            
        case .user:
            return "\(serverBaseUrl)/user"
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .toplist(let itemsPerPage, let sortOption, let currency, let platformId):
            var items = [
                URLQueryItem(name: "vs_currency", value: currency.code.lowercased()),
                URLQueryItem(name: "order", value: sortOption.toplistApiValue),
                URLQueryItem(name: "per_page", value: "\(itemsPerPage)"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "sparkline", value: "false"),
                URLQueryItem(name: "price_change_percentage", value: "1h,24h,7d,30d")
            ]
            if let platformId {
                items.append(URLQueryItem(name: "category", value: platformId))
            }
            return items
            
        case .search(let query):
            return [URLQueryItem(name: "query", value: query)]
            
        case .fearAndGreed:
            return [
                URLQueryItem(name: "limit", value: "0"),
                URLQueryItem(name: "format", value: "json")
            ]
            
        case .allCategories(let sortOption):
            return [URLQueryItem(name: "order", value: sortOption.categoriesApiValue)]
            
        case .allDerivatives(let sortOption):
            return [
                URLQueryItem(name: "per_page", value: "250"),
                URLQueryItem(name: "order", value: sortOption.derivativesApiValue)
            ]
            
        case .exchangeDerivatives:
            return [URLQueryItem(name: "include_tickers", value: "unexpired")]
            
        case .coinsWithCurrencies(let ids, let currencies):
            return [
                URLQueryItem(name: "ids", value: ids.stringSeparatedByComma),
                URLQueryItem(name: "vs_currencies", value: currencies.map({ $0.code }).stringSeparatedByComma)
            ]
            
        case .candleStick(_, let days, _, let currency):
            return [
                URLQueryItem(name: "vs_currency", value: currency.code.lowercased()),
                URLQueryItem(name: "days", value: days)
            ]
            
        case .exchangeVolume(_, let days):
            return [URLQueryItem(name: "days", value: days)]
            
        case .globalChart(let days):
            return [URLQueryItem(name: "days", value: days)]
            
        case .exchanges:
            return [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .coin(_, let sparkline, _):
            return [URLQueryItem(name: "sparkline", value: sparkline ? "true" : "false")]
            
        case .coinPriceVolume(_, let days, _, let interval, let currency):
            var items = [
                URLQueryItem(name: "vs_currency", value: currency.code.lowercased()),
                URLQueryItem(name: "days", value: days)
            ]
            if let interval = interval {
                items.append(URLQueryItem(name: "interval", value: interval))
            }
            return items
            
        case .multipleCoins(let ids, let sparkline, let currency):
            return [
                URLQueryItem(name: "vs_currency", value: currency.code),
                URLQueryItem(name: "ids", value: ids.stringSeparatedByComma),
                URLQueryItem(name: "order", value: "market_cap_desc"),
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "sparkline", value: "\(sparkline)"),
                URLQueryItem(name: "price_change_percentage", value: "1h,24h,7d,30d")
            ]
            
        case .nftToplist(let platform, let sortOption):
            var items = [
                URLQueryItem(name: "order", value: sortOption.nftApiValue),
                URLQueryItem(name: "per_page", value: "250")
            ]
            if let platformId = platform.id, platformId != "all" {
                items.append(URLQueryItem(name: "asset_platform_id", value: platformId))
            }
            return items
            
        case .nftPlatforms:
            return [URLQueryItem(name: "filter", value: "nft")]
            
        case .nftPriceVolume(_, let days):
            return [URLQueryItem(name: "days", value: days)]
            
        case .winnersLosers(let priceChange, let currency):
            return [
                URLQueryItem(name: "vs_currency", value: currency.code),
                URLQueryItem(name: "duration", value: priceChange.rawValue),
                URLQueryItem(name: "top_coins", value: "500")
            ]
            
        case .gasFees(let includeHistory):
            return includeHistory ? [URLQueryItem(name: "includeHistory", value: "true")] : []
            
        case .publicTreasury(_, _, let page, let perPage):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ]

        case .entitiesList(let entity, let page, let perPage):
            return [
                URLQueryItem(name: "entity_type", value: entity.apiEntityType),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ]

        case .treasuryHoldingChart(_, _, let days):
            return [URLQueryItem(name: "days", value: days)]

        case .treasuryTransactionHistory(_, let coinIds, let page, let perPage):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ]
            if let coinIds {
                items.append(URLQueryItem(name: "coin_ids", value: coinIds))
            }
            return items

        case .global, .allCoins, .allExchanges, .trending, .image, .exchange, .newCoins,
             .nftDetail, .nftTickers, .getAlerts, .createPriceAlert,
             .deleteAlert, .updateUser, .triggerPriceAlert, .triggerBigMover,
             .subBigMover, .ubsubBigMover, .walletImport, .feedback,
             .subCoin, .treasuryDetail, .user:
            return []
        }
    }
    
    var shouldShowSnackbar: Bool {
        switch self {
        case .allCoins, .image(_), .walletImport, .createPriceAlert,
             .subCoin:
            return false
            
        default:
            return true
        }
    }

    /// Missing treasury data should render the empty state instead of an error.
    var treatsNotFoundAsEmpty: Bool {
        switch self {
        case .publicTreasury:
            return true
        default:
            return false
        }
    }
    
    func shouldAddBearerToken() -> Bool {
        switch self {
        case .deleteAlert, .getAlerts, .createPriceAlert, .subBigMover, .ubsubBigMover,
                .updateUser, .walletImport, .subCoin, .user:
            return true
        default:
            return false
        }
    }
    
    var shouldReturnRawData: Bool {
        switch self {
            case .image:
                return true

            default:
                return false
        }
    }

    /// Cache duration in minutes. Used to determine if cached data is still valid.
    func cacheTimeMinutes() -> Int {
        let defaultMinutes = 3
        switch self {
        case .allCoins, .allExchanges, .nftPlatforms, .entitiesList:
            return 60 * 24 * 1 // 1 days
        case .trending, .search:
            return 60 // 1 hour
        case .user(let ignoreCache):
            return ignoreCache ? 0 : 60 * 24 * 1
        case .getAlerts:
            return 0 // no cache
        default:
            return defaultMinutes
        }
    }
}
