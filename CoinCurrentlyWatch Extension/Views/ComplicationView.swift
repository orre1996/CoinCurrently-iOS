//
//  ComplicationView.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-27.
//

import SwiftUI
import ClockKit

struct ComplicationView: View {
    
    var currentCurrency: CurrencyDataModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 4) {
                Text(currentCurrency?.symbol?.uppercased() ?? "CoinCurrently")
                    .font(.satoshiBold(12))
                    .truncationMode(.tail)
                
                Text(currentCurrency?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                    .font(.satoshiBold(12))
                
                PriceChangePercentView(
                    change: currentCurrency?.market_data?.price_change_percentage_7d,
                    size: .small,
                    accessibleTimeframe: "7 days",
                    isDownloading: false
                )
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    
            PriceLineChartView(
                prices: currentCurrency?.market_data?.sparkline_7d?.price ?? getRandomPoints(),
                color: currentCurrency?.market_data?.price_change_percentage_7d?.changeColor,
                lineWidth: 1
            )
            .frame(maxWidth: .infinity)
            
            chartTimes
        }
        .edgesIgnoringSafeArea([.top, .bottom])
        .foregroundStyle(Color.onSurface)
    }
    
    @ViewBuilder
    private var highsAndLows: some View {
        let prices = currentCurrency?.market_data?.sparkline_7d?.price
        
        HStack(spacing: 0) {
            Image.trendDown
                .resizable()
                .frame(width: 10, height: 10)

            ShimmeringText(
                text: prices?.min()?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000",
                isDownloading: prices?.isEmpty ?? true
            )
            .padding(.horizontal, 4)
            
            Spacer(minLength: 0)
            
            Image.trendUp
                .resizable()
                .frame(width: 10, height: 10)
                .padding(.horizontal, 4)
            
            ShimmeringText(
                text: prices?.max()?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000",
                isDownloading: prices?.isEmpty ?? true
            )
        }
        .font(.satoshiRegular(12))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
    
    private var chartTimes: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)
            
            ForEach((1...3), id: \.self) {
                ShimmeringText(
                    text: getTimeInChart(at: $0),
                    isDownloading: currentCurrency == nil
                )
                .font(.satoshiMedium(12))
                .foregroundColor(.onSurface)
                
                Spacer(minLength: 0)
            }
        }
    }
    
    private func getTimeInChart(at index: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM dd"

        // 4 labels across 7 days → every ~2 days
        // index: 0,1,2,3 → daysBack: 6,4,2,0
        let daysBack = max(0, 6 - (index * 2))

        let date = Calendar.current.date(
            byAdding: .day,
            value: -daysBack - 1,
            to: Date()
        ) ?? Date()

        return formatter.string(from: date)
    }
    
    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.1...0.9)
        
        for _ in (0..<168) {
            previousValue = CGFloat.random(in: max(0.1, (previousValue - 0.01))...min((previousValue + 0.01), 0.9))
            pointsArray.append(previousValue)
        }
        
        return pointsArray
    }
}
