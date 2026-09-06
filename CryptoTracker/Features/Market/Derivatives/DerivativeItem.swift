//
//  DerivativeItem.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-18.
//

import SwiftUI

struct DerivativeItem: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let currentDerivative: Derivative?
    let bitcoin: CurrencyDataModel?
    var listIndex: Int? = nil
    var listCount: Int? = nil
    let derivativeSelected: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 8 : 0, horizontalAlignment: .leading, verticalAlignment: .top) {
                imageView
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 0, horizontalAlignment: .leading, verticalAlignment: .top) {
                    nameView
                    
                    if !isHorizontal {
                        interestSubtitleView
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                if isHorizontal {
                    interestColumnView
                }
                
                volumeView
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap for \(currentDerivative?.name ?? "") details")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            derivativeSelected()
        }
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        if let listIndex, let listCount {
            components.append("Derivative \(listIndex + 1) of \(listCount), \(currentDerivative?.name ?? "")")
        } else {
            components.append(currentDerivative?.name ?? "")
        }
        
        let bitcoinInterest = currentDerivative?.open_interest_btc ?? 0.0
        let bitcoinPrice = bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let totalInterest = bitcoinInterest * bitcoinPrice
        components.append("Open interest: \(totalInterest.formatCurrency(accessible: true)), ")
        
        let bitcoinVolume = Double(currentDerivative?.trade_volume_24h_btc ?? "0.0") ?? 0.0
        let totalVolume = bitcoinVolume * bitcoinPrice
        components.append("24 hour volume: \(totalVolume.formatCurrency(accessible: true))")
        
        return components.joined(separator: " - ")
    }
    
    private var imageView: some View {
        ShimmeringImage(
            imageUrl: currentDerivative?.image,
            downloading: currentDerivative == nil,
            size: 28 * min(scale, 1.5)
        )
        .accessibilityHidden(true)
    }
    
    private var nameView: some View {
        ShimmeringText(
            text: currentDerivative?.name ?? "000000000",
            isDownloading: currentDerivative == nil
        )
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var interestColumnView: some View {
        MinimumTextSize(
            text: "24h Volume",
            alignment: .trailing
        ) {
            ShimmeringText(
                text: formattedOpenInterest,
                isDownloading: isDownloadingOpenInterest
            )
            .font(.satoshiBold(16))
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
    
    private var formattedOpenInterest: String {
        let bitcoinInterest = currentDerivative?.open_interest_btc ?? 0.0
        let bitcoinPrice = bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let totalInterest = bitcoinInterest * bitcoinPrice
        return totalInterest.formatCurrency()
    }
    
    private var isDownloadingOpenInterest: Bool {
        currentDerivative == nil || bitcoin?.market_data?.current_price == nil
    }
    
    @ViewBuilder
    private var interestSubtitleView: some View {
        ShimmeringText(
            text: formattedOpenInterest,
            isDownloading: isDownloadingOpenInterest
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var volumeView: some View {
        let bitcoinVolume = Double(currentDerivative?.trade_volume_24h_btc ?? "0.0") ?? 0.0
        let bitcoinPrice = bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let totalVolume = bitcoinVolume * bitcoinPrice
        
        MinimumTextSize(
            text: "24h Volume",
            alignment: .trailing
        ) {
            ShimmeringText(
                text: totalVolume.formatCurrency(),
                isDownloading: currentDerivative == nil || bitcoin?.market_data?.current_price == nil
            )
            .font(.satoshiBold(16))
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
}
