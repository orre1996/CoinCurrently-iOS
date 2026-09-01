//
//  CryptoDetailExchangesView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-12.
//

import SwiftUI

/// A generic view for displaying exchanges/markets across Crypto, NFT, and Exchange detail screens.

struct CryptoDetailExchangesView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    var items: [ExchangeMarketItem]? = nil
    var headerLabel: String = "Exchange"
    var sortByPriceDescending: Bool = true
    var showVolumeOverride: Bool? = nil
    var useExchangeStyle: Bool = false
    let fromScreen: ScreenLabel
    let selectedSortOption: SortOption
    let errorMessage: String
    @Binding var isSortShowing: Bool
    
    var body: some View {
        if (items == nil || !(items?.isEmpty ?? false)) {
            SecondaryButton(
                text: selectedSortOption.title,
                accessibilityLabel: "Sort, currently selected: \(selectedSortOption.accessibilityTitle)",
                icon: .sort,
                action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: fromScreen, sheet: .sortBy)
                    )
                    isSortShowing = true
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(
                EdgeInsets(
                    top: 32,
                    leading: 16,
                    bottom: 8,
                    trailing: 16
                )
            )
            
            sectionHeader
        }
        
        if let items = items {
            realList(items: items)
            
            if items.isEmpty {
                EmptyContent(
                    title: "No markets yet",
                    subTitle: "When this \(errorMessage) is added to a market, it'll show up here.",
                )
                .padding(
                    EdgeInsets(
                        top: 72,
                        leading: 32,
                        bottom: 40,
                        trailing: 32
                    )
                )
            }
        } else {
            tempList
        }
    }
    
    private var showVolume: Bool {
        if let override = showVolumeOverride {
            return override
        }
        return items?.contains { $0.volume != nil } ?? false
    }
    
    @ViewBuilder
    private var sectionHeader: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        HStack(spacing: 16) {
            Text(isHorizontal ? headerLabel : "\(headerLabel) / Price")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                if showVolume {
                    Text("Price")
                    
                    Text("24h Volume")
                } else {
                    Text("Price")
                }
            } else if showVolume {
                Text("24h Volume")
            }
        }
        .lineLimit(1)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 6,
                trailing: 16
            )
        )
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var tempList: some View {
        let rowCount: Int = isPad ? 40 : 20
        ForEach(0..<rowCount, id: \.self) { index in
            CryptoDetailExchangeRow(
                item: nil,
                showVolume: showVolume,
                useExchangeStyle: useExchangeStyle,
                fromScreen: fromScreen,
                isLastRow: index == rowCount - 1,
                headerLabel: headerLabel
            )
        }
    }
    
    @ViewBuilder
    private func realList(items: [ExchangeMarketItem]) -> some View {
        ForEach(items) { item in
            CryptoDetailExchangeRow(
                item: item,
                showVolume: showVolume,
                useExchangeStyle: useExchangeStyle,
                fromScreen: fromScreen,
                isLastRow: item == items.last,
                headerLabel: headerLabel
            )
        }
    }
}

// MARK: - Row component

struct CryptoDetailExchangeRow: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    @Environment(\.openURL) private var openURL
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let item: ExchangeMarketItem?
    let showVolume: Bool
    let useExchangeStyle: Bool
    let fromScreen: ScreenLabel
    let isLastRow: Bool
    let headerLabel: String
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                imageView
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 0, horizontalAlignment: .leading, verticalAlignment: .top) {
                    nameView
                    
                    if !isHorizontal {
                        priceSubtitleView
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                priceView
                    .frame(alignment: .trailing)
                
                if showVolume {
                    volumeView
                }
            } else if showVolume {
                volumeView
            }
        }
        .padding(
            EdgeInsets(
                top: 10,
                leading: 16,
                bottom: isLastRow ? 0 : 10,
                trailing: 16
            )
        )
        .frame(minHeight: 48)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(headerLabel) \(item?.name ?? "")")
        .accessibilityHint("Double tap for details. Long press for more options")
        .onTapGesture {
            guard let urlString = item?.tradeUrl, !urlString.isEmpty, let url = URL(string: urlString) else {
                return
            }
            
            AnalyticsManager.shared.log(
                WebViewOpened(fromScreen: fromScreen, url: url.absoluteString)
            )
            openURL(url)
        }
    }
    
    private var imageSize: CGFloat {
        useExchangeStyle ? 28 * min(scale, 1.5) : 16 * min(scale, 1.5)
    }
    
    @ViewBuilder
    private var imageView: some View {
        if useExchangeStyle && item != nil && item?.imageUrl == nil {
            Circle()
                .strokeBorder(Color.outlineVariant, lineWidth: 1)
                .frame(width: imageSize, height: imageSize)
        } else {
            ShimmeringImage(
                imageUrl: item?.imageUrl,
                downloading: item == nil,
                size: imageSize
            )
            .accessibilityHidden(true)
        }
    }
    
    private var nameView: some View {
        NewShimmeringText(
            text: item?.name ?? "000000",
            isDownloading: item?.name == nil
        )
        .foregroundStyle(Color.onSurface)
        .font(.satoshiBold(16))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityHidden(true)
        .multilineTextAlignment(.leading)
    }
    
    private var priceCurrency: CurrencyModel {
        item?.priceCurrency ?? CurrencyModel()
    }
    
    private var formattedPrice: String {
        item?.price?.formatCurrency(threshold: FormattingThreshold.none, currency: priceCurrency) ?? "000000000"
    }
    
    private var isDownloadingPrice: Bool {
        item?.price == nil
    }
    
    @ViewBuilder
    private var priceView: some View {
        NewShimmeringText(
            text: formattedPrice,
            isDownloading: isDownloadingPrice
        )
        .foregroundStyle(Color.onSurface)
        .font(.satoshiBold(16))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Last price: \(item?.price?.currencyAccessible(currency: priceCurrency) ?? "000000000")")
        .multilineTextAlignment(.trailing)
    }
    
    @ViewBuilder
    private var priceSubtitleView: some View {
        NewShimmeringText(
            text: formattedPrice,
            isDownloading: isDownloadingPrice
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var volumeView: some View {
        let currency = item?.priceCurrency ?? CurrencyModel()
        let formattedVolume = item?.volume?.formatCurrency(currency: currency)
        
        MinimumTextSize(
            text: "24h Volume",
            alignment: .trailing
        ) {
            NewShimmeringText(
                text: formattedVolume ?? "000000000",
                isDownloading: item?.volume == nil
            )
            .font(.satoshiBold(16))
        }
        .foregroundStyle(Color.onSurface)
        .font(.satoshiMedium(14))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("24 hour volume: \(item?.volume?.formatCurrency(currency: currency, accessible: true) ?? "000000000")")
        .multilineTextAlignment(.trailing)
    }
}
