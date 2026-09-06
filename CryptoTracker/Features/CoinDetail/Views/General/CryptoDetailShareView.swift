//
//  CryptoDetailShareView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/6/25.
//

import SwiftUI

struct CryptoDetailShareView: View {
    let viewModel: CryptoDetailViewModelImp
    
    @State private var biggestChartValue: CGSize = .zero
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        LazyVStack(spacing: 0) {
            CryptoDetailSummaryView(
                name: viewModel.cryptoInfo?.name,
                currentPrice: viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency(),
                imageUrl: viewModel.cryptoInfo?.image?.small,
                prices: viewModel.onlyPrices,
                isSharing: true,
                image: viewModel.currencyLogo,
                selectedTimeframe: viewModel.selectedTimeFrame,
                shortPrice: false,
                shortChange: false,
                changeCoin: { }
            )
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 16,
                    trailing: 16
                )
            )
            
            ZStack {
                ChartBackground(
                    biggestValue: $biggestChartValue,
                    values: (0..<6).map({ viewModel.getPriceInChart(prices: viewModel.getPrices(), at: $0) })
                )
                
                if viewModel.mainReloading {
                    ActivityIndicator()
                        .padding(.trailing, biggestChartValue.width)
                } else {
                    if viewModel.isCandleChartEnabled {
                        candleGraph(
                            halfBiggestChartValueHeight: halfBiggestChartValueHeight
                        )
                        .anyView()
                    } else {
                        mainGraph(
                            halfBiggestChartValueHeight: halfBiggestChartValueHeight
                        )
                        .anyView()
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
            .accessibilityHidden(true)
            
            ChartTimeStamps(
                currentTimeChart: viewModel.selectedTimeFrame,
                timeStamps: viewModel.getTimestamps()
            )
            .padding(
                EdgeInsets(
                    top:  -biggestChartValue.height / 2,
                    leading: 16,
                    bottom: 8 + biggestChartValue.height / 2,
                    trailing: 16 + biggestChartValue.width
                )
            )
        }
    }

    @ViewBuilder
    private func mainGraph(halfBiggestChartValueHeight: CGFloat) -> some View {
        PriceLineChartView(
            prices: viewModel.onlyPrices,
            color: viewModel.graphColor,
            lineWidth: 2,
            dragPositions: [],
            size: viewModel.chartSize,
            isDragging: false
        )
        .readSize {
            viewModel.chartSize = $0
        }
        .padding(
            EdgeInsets(
                top: halfBiggestChartValueHeight,
                leading: 0,
                bottom: halfBiggestChartValueHeight,
                trailing: biggestChartValue.width
            )
        )
    }
    
    @ViewBuilder
    private func candleGraph(
        halfBiggestChartValueHeight: CGFloat
    ) -> some View {
        ZStack {
            CandleStickView(
                candles: viewModel.candleSticks,
                viewWidth: viewModel.chartSize.width
            )
        }
        .readSize {
            viewModel.chartSize = $0
        }
        .padding(
            EdgeInsets(
                top: halfBiggestChartValueHeight,
                leading: 0,
                bottom: halfBiggestChartValueHeight,
                trailing: biggestChartValue.width
            )
        )
    }
}
