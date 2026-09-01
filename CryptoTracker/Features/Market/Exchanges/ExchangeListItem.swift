//
//  ExchangeListItem.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-25.
//

import SwiftUI

struct ExchangeListItem: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let data: ExchangeModel?
    let bitcoin: CurrencyDataModel?
    var listIndex: Int? = nil
    var listCount: Int? = nil
    let handleCurrencyClick: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                coinImage
                    .accessibilityHidden(true)
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 0, horizontalAlignment: .leading, verticalAlignment: .center) {
                    exchangeName
                    
                    if !isHorizontal {
                        volumeSubtitleView
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                volumeView
            }
            
            trustColorView
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap for \(data?.name ?? "") details")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            handleCurrencyClick()
        }
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        if let listIndex, let listCount {
            components.append("Exchange \(listIndex + 1) of \(listCount), \(data?.name ?? "")")
        } else {
            components.append(data?.name ?? "")
        }
        
        let volumeBtc = data?.trade_volume_24h_btc ?? 0.0
        let bitcoinPrice = bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let totalVolume = volumeBtc * bitcoinPrice
        components.append("24 hour volume: \(totalVolume.formatCurrency(accessible: true))")
        
        if let trustScore = data?.trust_score {
            components.append("Trust score: \(trustScore) of 10")
        }
        
        return components.joined(separator: ". ")
    }
    
    private var coinImage: some View {
        ShimmeringImage(
            imageUrl: data?.image ?? "",
            downloading: data == nil,
            size: 28 * min(scale, 1,5)
        )
    }
    
    private var exchangeName: some View {
        NewShimmeringText(
            text: data?.name ?? "00000",
            isDownloading: data?.name == nil
        )
        .frame(minWidth: 80, alignment: .leading)
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
    
    private var formattedVolume: String {
        let volumeBtc = data?.trade_volume_24h_btc ?? 0.0
        let bitcoinPrice = bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let totalVolume = volumeBtc * bitcoinPrice
        return totalVolume.formatCurrency(
            threshold: isHorizontal ? FormattingThreshold.none : FormattingThreshold.million
        )
    }
    
    private var isDownloadingVolume: Bool {
        data == nil || bitcoin == nil
    }
    
    @ViewBuilder
    private var volumeView: some View {
        NewShimmeringText(
            text: formattedVolume,
            isDownloading: isDownloadingVolume
        )
        .multilineTextAlignment(.trailing)
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
        .layoutPriority(1)
    }
    
    @ViewBuilder
    private var volumeSubtitleView: some View {
        NewShimmeringText(
            text: formattedVolume,
            isDownloading: isDownloadingVolume
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    private var trustColorView: some View {
        NewShimmeringText(
            text: "\(data?.trust_score ?? 0)/10",
            isDownloading: data == nil
        )
        .font(.satoshiBold(16))
        .foregroundStyle(data?.trust_score?.trustColor ?? Color.onSurfaceDim)
        .accessibilityHidden(true)
    }
}

