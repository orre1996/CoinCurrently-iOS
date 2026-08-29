//
//  CryptoDetailOverviewView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/12/25.
//

import SwiftUI

struct NFTDetailOverviewView: View {
    let nftDetailModel: NFTDetail?
    let currentCurrency: CurrencyDataModel?
    let prices: [Double]?
    let timeChart: TimeCharts
    let fromScreen: ScreenLabel
    
    let chartCurrency: CurrencyModel
    let isFiatSelected: Bool
    let multiplier: Double?
    
    @Binding var isSelectingCurrency: Bool
    @Binding var selectedCurrency: CurrencyModel
    
    var body: some View {
        VStack(spacing: 32) {
            NFTDetailStatisticsView(
                nftDetailInfo: nftDetailModel,
                timeChart: timeChart,
                prices: prices,
                chartCurrency: chartCurrency,
                isFiatSelected: isFiatSelected,
                multiplier: multiplier
            )
            
            NFTHistoricalDataView(
                nftDetailModel: nftDetailModel
            )
    
            NFTConverterView(
                currentCurrency: currentCurrency,
                fromScreen: fromScreen,
                isSelectingCurrency: $isSelectingCurrency,
                selectedCurrency: $selectedCurrency
            )
        }
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
