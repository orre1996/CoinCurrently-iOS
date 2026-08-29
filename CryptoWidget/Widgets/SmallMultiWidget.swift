//
//  SmallMultiWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-27.
//

import SwiftUI

struct SmallMultiWidget: View {
    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            
            MultiWidgetCell(data: data?.first, image: image?.first, selectedCurrency: selectedCurrency, hasPro: true)
                .padding(.top, 8)
                .padding(.bottom, 6)
            
            Separator()
            
            MultiWidgetCell(data: data?[safely: 1], image: image?[safely: 1], selectedCurrency: selectedCurrency, hasPro: true)
                .padding(.top, 6)
                .padding(.bottom, 4)
            
        }

    }
}

struct MultiWidgetCell: View {
    @Environment(\.colorScheme) var scheme

    let data: Toplist?
    let image: UIImage?
    let selectedCurrency: CurrencyModel?
    let hasPro: Bool
    
    let horizontalPadding: CGFloat = 12
    
    var body: some View {
        
        if let url = URL(string: hasPro ? data == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")" : "buyPro") {
            
            Link(destination: url) {
                
                GeometryReader { reader in
                    
                    VStack(alignment: .center, spacing: 0) {
                        
                        HStack(alignment: .top, spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 0) {
                                
                                Text(data?.name ?? "CoinCurrently")
                                    .font(.regularWidget14)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .minimumScaleFactor(0.7)
                                    .frame(height: reader.size.height / 3)
                                
                                coinPrice
                                    .frame(height: reader.size.height / 3)
                                
                            }
                            .foregroundColor(Color.onSurface(for: scheme))
                            
                            Spacer(minLength: 8)
                            
                            coinImage
                            
                        }
                        
                        HStack(alignment: .center, spacing: 0) {
                            Text("7d: ")
                                .font(.regularWidget12)
                                .foregroundStyle(Color.onSurface(for: scheme))
                            
                            NewPriceChangePercentView(
                                change: data?.price_change_percentage_7d_in_currency ?? 0,
                                size: .small,
                                accessibleTimeframe: "7 days",
                                isDownloading: false
                            )
                            
                            Spacer(minLength: 0)
                            
                            VStack {
                                
                                Spacer()
                                
                                NewChartView(
                                    prices: data?.sparkline_in_7d?.price ?? getRandomPoints(),
                                    color: data?.price_change_percentage_7d_in_currency?.changeColor(for: scheme),
                                )
                                .frame(width: 40, height: 13)
                                
                                Spacer()
                                
                            }
                            .frame(maxHeight: 15)
                            
                        }
                        .frame(height: reader.size.height / 3)
                        
                    }
                    .frame(maxHeight: reader.size.height)
                    
                }
                .padding(.horizontal, horizontalPadding)
                
            }
            .widgetURL(url)
            
        }
        
    }
    
    private var coinImage: some View {
        Image(uiImage: image ?? UIImage())
            .resizable()
            .widgetAccentedRenderingMode(.desaturated)
            .frame(width: 25, height: 25, alignment: .center)
            .scaledToFit()
            .cornerRadius(data?.name == nil ? 8 : 0)
    }
    
    private var coinPrice: some View {
        return Text("\(data?.current_price?.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency) ?? "$0.00")")
            .font(.regularWidget14)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
    
    func getPrices() -> [Double] {
        return []
        /*let tempPrices = getRandomPoints()
        
        let prices = priceVolume?.prices?.map {
            ($0.last ?? 0.0) ?? 0.0
        } ?? tempPrices
        
        return priceVolume?.prices == nil ? tempPrices : prices*/
    }
    
    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.0...1.0)
        
        for _ in (0..<80) {
            previousValue = Double.random(in: max(0.0, (previousValue - 0.01))...min((previousValue + 0.01), 1.0))
            pointsArray.append(previousValue)
        }
        
        return pointsArray.normalized
    }
    
}
