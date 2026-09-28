//
//  CryptoDetailOverviewView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/12/25.
//

import SwiftUI

struct CryptoDetailOverviewView: View {
    let cryptoDetailModel: CurrencyDataModel?
    let timeChart: TimeCharts
    let prices: [Double]?
    let totalMarketCap: Double?
    let alerts: [AlertCoin]?
    let fromScreen: ScreenLabel
    
    @Binding var isSelectingCurrency: Bool
    @Binding var selectedCurrency: CurrencyModel
    @Binding var showCommunitySentimentHelp: Bool
    
    let addNewAlert: () -> Void
    let deleteAlert: (AlertCoin) -> Void
    var showsCurrencyConverter = true
    var showsPriceAlerts = true
    var horizontalPadding: CGFloat = 16

    private var padding: CGFloat {
        #if IS_WATCH
        16
        #else
        32
        #endif
    }
    
    var body: some View {
        VStack(spacing: padding) {
            CryptoDetailStatisticsView(
                cryptoDetailModel: cryptoDetailModel,
                timeChart: timeChart,
                prices: prices,
                totalMarketCap: totalMarketCap
            )
            
            HistoricalDataView(
                cryptoDetailModel: cryptoDetailModel
            )
            
            CommunitySentimentView(
                sentimentVotesUpPercentage: cryptoDetailModel?.sentiment_votes_up_percentage,
                sentimentVotesDownPercentage: cryptoDetailModel?.sentiment_votes_down_percentage,
                fromScreen: fromScreen,
                showCommunitySentimentHelp: $showCommunitySentimentHelp
            )
            
            #if !IS_WATCH
            if showsCurrencyConverter {
                CurrencyConverterView(
                    cryptoDetailModel: cryptoDetailModel,
                    fromScreen: fromScreen,
                    isSelectingCurrency: $isSelectingCurrency,
                    selectedCurrency: $selectedCurrency
                )
            }
            
            if showsPriceAlerts {
                CryptoDetailAlertsView(
                    cryptoDetailModel: cryptoDetailModel,
                    alerts: alerts,
                    addNewAlert: addNewAlert,
                    deleteAlert: deleteAlert
                )
            }
            #endif
        }
        .ignoresSafeArea(edges: .bottom)
        .padding(
            EdgeInsets(
                top: padding,
                leading: horizontalPadding,
                bottom: 0,
                trailing: horizontalPadding
            )
        )
    }
}
