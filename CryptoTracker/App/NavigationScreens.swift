//
//  NavigationScreens.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-22.
//

import Foundation
import SwiftUI

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
    case AddPortfolioTransaction(
        transactionType: PortfolioTransactionType,
        currencyDataModel: CurrencyDataModel?,
        transaction: PortfolioTransaction?
    )
    case PortfolioSwapTransaction(
        transactionType: PortfolioTransactionType,
        currencyDataModel: CurrencyDataModel?,
        transaction: PortfolioSwapTransaction?
    )
    case ImportWalletTransaction
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
        case .AddPortfolioTransaction(_, _, _):
            "NewPortfolioTransaction"
        case .PortfolioSwapTransaction(_, _, _):
            "PortfolioSwapTransaction"
        case .ImportWalletTransaction:
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
    case newSwapTransaction = "PortfolioSwapTransaction"
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
