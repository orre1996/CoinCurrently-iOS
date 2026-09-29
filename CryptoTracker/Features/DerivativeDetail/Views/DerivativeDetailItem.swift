//
//  DerivativeDetailItem.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/4/26.
//

import SwiftUI

struct DerivativeDetailItem: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let derivativeDetail: DerivativeDetail?
    let multiplier: Double?
    let isFutures: Bool
    let index: Int
    let listCount: Int
    let imageUrl: String?
    let hasToplist: Bool
    let derivativeSelected: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            HStack(spacing: 8) {
                coinImageView
                
                symbolView
            }
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 24 : 0, horizontalAlignment: isHorizontal ? .trailing : .trailing, verticalAlignment: .top) {
                priceView
                
                if isHorizontal {
                    openInterestColumnView
                } else {
                    openInterestSubtitleView
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(
            EdgeInsets(
                top: 10,
                leading: 16,
                bottom: 10,
                trailing: 16
            )
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            derivativeSelected()
        }
    }
    
    @ViewBuilder
    private var coinImageView: some View {
        if hasToplist && imageUrl == nil {
            Circle()
                .strokeBorder(Color.outlineVariant, lineWidth: 1)
                .frame(width: 28 * min(scale, 1.5), height: 28 * min(scale, 1.5))
        } else {
            ShimmeringImage(
                imageUrl: imageUrl,
                downloading: imageUrl == nil,
                size: 28 * min(scale, 1.5)
            )
            .accessibilityHidden(true)
        }
    }
    
    private var symbolView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmeringText(
                text: derivativeDetail?.symbol ?? "000000",
                isDownloading: derivativeDetail?.symbol == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            
            if isFutures {
                ShimmeringText(
                    text: derivativeDetail?.expired_at.map { $0.timeUntilExpired } ?? "-",
                    isDownloading: derivativeDetail == nil
                )
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(12))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(symbolAccessibilityLabel)
    }
    
    private var symbolAccessibilityLabel: String {
        let typeLabel = Localization.string(isFutures ? "Future" : "Perpetual")
        let symbol = derivativeDetail?.symbol?.map({ "\($0)" }).joined(separator: " ") ?? ""
        var label = Localization.format("%1$@ %2$d of %3$d, Symbol: %4$@", typeLabel, index + 1, listCount, symbol)
        
        if isFutures, let expiredAt = derivativeDetail?.expired_at {
            let expiresIn = expiredAt.timeUntilExpired
            if Date(timeIntervalSince1970: expiredAt) <= Date() {
                label += Localization.string(", expired")
            } else {
                label += Localization.format(", expires in %@", expiresIn)
            }
        }
        
        return label
    }
    
    @ViewBuilder
    private var priceView: some View {
        let lastPrice = (Double(derivativeDetail?.converted_last?.usd ?? "0") ?? 0) * (multiplier ?? 0)
        
        ShimmeringText(
            text: derivativeDetail?.converted_last == nil || multiplier == nil ? "00000000" : lastPrice.formatCurrency(threshold: FormattingThreshold.none),
            isDownloading: derivativeDetail?.converted_last == nil || multiplier == nil
        )
        .foregroundStyle(Color.onSurface)
        .font(.satoshiBold(16))
        .multilineTextAlignment(.trailing)
        .accessibilityLabel(Localization.format("Price: %@", lastPrice.currencyAccessible()))
    }
    
    private var formattedOpenInterest: String {
        let openInterest = (derivativeDetail?.open_interest_usd ?? 0) * (multiplier ?? 0)
        return derivativeDetail?.open_interest_usd == nil || multiplier == nil
            ? "00000000"
            : openInterest.formatCurrency()
    }
    
    private var isDownloadingOpenInterest: Bool {
        derivativeDetail?.open_interest_usd == nil || multiplier == nil
    }
    
    private var openInterestAccessibilityLabel: String {
        let openInterest = (derivativeDetail?.open_interest_usd ?? 0) * (multiplier ?? 0)
        return "Open interest: \(openInterest.formatCurrency(accessible: true))"
    }
    
    @ViewBuilder
    private var openInterestColumnView: some View {
        MinimumTextSize(
            text: Localization.string("Open Interest"),
            alignment: .trailing
        ) {
            ShimmeringText(
                text: formattedOpenInterest,
                isDownloading: isDownloadingOpenInterest
            )
            .font(.satoshiBold(16))
        }
        .foregroundStyle(Color.onSurface)
        .font(.satoshiMedium(14))
        .accessibilityLabel(openInterestAccessibilityLabel)
        .multilineTextAlignment(.trailing)
    }
    
    @ViewBuilder
    private var openInterestSubtitleView: some View {
        ShimmeringText(
            text: formattedOpenInterest,
            isDownloading: isDownloadingOpenInterest
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.trailing)
        .accessibilityLabel(openInterestAccessibilityLabel)
    }
}
