//
//  MarketStatsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/30/25.
//

import SwiftUI

struct MarketStatsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    let globalMarket: GlobalMarketModel?
    let gasFees: GasFees?
    let fearGreed: FearGreed?
    let navigateToGlobalMarket: () -> Void
    let navigateToGasFees: () -> Void
    let navigateToFearGreed: () -> Void
    
    @State private var fearMeterWidth: CGFloat = 1
    
    var body: some View {
        let isLargeFont = category.isAccessibilityCategory && verticalSizeClass == .regular
        
        AdaptiveStack(
            isHorizontal: !isLargeFont,
            spacing: isLargeFont ? 16 : 32,
            horizontalAlignment: .center,
            verticalAlignment: .top
        ) {
            marketCapView
            
            if isLargeFont {
                Separator()
            }
            
            gasFeesView
            
            if isLargeFont {
                Separator()
            }
            
            fearGreedView
        }
        .minimumScaleFactor(0.7)
        .cardBackground()
        .overlay {
            if !isLargeFont {
                dividers
            }
        }
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16 + safeAreaInsets.leading,
                bottom: 8,
                trailing: 16 + safeAreaInsets.trailing
            )
        )
    }
    
    @ViewBuilder
    private var marketCapView: some View {
        let marketCap = globalMarket?.data?.total_market_cap?.getConvertedCurrency()
        let marketCapAccessible = marketCap?.formatCurrency(accessible: true)
        
        let change = globalMarket?.data?.market_cap_change_percentage_24h_usd
        let changeDirection = change?.directionAccessible ?? ""
        let accessibleChange = change?.numberAccessible(maxPlaces: change?.changePercentDecimalPoints ?? 2) ?? ""
        
        Button(action: {
            navigateToGlobalMarket()
        }, label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Market Cap")
                    .font(.satoshiMedium(14))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                
                NewShimmeringText(
                    text: marketCap?.formatCurrency() ?? "00000",
                    isDownloading: globalMarket == nil
                )
                .font(.satoshiBold(24))
                .foregroundStyle(Color.onSurfaceContainer)
                .lineLimit(1)
                
                NewPriceChangePercentView(
                    change: change,
                    size: .small,
                    accessibleTimeframe: "24 hour",
                    isDownloading: globalMarket == nil
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The global market cap is \(marketCapAccessible ?? ""), - 24 hour price change: \(changeDirection) \(accessibleChange) percent")
        .accessibilityHint("Double tap for more global market stats")
    }
    
    @ViewBuilder
    private var gasFeesView: some View {
        let gasFee = Double(gasFees?.gasFeeData?.first?.proposeGasPrice ?? "0")
        
        Button(action: {
            navigateToGasFees()
        }, label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("ETH Gas Fee")
                    .font(.satoshiMedium(14))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                
                NewShimmeringText(
                    text: gasFee?.formatted(.number.precision(.fractionLength(2))) ?? "0000",
                    isDownloading: gasFees?.gasFeeData == nil
                )
                .font(.satoshiBold(24))
                .foregroundStyle(Color.onSurfaceContainer)
                .lineLimit(1)
                
                Text("Gwei")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceContainerDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The current average ethereum gas fee is \(gasFee?.numberAccessible(maxPlaces: 2) ?? "") Gwei.")
        .accessibilityHint("Double tap for more gas fee stats")
    }
    
    @ViewBuilder
    private var fearGreedView: some View {
        let firstValue = fearGreed?.data?.first?.value
        let classification = fearGreed?.data?.first?.value_classification ?? ""
        
        Button(action: {
            navigateToFearGreed()
        }, label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fear & Greed")
                    .font(.satoshiMedium(14))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                
                NewShimmeringText(
                    text: firstValue ?? "00",
                    isDownloading: fearGreed == nil
                )
                .font(.satoshiBold(24))
                .foregroundStyle(Color.onSurfaceContainer)
                .lineLimit(1)
                
                fearGreedMeter
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .accessibilityLabel("The current fear and greed index is \(firstValue ?? ""). \(classification)")
        .accessibilityHint("Double tap for more fear and greed stats")
    }
    
    @ViewBuilder
    private var fearGreedMeter: some View {
        let circleSize: CGFloat = 12
        let circleOutlinePadding: CGFloat = 1
        let indicatorSize = FearGreedMeter.indicatorSize(
            circleSize: circleSize,
            outlinePadding: circleOutlinePadding
        )
        let percent = (Double(fearGreed?.data?.first?.value ?? "0") ?? 0) / 100
        
        FearGreedMeter(height: 8)
            .overlay(alignment: .leading) {
                Circle()
                    .foregroundStyle(Color.surfaceContainerHighest)
                    .frame(width: circleSize, height: circleSize)
                    .padding(circleOutlinePadding)
                    .background(
                        Circle()
                            .foregroundStyle(Color.outline)
                    )
                    .offset(
                        x: FearGreedMeter.indicatorOffset(
                            containerWidth: fearMeterWidth,
                            indicatorSize: indicatorSize,
                            percent: CGFloat(percent)
                        )
                    )
                    .animation(.default, value: fearGreed?.data?.first?.value)
            }
            .padding(.top, 4)
            .readSize {
                fearMeterWidth = $0.width
            }
    }
    
    private var dividers: some View {
        HStack(spacing: 0) {
            Spacer()
            
            VerticalSeparator(width: 2)
            
            Spacer()
            
            VerticalSeparator(width: 2)
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
