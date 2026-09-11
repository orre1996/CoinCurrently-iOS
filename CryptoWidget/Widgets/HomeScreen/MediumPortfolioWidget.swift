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
                    VStack(alignment: .leading, spacing: 4) {
                        portfolioValue
                        
                        Spacer(minLength: 12)
                        
                        dailyWinner
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(16)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        portfolioDailyChange
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
    
    private var portfolioValue: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Value")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            ShimmeringText(
                text: entry?.totalValue?.formatCurrency() ?? "000000",
                isDownloading: entry == nil
            )
            .foregroundStyle(Color.onSurface(for: scheme))
            .font(.satoshiBold(22))
            .privacySensitive()
        }
    }
    
    private var portfolioDailyChange: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("24h Change")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            changeView(
                value: entry?.portfolioDailyChangeValue,
                percent: entry?.portfolioDailyChangePercent
            )
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
        changeView(
            value: entry?.dailyChangeValue(for: pie),
            percent: entry?.dailyChangePercent(for: pie)
        )
    }
    
    @ViewBuilder
    private func changeView(value: Double?, percent: Double?) -> some View {
        let showDash = (percent?.isInfinite ?? true) || portfolioCoins.isEmpty
        let safeChange = percent?.isInfinite ?? false ? 0 : percent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol

        OverflowLayout(spacing: 4) {
            PriceChangeValueView(
                change: value,
                size: .small,
                hideData: false,
                accessibleTimeframe: "24 hour",
                isDownloading: entry == nil
            )
            .privacySensitive()

            ShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || percent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(14))
            .opacity(0.75)
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
