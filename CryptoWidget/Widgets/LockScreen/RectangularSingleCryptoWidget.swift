//
//  RectangularSingleCryptoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-10.
//

import SwiftUI
import Charts
import WidgetKit

struct RectangularSingleCryptoWidget: View {
    @Environment(\.colorScheme) var scheme
    
    let data: Toplist?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        if let url = URL(string: data?.id == nil || data?.symbol == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")") {
            
            GeometryReader { reader in
                
                ZStack {
                    
                    AccessoryWidgetBackground()
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(data?.symbol?.uppercased() ?? "CNCR")
                            
                            Spacer(minLength: 0)
                            
                            Text(data?.current_price?.formatCurrency(threshold: .hundredThousand, currency: selectedCurrency ?? CurrencyModel(), maxDecimals: 4) ?? "$0.00")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 0)
                        
                        let firstChange = data?.price_change_percentage_24h_in_currency ?? 0
                        let decimals1 = abs(firstChange.roundTo(places: 2)) >= 100.0 ? 1 : 2
                        let firstDecimal = "%.\(decimals1)f"
                        let daily = "\(String(format: firstDecimal, firstChange))"
                        let symbol = firstChange < 0 ? "" : "+"
                        
                        let secondChange = data?.price_change_percentage_7d_in_currency ?? 0
                        let decimals2 = abs(secondChange.roundTo(places: 2)) >= 100.0 ? 1 : 2
                        let secondDecimal = "%.\(decimals2)f"
                        let weekly = "\(String(format: secondDecimal, secondChange))"
                        let symbol1 = secondChange < 0 ? "" : "+"
                        
                        let thirdChange = data?.price_change_percentage_30d_in_currency ?? 0
                        let decimals3 = abs(thirdChange.roundTo(places: 2)) >= 100.0 ? 1 : 2
                        let thirdDecimal = "%.\(decimals3)f"
                        let monthly = "\(String(format: thirdDecimal, thirdChange))"
                        let symbol2 = thirdChange < 0 ? "" : "+"
                        
                        HStack(spacing: 4) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("24h:")
                                    .frame(maxHeight: .infinity)
                                
                                Text("7d:")
                                    .frame(maxHeight: .infinity)
                                
                                Text("30d:")
                                    .frame(maxHeight: .infinity)
                            }
                            .font(.system(size: 10, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(symbol)\(daily)%")
                                    .frame(maxHeight: .infinity)
                                
                                Text("\(symbol1)\(weekly)%")
                                    .frame(maxHeight: .infinity)
                                
                                Text("\(symbol2)\(monthly)%")
                                    .frame(maxHeight: .infinity)
                            }
                            .font(.system(size: 10, weight: .medium))
                            
                            Spacer(minLength: 2)
                            
                            let prices = getPrices().enumerated().compactMap { index, element in index % 4 == 0 ? element : nil }.normalized
                            
                            Chart {
                                ForEach(prices.indices, id: \.self) { index in
                                    let point = prices[safely: index] ?? .zero
                                    
                                    LineMark(x: .value("", index), y: .value("", Double(point)))
                                        .lineStyle(.init(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                                        .foregroundStyle(Color.onSurface(for: scheme))
                                        .interpolationMethod(.catmullRom)
                                }
                                
                                ForEach(prices.indices, id: \.self) { index in
                                    let point = prices[safely: index] ?? .zero
                                    
                                    AreaMark(x: .value("", index), y: .value("", Double(point)))
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.onSurface(for: scheme).opacity(0.4), Color.onSurface(for: scheme).opacity(0.018)]),
                                                                        startPoint: .top,
                                                                        endPoint: .bottom))
                                }
                            }
                            .chartYAxis(.hidden)
                            .chartXAxis(.hidden)
                            .padding(.top, 4)
                            .padding(.bottom, 5)
                            .clipped()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(url)
        }
    }
    
    func getPrices() -> [Double] {
        return data?.sparkline_in_7d?.price ?? getRandomPoints()
    }
    
    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.0...1.0)
        
        for _ in (0..<168) {
            previousValue = Double.random(in: max(0.0, (previousValue - 0.01))...min((previousValue + 0.01), 1))
            pointsArray.append(previousValue)
        }
        
        return pointsArray
    }
}
