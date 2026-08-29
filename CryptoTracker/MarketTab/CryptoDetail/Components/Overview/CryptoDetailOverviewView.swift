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
    
    var body: some View {
        VStack(spacing: 32) {
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
            
            CurrencyConverterView(
                cryptoDetailModel: cryptoDetailModel,
                fromScreen: fromScreen,
                isSelectingCurrency: $isSelectingCurrency,
                selectedCurrency: $selectedCurrency
            )
            
            CryptoDetailAlertsView(
                cryptoDetailModel: cryptoDetailModel,
                alerts: alerts,
                addNewAlert: addNewAlert,
                deleteAlert: deleteAlert
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
    }
}
