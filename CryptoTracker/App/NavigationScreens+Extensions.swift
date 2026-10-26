//
//  NavigationScreens+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-19.
//

import SwiftUI

extension NavigationScreens {
    @ViewBuilder @MainActor
    var screenView: some View {
        switch self {
        case .MainFlow:
            MainTabView()
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
            
        case .CryptoDetail(let currencyDataModel):
            CryptoDetailScreen(
                cryptoInfo: currencyDataModel
            )
            
        case .CompareCoins(let cryptoInfo, let priceVolumeModel, let compareId):
            CompareCoinsScreen(
                cryptoInfo: cryptoInfo,
                priceVolumeModel: priceVolumeModel,
                compareId: compareId
            )
            
        case .AddPortfolioTransaction(let transactionType, let currencyDataModel, let transaction):
            AddTransactionScreen(
                transactionType: transactionType,
                currencyDetail: currencyDataModel,
                transaction: transaction
            )
            
        case .PortfolioSwapTransaction(let transactionType, let currencyDataModel, let transaction):
            AddSwapTransactionScreen(
                transactionType: transactionType,
                currencyDetail: currencyDataModel,
                transaction: transaction
            )
            
        case .ImportWalletTransaction:
            ImportWalletTransactionScreen()

        case .Feedback:
            FeedbackScreen()
            
        case .FearGreed:
            FearGreedScreen()
            
        case .GlobalMarket:
            GlobalMarketScreen()
            
        case .GasFees:
            GasFeesScreen()
            
        case .Search(let screenCase):
            SearchScreen(
                screenCase: screenCase,
                fromScreen: .search,
                isSheet: false,
                highlightId: nil,
                hideId: nil,
                close: { _, _, _ in }
            )
            
        case .WalletDetails(let wallet, let coin):
            WalletDetailsScreen(
                wallet: wallet,
                coin: coin
            )
            
        case .NFTDetail(let nftToplist):
            NFTDetailScreen(
                nftToplist: nftToplist
            )
            
        case .CategoryDetail(let category):
            CategoryDetailScreen(
                category: category
            )
            
        case .Heatmap(let category):
            HeatmapScreen(
                category: category
            )
            
        case .ExchangeDetail(let exchangeModel):
            ExchangeDetailScreen(
                exchangeModel: exchangeModel
            )
            
        case .DerivativeDetail(let derivative):
            DerivativeDetailScreen(
                derivative: derivative
            )
            
        case .TreasuryDetail(let treasuryId, let treasuryDetail, let coinId):
            TreasuryDetailScreen(
                treasuryId: treasuryId,
                treasuryDetail: treasuryDetail,
                coinId: coinId
            )
            
        case .StartTab:
            StartTabScreen()
            
        case .CurrencySelector:
            CurrencySelectorScreen()
            
        case .Converter:
            CalculatorScreen()
            
        case .PriceAlerts:
            PriceAlertsScreen()
            
        case .Settings:
            // Used in watch app
            EmptyView()
            
        case .Home, .Portfolio, .Market:
            EmptyView()
        }
    }
}
