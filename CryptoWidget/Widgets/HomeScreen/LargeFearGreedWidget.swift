//
//  LargeFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-28.
//

import SwiftUI

struct LargeFearGreedWidget: View {
    @Environment(\.colorScheme) var scheme

    let fearGreedModel: FearGreed?
    let hasBoughtPro: Bool
    
    var prices: [Double] {
        var prices = Array(fearGreedModel?.data?[0...29] ?? []).reversed().map({ Double(Int($0.value ?? "0") ?? 0) })
        
        if prices.isEmpty {
            return getRandomPoints()
        }
        
        prices += [0, 100]
        return prices
    }
    
    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.1...0.9)
        
        for _ in (0..<30) {
            previousValue = Double.random(in: max(0.1, (previousValue - 0.01))...min((previousValue + 0.01), 0.9))
            pointsArray.append(previousValue)
        }
        
        return pointsArray
    }
    
    var timeStamps: [Double] {
        let timeStamps = Array(fearGreedModel?.data?[0...29] ?? []).reversed().map({ Double((Int($0.timestamp ?? "0") ?? 0) * 1000) })
        
        if timeStamps.isEmpty {
            return []
        }

        return timeStamps
    }
    
    var body: some View {
        if let url = URL(string: hasBoughtPro ? "fearGreed" : "buyPro") {
            
            Link(destination: url) {
                
                GeometryReader { reader in
                    
                    VStack(spacing: 0) {
                        
                        ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                            
                            WidgetChartBackground()
                            
                            PriceLineChartView(
                                prices: prices,
                                color: fearGreedModel?.data?.isEmpty ?? true ? Color.onSurfaceDim(for: scheme) : getIndexColor(
                                    indexValue: fearGreedModel?.data?.first?.value ?? "0",
                                    for: scheme
                                ),
                                lineWidth: 2,
                                dropCount: 2
                            )

                            VStack(alignment: .leading, spacing: 0) {
                                
                                Spacer()
                                
                                ForEach(["75", "50", "25"], id: \.self) { value in
                                    
                                    ZStack {
                                        
                                        Text(value)
                                            .frame(height: 20, alignment: .leading)
                                            .padding(3)
                                            .foregroundColor(Color.onSurface(for: scheme))
                                            .font(.regularWidget14)
                                        
                                    }
                                    .background(.tertiary.opacity(0.8))
                                    .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                }
                            }
                            .padding(EdgeInsets(top: 8, leading: 13, bottom: 19, trailing: 0))
                            
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: reader.size.height / 2, alignment: .center)
                        
                        HStack(alignment: .center, spacing: 0) {
                            
                            Spacer()
                            
                            ForEach(1...3, id: \.self) { index in
                                VStack(spacing: 2) {
                                    Rectangle()
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 1.1, height: 6)

                                    Text(getTimeInChart(at: index))
                                        .foregroundColor(Color.onSurface(for: scheme).opacity(0.6))
                                        .font(.regularWidget12)
                                        .frame(minWidth: 40)
                                        .padding(.top, -1)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Separator()
                            .padding(.top, 16)
                        
                        VStack(spacing: 0) {
                            
                            HStack(spacing: 0) {
                                
                                FearSquare(indexValue: fearGreedModel?.data?.first?.value,
                                           timeFrame: "Now",
                                           status: fearGreedModel?.data?.first?.value_classification)
                                .frame(maxHeight: .infinity)
                                
                                Rectangle()
                                    .frame(minWidth: 1, maxWidth: 1, minHeight: 0, maxHeight: .infinity, alignment: .center)
                                    .foregroundStyle(.tertiary)
                                
                                FearSquare(indexValue: fearGreedModel?.data?[safely: 1]?.value,
                                           timeFrame: "Yesterday",
                                           status: fearGreedModel?.data?[safely: 1]?.value_classification)
                                .frame(maxHeight: .infinity)
                                
                            }
                            .frame(maxWidth: .infinity)
                            
                            Separator()
                            
                            HStack(spacing: 0) {
                                
                                FearSquare(indexValue: fearGreedModel?.data?[safely: 7]?.value,
                                           timeFrame: "Last week",
                                           status: fearGreedModel?.data?[safely: 7]?.value_classification)
                                .frame(maxHeight: .infinity)
                                
                                Rectangle()
                                    .frame(minWidth: 1, maxWidth: 1, minHeight: 0, maxHeight: .infinity, alignment: .center)
                                    .foregroundStyle(.tertiary)
                                
                                FearSquare(indexValue: fearGreedModel?.data?[safely: 30]?.value,
                                           timeFrame: "Last month",
                                           status: fearGreedModel?.data?[safely: 30]?.value_classification)
                                .frame(maxHeight: .infinity)
                                
                            }
                            .frame(maxWidth: .infinity)
                            
                        }
                    }
                }
                .overlay {
                    if !hasBoughtPro {
                        WidgetBuyProOverlay()
                    }
                }
            }
        }
    }

    private func getTimeInChart(at: Int) -> String {
        let format = "MMM dd"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        
        let mainTimeStamp = timeStamps
        let currentTimeStamp: Double
        let timeStampCount = mainTimeStamp.count
        if timeStampCount == 0 { return dateFormatter.string(from: Date()) }
        
        let steps: Double = 1/4
        let at = Double(at)
        
        currentTimeStamp = mainTimeStamp[safely: Int(Double(timeStampCount) * steps * at)] ?? 0
        
        let date2 = Date(timeIntervalSince1970: (currentTimeStamp) / 1000).nearestHour
        
        let date = dateFormatter.string(from: date2)
        
        return date
    }
}
