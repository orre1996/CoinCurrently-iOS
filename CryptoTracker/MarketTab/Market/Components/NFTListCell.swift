//
//  NFTListCell.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-03.
//

import SwiftUI

struct NFTListCell: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1
    
    var nftToplist: NFTToplist?
    var chainCurrency: CurrencyModel?
    var priceMultiplier: Double?
    var listIndex: Int? = nil
    var listCount: Int? = nil
    let nftSelected: () -> Void

    private var isHorizontal: Bool {
        return !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        Button(action: {
            nftSelected()
        }, label: {
            HStack(spacing: 8) {
                AdaptiveStack(
                    isHorizontal: isHorizontal,
                    spacing: 8,
                    horizontalAlignment: .leading,
                    verticalAlignment: .center
                ) {
                    nftImageView
                    
                    nftNameView
                    
                    floorPriceView
                }
                
                priceChangeView
                    .padding(.leading, 8)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap for \(nftToplist?.name ?? "") details")
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        if let listIndex, let listCount {
            components.append("NFT \(listIndex + 1) of \(listCount), \(nftToplist?.name ?? "")")
        } else {
            components.append(nftToplist?.name ?? "")
        }
        
        if let nativeFloorPrice = nftToplist?.floor_price?.native_currency {
            components.append("Floor price: \(accessibleNativeFloorPrice(nativeFloorPrice))")
        }
        
        if let priceMultiplier {
            let convertedFloorPrice = (nftToplist?.floor_price?.usd ?? 0) * priceMultiplier
            components.append(
                "Converted floor price: \(convertedFloorPrice.formatCurrency(threshold: FormattingThreshold.none, accessible: true)), "
            )
        }
        
        let change = nftToplist?.floor_price_in_usd_24h_percentage_change
        let safeChange = change?.isInfinite ?? false ? 0 : change
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let accessibleChange = safeChange?.numberAccessible(maxPlaces: decimals) ?? ""
        components.append("24 hour price change: \(change?.directionAccessible ?? "") \(accessibleChange) percent")
        
        return components.joined(separator: " - ")
    }

    private func accessibleNativeFloorPrice(_ amount: Double) -> String {
        let maxDecimals = abs(amount) < 1 ? 7 : 2
        let amountText = amount.formattedRemovingTrailingZeros(maximumDigits: maxDecimals)
        let symbolText = accessibleNativeCurrencySymbol()
        
        guard !symbolText.isEmpty else { return amountText }
        return "\(amountText) \(symbolText)"
    }
    
    private func accessibleNativeCurrencySymbol() -> String {
        if let symbol = nftToplist?.native_currency_symbol?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            return symbol.uppercased().map { String($0) }.joined(separator: " ")
        }
        
        if let chainCurrency,
           !chainCurrency.symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            let symbol = chainCurrency.symbol.trimmingCharacters(in: .whitespaces)
            return symbol.uppercased().map { String($0) }.joined(separator: " ")
        }
        
        return ""
    }
    
    private func nativeFloorPriceCurrency() -> CurrencyModel {
        if let symbol = nftToplist?.native_currency_symbol?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            let spelledSymbol = symbol.uppercased().map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol,
                symbol: symbol,
                locale: "",
                suffix: true
            )
        }
        
        if let chainCurrency,
           !chainCurrency.symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            return chainCurrency
        }
        
        if let nativeCurrency = nftToplist?.native_currency, !nativeCurrency.isEmpty {
            return CurrencyModel(
                currency: nativeCurrency,
                code: nativeCurrency,
                symbol: "",
                locale: "",
                suffix: true
            )
        }
        
        return CurrencyModel.empty
    }
    
    private var nftImageView: some View {
        ShimmeringImage(
            imageUrl: nftToplist?.image?.small,
            downloading: nftToplist == nil,
            size: 28 * min(scale, 1.5)
        )
        .accessibilityHidden(true)
    }
    
    private var nftNameView: some View {
        NewShimmeringText(
            text: nftToplist?.name ?? "00000000",
            isDownloading: nftToplist?.name == nil
        )
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var floorPriceView: some View {
        VStack(alignment: isHorizontal ? .trailing : .leading, spacing: 0) {
            NewShimmeringText(
                text: "\(nftToplist?.floor_price?.native_currency?.formatCurrency(threshold: FormattingThreshold.none, currency: nativeFloorPriceCurrency()) ?? "0000")",
                isDownloading: nftToplist?.floor_price?.native_currency == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            
            NewShimmeringText(
                text: "\(((nftToplist?.floor_price?.usd ?? 0) * (priceMultiplier ?? 0)).formatCurrency(threshold: FormattingThreshold.none))",
                isDownloading: nftToplist?.floor_price?.native_currency == nil || priceMultiplier == nil
            )
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(12))
        }
        .multilineTextAlignment(isHorizontal ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isHorizontal ? .trailing : .leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var priceChangeView: some View {
        let change = nftToplist?.floor_price_in_usd_24h_percentage_change
        
        MinimumTextSize(
            text: "999.9%",
            extraSize: 16 * min(scale, 1.5) + 4,
            alignment: .trailing
        ) {
            NewPriceChangePercentView(
                change: change,
                accessibleTimeframe: "24 hour",
                isDownloading: nftToplist == nil
            )
        }
        .font(.satoshiBold(16))
        .frame(alignment: .trailing)
        .accessibilityHidden(true)
    }
}
