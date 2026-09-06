//
//  MediumPortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-21.
//

import SwiftUI
import UIKit

struct MediumPortfolioWidget: View {
    @Environment(\.colorScheme) var scheme
    
    var entry: PortfolioEntry?
    
    private var portfolioCoins: [Pie] {
        entry?.portfolioCoins ?? []
    }
    
    var body: some View {
        if let url = URL(string: "portfolio") {
            Link(destination: url) {
                HStack(spacing: 0) {
                    SmallPortfolioWidget(entry: entry)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        dailyWinner
                            .frame(maxHeight: .infinity, alignment: .leading)
                        
                        dailyLoser
                            .frame(maxHeight: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
        }
    }
    
    private var dailyWinner: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily Winner")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            HStack(spacing: 4) {
                ShimmeringImageWithUIImage(
                    image: coinImage(for: entry?.dailyWinnerPie),
                    downloading: entry == nil || entry?.dailyWinnerPie?.data?.image == nil,
                    size: 16
                )
                
                ShimmeringText(
                    text: entry?.dailyWinnerPie?.data?.symbol?.uppercased() ?? "0000",
                    isDownloading: entry == nil
                )
                .foregroundStyle(Color.onSurface(for: scheme))
                .font(.satoshiBold(16))
            }
            
            dailyChangeView(for: entry?.dailyWinnerPie)
        }
    }
    
    private var dailyLoser: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily Loser")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            HStack(spacing: 4) {
                ShimmeringImageWithUIImage(
                    image: coinImage(for: entry?.dailyLoserPie),
                    downloading: entry == nil || entry?.dailyLoserPie?.data?.image == nil,
                    size: 16
                )
                
                ShimmeringText(
                    text: entry?.dailyLoserPie?.data?.symbol?.uppercased() ?? "0000",
                    isDownloading: entry == nil
                )
                .foregroundStyle(Color.onSurface(for: scheme))
                .font(.satoshiBold(16))
            }
            
            dailyChangeView(for: entry?.dailyLoserPie)
        }
    }
    
    @ViewBuilder
    private func dailyChangeView(for pie: Pie?) -> some View {
        let changePercent = entry?.dailyChangePercent(for: pie)
        let showDash = (changePercent?.isInfinite ?? true) || portfolioCoins.isEmpty
        let safeChange = changePercent?.isInfinite ?? false ? 0 : changePercent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol

        OverflowLayout(spacing: 4) {
            PriceChangeValueView(
                change: entry?.dailyChangeValue(for: pie),
                size: .small,
                hideData: false,
                accessibleTimeframe: "24 hour",
                isDownloading: entry == nil
            )
            .privacySensitive()

            ShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || changePercent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(14))
        }
    }
    
    private func coinImage(for pie: Pie?) -> UIImage {
        guard
            let imageURL = pie?.data?.image,
            let data = CoinImageCache.imageData(for: imageURL),
            let image = UIImage(data: data)
        else {
            return UIImage()
        }
        
        return image
    }
}
