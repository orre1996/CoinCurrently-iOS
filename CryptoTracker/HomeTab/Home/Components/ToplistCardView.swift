//
//  ToplistCardView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct ToplistCardView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist?
    let selectedChangeOption: PriceChange
    let isFirstElement: Bool
    let listIndex: Int
    let listCount: Int
    let navigateToCryptoDetail: () -> Void
    
    @State private var marketCapSize = CGSize.zero
    @State private var changeSize = CGSize.zero
    
    private var isHorizontal: Bool {
        return !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        Button(action: {
            navigateToCryptoDetail()
        }, label: {
            HStack(spacing: 16) {
                marketCapRankView
                
                AdaptiveStack(
                    isHorizontal: isHorizontal,
                    spacing: 8,
                    horizontalAlignment: .leading,
                    verticalAlignment: .center
                ) {
                    coinImageView
                    
                    coinStatsView
                        .padding(.trailing, 8)
                    
                    priceView
                }
                
                priceChangeView
            }
            .padding(
                EdgeInsets(
                    top: isFirstElement ? 0 : 10,
                    leading: 0,
                    bottom: 10,
                    trailing: 0
                )
            )
            .contentShape(Rectangle())
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap for \(coin?.name ?? "") details. Long press for more options")
    }
    private var marketCapRankView: some View {
        MinimumTextSize(text: "9999") {
            NewShimmeringText(
                text: coin == nil ? "-" : coin?.market_cap_rank?.description ?? "-",
                isDownloading: coin == nil
            )
        }
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiBold(16))
        .accessibilityHidden(true)
    }
    
    private var coinImageView: some View {
        ShimmeringImage(
            imageUrl: coin?.image,
            downloading: coin == nil,
            size: 28 * min(scale, 1.5)
        )
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var coinStatsView: some View {
        let marketCap = coin?.market_cap
        
        VStack(alignment: .leading, spacing: 0) {
            NewShimmeringText(
                text: coin?.symbol?.uppercased() ?? "0000",
                isDownloading: coin == nil
            )
            .multilineTextAlignment(.leading)
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            
            NewShimmeringText(
                text: coin == nil ? "00000000" : (marketCap ?? 0).formatCurrency(),
                isDownloading: coin == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
        }
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    private var priceView: some View {
        NewShimmeringText(
            text: coin?.current_price?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000000",
            isDownloading: coin == nil
        )
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .multilineTextAlignment(isHorizontal ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isHorizontal ? .trailing : .leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var priceChangeView: some View {
        let change = coin?.getPriceChange(selectedChangeOption: selectedChangeOption)
        
        MinimumTextSize(
            text: "999.9%",
            extraSize: 16 * min(scale, 1.5) + 4,
            alignment: .trailing
        ) {
            NewPriceChangePercentView(
                change: change,
                accessibleTimeframe: selectedChangeOption.accessibilityTimeframe,
                isDownloading: coin == nil
            )
        }
        .font(.satoshiBold(16))
        .frame(alignment: .trailing)
        .accessibilityHidden(true)
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append("Currency \(listIndex + 1) of \(listCount), \(coin?.name ?? "")")
        components.append("Price: \(coin?.current_price?.currencyAccessible() ?? "")")
        
        let change = coin?.getPriceChange(selectedChangeOption: selectedChangeOption)
        let safeChange = change?.isInfinite ?? false ? 0 : change
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let accessibleChange = safeChange?.numberAccessible(maxPlaces: decimals) ?? ""
        components.append("\(selectedChangeOption.accessibilityTimeframe) price change: \(change?.directionAccessible ?? "") \(accessibleChange) percent")
        components.append("Market cap: \((coin?.market_cap ?? 0).formatCurrency(accessible: true))")

        return components.joined(separator: " - ")
    }
    
}
