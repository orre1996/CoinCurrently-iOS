//
//  NavigationScreens.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-22.
//

import Foundation
import SwiftUI

enum SearchCase: String, Codable {
    case onlyCoins = ""
    case coins = "Coins"
    case nfts = "NFTs"
    case categories = "Sectors"
    case exchanges = "Exchanges"
    
    var accessibilityItemType: String {
        switch self {
        case .onlyCoins, .coins:
            return "Coin"
        case .nfts:
            return "NFT"
        case .categories:
            return "Sector"
        case .exchanges:
            return "Exchange"
        }
    }
}

enum SearchScreenCase: Codable, Equatable, Hashable {
    case search(list: SearchCase)
    case transaction(transactionType: NewTransactionType)
    case fixedList(list: [Toplist])
    
    var title: String {
        switch self {
        case .search(let list):
            switch list {
            case .onlyCoins, .coins:
                "Select Coin"
            case .nfts:
                "Select NFT"
            case .categories:
                "Select Sector"
            case .exchanges:
                "Select Exchange"
            }
        case .transaction(_):
            "Select Coin"
        case .fixedList(_):
            "Select Coin"
        }
    }
    
    var textfieldPlaceholder: String {
        switch self {
        case .search(let list):
            switch list {
            case .onlyCoins, .coins:
                "e.g. BTC or Ethereum"
            case .nfts:
                "e.g. CryptoPunks"
            case .categories:
                "e.g. Layer 1"
            case .exchanges:
                "e.g. Coinbase"
            }
        case .transaction(_):
            "e.g. BTC or Ethereum"
        case .fixedList(_):
            "e.g. BTC or Ethereum"
        }
    }
    
    var coins: [Toplist] {
        switch self {
        case .fixedList(let list):
            return list
        default:
            return []
        }
    }
}

enum NavigationScreens: Codable, Equatable, Hashable {
    
    // For analytics
    case Home
    case Portfolio
    case Market
    case News
    case Settings
    
    // For app use
    case MainFlow
    case CryptoDetail(
        currencyDataModel: CurrencyDataModel
    )
    case CompareCoins(
        cryptoInfo: CurrencyDataModel?,
        priceVolumeModel: PriceVolumeModel?,
        compareId: String
    )
    case NewPortfolioTransaction(
        transactionType: NewTransactionType,
        currencyDataModel: CurrencyDataModel?,
        transaction: NewTransaction?
    )
    case NewSwapTransaction(
        transactionType: NewTransactionType,
        currencyDataModel: CurrencyDataModel?,
        transaction: NewSwapTransaction?
    )
    case NewImportTransaction
    case Feedback
    case Referral(referralCode: String)
    
    // Home
    case FearGreed
    case GlobalMarket
    case GasFees
    
    // Portfolio
    case Search(
        screenCase: SearchScreenCase
    )
    
    case WalletDetails(
        wallet: AddressImport,
        coin: Toplist
    )
    
    // Market
    case NFTDetail(
        nftToplist: NFTToplist
    )
    case CategoryDetail(
        category: CryptoCategory
    )
    case Heatmap(
        category: CryptoCategory?
    )
    case ExchangeDetail(
        exchange: Exchange
    )
    case DerivativeDetail(
        derivative: Derivative,
    )
    case TreasuryDetail(
        treasuryId: String,
        treasuryDetail: TreasuryDetailEntity,
        coinId: String
    )
    
    // More
    case StartTab
    case CurrencySelector
    case Widgets
    case Converter
    case PriceAlerts
    case Achievements
    
    // General
    case BuyPro
    
    func rawValue(currentTab: String) -> String {
        switch self {
        case .MainFlow:
            currentTab
        case .CryptoDetail(_):
            "CryptoDetail"
        case .CompareCoins(_, _, _):
            "CompareCoins"
        case .NewPortfolioTransaction(_, _, _):
            "NewPortfolioTransaction"
        case .NewSwapTransaction(_, _, _):
            "NewSwapTransaction"
        case .NewImportTransaction:
            "NewImportTransaction"
        case .Feedback:
            "Feedback"
        case .Referral(_):
            "Referral"
        case .FearGreed:
            "FearGreed"
        case .GlobalMarket:
            "GlobalMarket"
        case .GasFees:
            "GasFees"
        case .Search(_):
            "Search"
        case .WalletDetails(_, _):
            "WalletDetails"
        case .NFTDetail(_):
            "NFTDetail"
        case .CategoryDetail:
            "CategoryDetail"
        case .Heatmap:
            "Heatmap"
        case .ExchangeDetail(_):
            "ExchangeDetail"
        case .DerivativeDetail(_):
            "DerivativeDetail"
        case .TreasuryDetail(_, _, _):
            "TreasuryDetail"
        case .StartTab:
            "StartTab"
        case .CurrencySelector:
            "CurrencySelector"
        case .Widgets:
            "Widgets"
        case .Converter:
            "Converter"
        case .PriceAlerts:
            "PriceAlerts"
        case .Achievements:
            "Achievements"
        case .BuyPro:
            "Settings"
            
        // For analytics
        case .Home:
            "Home"
        case .Portfolio:
            "Portfolio"
        case .Market:
            "Market"
        case .News:
            "News"
        case .Settings:
            "Settings"
            
        }
    }
}

/// Parameter-free screen identifiers for analytics (aligned with ``NavigationScreens/rawValue``).
enum ScreenLabel: String {
    case mainFlow = "MainFlow"
    case cryptoDetail = "CryptoDetail"
    case compareCoins = "CompareCoins"
    case newPortfolioTransaction = "NewPortfolioTransaction"
    case newSwapTransaction = "NewSwapTransaction"
    case newImportTransaction = "NewImportTransaction"
    case feedback = "Feedback"
    case referral = "Referral"
    case fearGreed = "FearGreed"
    case globalMarket = "GlobalMarket"
    case gasFees = "GasFees"
    case search = "Search"
    case walletDetails = "WalletDetails"
    case nftDetail = "NFTDetail"
    case categoryDetail = "CategoryDetail"
    case heatmap = "Heatmap"
    case exchangeDetail = "ExchangeDetail"
    case derivativeDetail = "DerivativeDetail"
    case treasuryDetail = "TreasuryDetail"
    case currencySelector = "CurrencySelector"
    case widgets = "Widgets"
    case converter = "Converter"
    case priceAlerts = "PriceAlerts"
    case achievements = "Achievements"
    case settings = "Settings"
    case home = "Home"
    case portfolio = "Portfolio"
    case market = "Market"
    case news = "News"
    case buyPro = "BuyPro"
    case toplist = "Toplist"
    case nfts = "NFTs"
    case treasuries = "Treasuries"
    case sectors = "Sectors"
    case exchanges = "Exchanges"
    case derivatives = "Derivatives"
}

enum SheetLabel: String {
    case communitySentimentHelp = "CommunitySentimentHelp"
    case fearGreedHelp = "FearGreedHelp"
    case gasFeesHelp = "GasFeesHelp"
    case gasFeesCost = "GasFeesCost"
    case widgetsHelp = "WidgetsHelp"
    case editWidgets = "EditWidgets"
    case coinSearch = "CoinSearch"
    case currencySelector = "CurrencySelector"
    case theme = "Theme"
    case startTab = "StartTab"
    case resetApp = "ResetApp"
    case newPriceAlert = "NewPriceAlert"
    case sortBy = "SortBy"
    case priceChange = "PriceChange"
    case heatmapWeighting = "HeatmapWeighting"
    case platform = "Platform"
    case renameWallet = "RenameWallet"
    case deleteWallet = "DeleteWallet"
    case walletInfo = "WalletInfo"
    case portfolioTypeFilter = "PortfolioTypeFilter"
    case portfolioDateFilter = "PortfolioDateFilter"
    case portfolioCoinFilter = "PortfolioCoinFilter"
    case portfolioTransactionDetails = "PortfolioTransactionDetails"
    case portfolioAddTransactionType = "PortfolioAddTransactionType"
    case portfolioExportFormat = "PortfolioExportFormat"
    case newTransactionDate = "NewTransactionDate"
    case newTransactionTime = "NewTransactionTime"
    case derivativeDetailSheet = "DerivativeDetailSheet"
}

enum BuyProAction: String {
    case Favorite
    case NewsFilter
    case Settings
    case PriceAlert
    case ImportWallet
    case AddTransaction
    case ExportPortfolio
    case Deeplink
    case HomePromotion
}

extension Int {
    var tabToScreenLabel: ScreenLabel? {
        switch self {
        case 0:
            return .home
        case 1:
            return .portfolio
        case 2:
            return .market
        case 3:
            return .news
        case 4:
            return .settings
        default:
            return nil
        }
    }
    
    var newsTab: String {
        switch self {
        case 0:
            return "Articles"
        case 1:
            return "Video"
        case 2:
            return "Podcasts"
        default:
            return "Invalid"
        }
    }
}
