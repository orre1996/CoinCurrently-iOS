//
//  CategoryItemView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-18.
//

import SwiftUI

struct CategoryItemView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let currentCategory: CryptoCategory?
    let priceMultiplier: Double?
    var listIndex: Int? = nil
    var listCount: Int? = nil
    let categorySelected: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                nameView
                
                HStack(alignment: .center, spacing: 4) {
                    if let currentCategory, currentCategory.top_3_coins != nil {
                        realImagesView
                    } else {
                        tempImagesView
                    }
                }
                .accessibilityHidden(true)
                
                if !isHorizontal {
                    marketCapSubtitleView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                marketCapView
            }
            
            priceChangeView
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(Localization.format("Double tap for %@ details", currentCategory?.name ?? ""))
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            categorySelected()
        }
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        if let listIndex, let listCount {
            components.append(Localization.format("Category %d of %d, %@", listIndex + 1, listCount, currentCategory?.name ?? ""))
        } else {
            components.append(currentCategory?.name ?? "")
        }
        
        let marketCap = (currentCategory?.market_cap ?? 0.0) * (priceMultiplier ?? 0.0)
        components.append(Localization.format("Market cap: %@", marketCap.formatCurrency(accessible: true)))
        
        let change = currentCategory?.market_cap_change_24h
        let safeChange = change?.isInfinite ?? false ? 0 : change
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let accessibleChange = safeChange?.numberAccessible(maxPlaces: decimals) ?? ""
        let direction = change?.directionAccessible ?? ""
        components.append(Localization.format(
            "24 hour price change: %@ %@ percent",
            direction.isEmpty ? "" : Localization.string(direction),
            accessibleChange
        ))
        
        return components.joined(separator: " - ")
    }
    
    private var nameView: some View {
        ShimmeringText(
            text: currentCategory?.name ?? "00000000000000",
            isDownloading: currentCategory == nil
        )
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
    
    private var formattedMarketCap: String {
        let marketCap = (currentCategory?.market_cap ?? 0.0) * (priceMultiplier ?? 0.0)
        return marketCap.formatCurrency()
    }
    
    private var isDownloadingMarketCap: Bool {
        currentCategory == nil || priceMultiplier == nil
    }
    
    @ViewBuilder
    private var marketCapView: some View {
        MinimumTextSize(
            text: Localization.string("Market Cap"),
            alignment: .trailing
        ) {
            ShimmeringText(
                text: formattedMarketCap,
                isDownloading: isDownloadingMarketCap
            )
        }
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var marketCapSubtitleView: some View {
        ShimmeringText(
            text: formattedMarketCap,
            isDownloading: isDownloadingMarketCap
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var priceChangeView: some View {
        let isLoading = isDownloadingMarketCap
        
        MinimumTextSize(
            text: "999.9%",
            extraSize: 16 * min(scale, 1.5) + 4,
            alignment: .trailing
        ) {
            PriceChangePercentView(
                change: currentCategory?.market_cap_change_24h,
                accessibleTimeframe: "24 hour",
                isDownloading: isLoading
            )
        }
        .font(.satoshiBold(16))
        .frame(alignment: .trailing)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var tempImagesView: some View {
        ForEach(0..<3, id: \.self) { index in
            ShimmeringImage(
                imageUrl: nil,
                downloading: true,
                size: 16 * min(scale, 1.5)
            )
        }
    }
    
    @ViewBuilder
    private var realImagesView: some View {
        ForEach(0..<3, id: \.self) { index in
            if let image = currentCategory?.top_3_coins?[safely: index] {
                ShimmeringImage(
                    imageUrl: image,
                    downloading: false,
                    size: 16 * min(scale, 1.5)
                )
            }
        }
    }
}

