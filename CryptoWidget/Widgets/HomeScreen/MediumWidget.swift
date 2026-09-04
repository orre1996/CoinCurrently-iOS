//
//  MediumWidget.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-24.
//

import SwiftUI

struct MediumCryptoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: Toplist?
    let image: UIImage?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        if let url = URL(string: data?.id == nil || data?.symbol == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")" ) {
            
            Link(destination: url) {
                
                VStack(alignment: .center, spacing: 0, content: {
                    
                    HStack(alignment: .center, spacing: 0, content: {
                        
                        coinImage
                            .padding(.trailing, 8)
                        
                        coinInfo
                        
                        Spacer()
                        
                        coinPrice
                            .padding(.leading, 8)
                        
                    })
                    .lineLimit(1)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
                    
                    Spacer()
                    
                    NewChartView(
                        prices: data?.sparkline_in_7d?.price ?? getRandomPoints(),
                        color: data?.price_change_percentage_7d_in_currency?.changeColor(for: scheme),
                        lineWidth: 2
                    )
                    
                    Spacer()
                    
                    priceChangeViews
                })
                
                .foregroundStyle(Color.onSurface(for: scheme))
            }
            .widgetURL(url)
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
            .minimumScaleFactor(0.7)
            .font(.regularWidget18)
            .foregroundStyle(Color.onSurface(for: scheme))
    }
    
    private var coinPrice: some View {
        return Text("\(data?.current_price?.formatCurrency(threshold: .none, currency: selectedCurrency ?? CurrencyModel()) ?? "$0.00")")
            .font(.regularWidget18)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color.onSurface(for: scheme))
    }
    
    private var priceChangeViews: some View {
        HStack(spacing: 8) {
            
            HStack(spacing: 4) {
                Text("24h:")
                    .font(.regularWidget12)
                    .foregroundStyle(Color.onSurface(for: scheme))
                    
                NewPriceChangePercentView(
                    change: data?.price_change_percentage_24h_in_currency,
                    size: .small,
                    accessibleTimeframe: "24 hour",
                    isDownloading: false
                )
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("7d:")
                    .font(.regularWidget12)
                    .foregroundStyle(Color.onSurface(for: scheme))
                
                NewPriceChangePercentView(
                    change: data?.price_change_percentage_7d_in_currency,
                    size: .small,
                    accessibleTimeframe: "7 days",
                    isDownloading: false
                )
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("30d:")
                    .font(.regularWidget12)
                    .foregroundStyle(Color.onSurface(for: scheme))
                
                NewPriceChangePercentView(
                    change: data?.price_change_percentage_30d_in_currency,
                    size: .small,
                    accessibleTimeframe: "30 days",
                    isDownloading: false
                )
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .minimumScaleFactor(0.7)
        .frame(height: 28)
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
