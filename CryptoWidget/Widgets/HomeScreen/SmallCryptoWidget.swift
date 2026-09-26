//
//  SmallWidget.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-24.
//

import SwiftUI

struct SmallCryptoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: Toplist?
    let image: UIImage?
    let selectedCurrency: CurrencyModel?
    let coinID: String?
    var showsEmptyPrompt: Bool = true
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var hasSelectedCoin: Bool {
        guard let coinID, !coinID.isEmpty else { return false }
        return true
    }
    
    var body: some View {
        if !hasSelectedCoin && data == nil {
            if showsEmptyPrompt {
                WidgetEmptyView(plural: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            Group {
                if let url = coinURL {
                    Link(destination: url) {
                        coinContent
                    }
                } else {
                    coinContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(coinURL)
        }
    }
    
    private var coinURL: URL? {
        URL(string: data?.symbol == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")")
    }

    private var coinContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                coinImageView
                
                coinInfoView
            }
            
            Spacer(minLength: 8)
            
            coinPriceView
            
            Spacer(minLength: 8)
            
            timeframeChangeView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }

    private var coinImageView: some View {
        ShimmeringImageWithUIImage(
            image: image,
            downloading: image == nil,
            size: 24 * min(scale, 1.5)
        )
    }
    
    private var coinInfoView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmeringText(
                text: data?.name ?? "000000",
                isDownloading: data == nil
            )
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurface(for: scheme))
            
            ShimmeringText(
                text: data?.symbol?.uppercased() ?? "0000",
                isDownloading: data == nil
            )
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDim(for: scheme))
        }
    }
    
    private var coinPriceView: some View {
        ShimmeringText(
            text: data?.current_price?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000000",
            isDownloading: data == nil
        )
        .font(.satoshiBold(22))
        .foregroundStyle(Color.onSurface(for: scheme))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
    
    private var timeframeChangeView: some View {
        HStack(spacing: 4) {
            Text("24h")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
            
            PriceChangePercentView(
                change: data?.price_change_percentage_24h_in_currency,
                size: .extraSmall,
                accessibleTimeframe: "24 hour",
                spacing: 0,
                isDownloading: data == nil
            )
        }
    }
}
