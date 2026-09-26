//
//  BigWidget.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-26.
//

import SwiftUI

struct LargeCryptoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: Toplist?
    let image: UIImage?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        let price = data
        
        if let url = URL(string: data?.id ?? .appName) {
            
            Link(destination: url) {
                
                GeometryReader { reader in
                    
                    VStack(alignment: .center, spacing: 0, content: {
                        
                        HStack(alignment: .center, spacing: 0, content: {
                            
                            coinImage
                                .padding(.trailing, 8)
                            
                            coinInfo
                            
                            Spacer()
                            
                            coinPrice
                                .padding(.leading, 8)
                            
                        })
                        .minimumScaleFactor(0.7)
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        
                        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
                            
                            WidgetChartBackground()
                            
                            PriceLineChartView(
                                prices: data?.sparkline_in_7d?.price ?? getRandomPoints(),
                                color: data?.price_change_percentage_7d_in_currency?.changeColor(for: scheme),
                                lineWidth: 2
                            )
                            .padding(.vertical, 12)
                            
                            VStack(alignment: .leading, spacing: 0, content: {
                                
                                Spacer()
                                
                                ForEach(1..<4) { index in
                                    
                                    ZStack {
                                        
                                        Text(getPriceInChart(at: 4 - index))
                                            .frame(height: 20, alignment: .leading)
                                            .padding(3)
                                            .foregroundStyle(Color.onSurface(for: scheme))
                                            .font(.regularWidget14)
                                        
                                    }
                                    .background(.tertiary.opacity(0.8))
                                    .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                }
                            })
                            .frame(maxWidth: reader.size.width, alignment: .leading)
                            .padding(EdgeInsets(top: 8, leading: 13, bottom: 19, trailing: 0))
                        }
                        .padding(.top, 8)
                        
                        HStack(alignment: .center, spacing: 0) {
                            
                            Spacer()
                            
                            ForEach(1...3, id: \.self) { index in
                                VStack(spacing: 0) {
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
                        
                        HStack(alignment: .center, spacing: 0, content: {
                            
                            HStack {
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    
                                    Spacer()
                                    
                                    Text("Open")
                                        .frame(height: 20)
                                    
                                    Text("High")
                                        .frame(height: 20)
                                    
                                    Text("Low")
                                        .frame(height: 20)
                                    
                                    Spacer()
                                    
                                }
                                .foregroundColor(Color.onSurface(for: scheme))
                                .padding(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 8))
                                .frame(height: reader.size.height / 3.8)
                                
                                Spacer()
                                
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    
                                    Spacer()
                                    
                                    Text(Double(getOpenPrice()).formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel()))
                                        .frame(height: 20, alignment: .trailing)
                                    
                                    Text("\(getHighestPrice().formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel()))")
                                        .frame(height: 20, alignment: .trailing)
                                    
                                    Text("\(getLowestPrice().formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel()))")
                                        .frame(height: 20, alignment: .trailing)
                                    
                                    Spacer()
                                    
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 8))
                                .frame(height: reader.size.height / 4, alignment: .trailing)
                                
                            }
                            
                            Rectangle()
                                .frame(width: 1, height: 75, alignment: .center)
                                .foregroundStyle(.tertiary)
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                            
                            HStack {
                                
                                VStack(alignment: .leading, spacing: 8, content: {
                                    
                                    Spacer()
                                    
                                    Text("Volume")
                                        .frame(height: 20)
                                    
                                    Text("Mkt Cap")
                                        .frame(height: 20)
                                    
                                    Text("Change")
                                        .frame(height: 20)
                                    
                                    Spacer()
                                    
                                })
                                .foregroundColor(Color.onSurface(for: scheme))
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 4, trailing: 8))
                                .frame(height: reader.size.height / 4)
                                
                                Spacer()
                                
                                
                                VStack(alignment: .trailing, spacing: 8, content: {
                                    
                                    Spacer()
                                    
                                    Text(price?.total_volume?.formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel()) ?? "$0.00")
                                        .frame(height: 20)
                                    
                                    Text("\(price?.market_cap?.formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel()) ?? "$0.00")")
                                        .frame(height: 20)
                                    
                                    Text("\((price?.price_change_percentage_7d_in_currency ?? 0.0).getPriceWithSymbol(currentPrice: price?.current_price ?? 0.0, showSign: true) )%")
                                        .frame(height: 20)
                                    
                                    Spacer()
                                    
                                })
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 16))
                                .frame(height: reader.size.height / 4)
                            }
                        })
                        .font(.mediumWidget14)
                        .foregroundColor(Color.onSurface(for: scheme))
                        .padding(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
                    })
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(Color.onSurface(for: scheme))
                    
                }
            }
        }
    }
    
    private var coinImage: some View {
        Image(uiImage: image ?? UIImage())
            .resizable()
            .widgetAccentedRenderingMode(.desaturated)
            .frame(width: 30, height: 30, alignment: .center)
            .scaledToFit()
            .cornerRadius(data?.name == nil ? 8 : 0)
    }
    
    private var coinInfo: some View {
        Text(data?.name == nil ? .appName : "\((data?.name ?? "").capitalized)")
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .font(.regularWidget18)
            .foregroundColor(Color.onSurface(for: scheme))
    }
    
    private var coinPrice: some View {
        let price = data
        
        return Text("\((price?.current_price ?? 0.0).formatCurrency(threshold: .none, currency: selectedCurrency ?? CurrencyModel()))")
            .foregroundColor(Color.onSurface(for: scheme))
            .font(.regularWidget18)
            .lineLimit(1)
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
    }
    
    func getPriceInChart(at: Int) -> String {
        let lowest = getLowestPrice()
        let priceSteps = (getHighestPrice() - getLowestPrice()) / 4
        return Double(lowest + (priceSteps * Double(at))).formatCurrency(
            threshold: .none,
            currency: selectedCurrency ?? CurrencyModel()
        )
    }
    
    func getHighestPrice() -> Double {
        guard let prices = data?.sparkline_in_7d?.price else { return 0.0 }
        return prices.max() ?? 0
    }
    
    func getLowestPrice() -> Double {
        guard let prices = data?.sparkline_in_7d?.price else { return 0.0 }
        return prices.min() ?? 0
    }

    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.1...0.9)
        
        for _ in (0..<168) {
            previousValue = Double.random(in: max(0.1, (previousValue - 0.01))...min((previousValue + 0.01), 0.9))
            pointsArray.append(previousValue)
        }
        
        return pointsArray
    }
    
    func getOpenPrice() -> CGFloat {
        return CGFloat(data?.sparkline_in_7d?.price.first ?? 0)
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
}
