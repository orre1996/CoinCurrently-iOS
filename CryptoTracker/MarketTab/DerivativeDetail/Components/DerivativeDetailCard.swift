//
//  DerivativeDetailCard.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-27.
//

import SwiftUI

struct DerivativeDetailCard: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.openURL) private var openURL
    
    @ScaledMetric private var scale: CGFloat = 1

    @Environment(\.sizeCategory) var category

    var derivative: DerivativeDetail? = nil
    var priceMultiplier: Double?
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        ZStack {
            AdaptiveButton(buttonAction: {
                
            }) {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.0001))
            
            VStack(spacing: 8) {
                
                Separator()
                    .opacity(0.5)
                    .padding(.horizontal, 1)
                    .padding(.bottom, 6)
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                    
                    Text("Ticker pair")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(derivative?.base ?? "")/\(derivative?.target ?? "")")
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("\(derivative?.base?.map({ "\($0) "}).joined() ?? "")/\(derivative?.target?.map({ "\($0) "}).joined() ?? "")")
                    
                }
                .padding(.horizontal, 16)
                .padding(.bottom, !isHorizontal ? 8 : 0)
                .accessibilityElement(children: .combine)
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                    
                    Text("24h volume")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("24 hour volume:")
                    
                    Text((Double(derivative?.converted_volume?.usd ?? "0.0"))?.getFormattedString(dontShort: true, selectedCurrency: CurrencyModel()) ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(isHorizontal ? .trailing : .leading)
                        .accessibilityLabel(Double(derivative?.converted_volume?.usd ?? "0.0")?.currencyAccessible(currency: CurrencyModel()) ?? "")
                    
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isHorizontal ? 0 : 8)
                .accessibilityElement(children: .combine)
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                    
                    Text("24h change")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("24 hour change:")
                    
                    let change = derivative?.h24_percentage_change ?? 0.0
                    let inValue = !(SettingsManager.shared.get(key: GlobalSettingKey.changesInPercent) ?? true)
                    let changeDirection = change > 0 ? "up" : "down"
                    let changePercent = "24 hour price change: \(changeDirection) \(change.numberAccessible()) percent"
                    
                    let previousValue = (Double(derivative?.converted_volume?.usd ?? "0.0") ?? 0) / ((change / 100) + 1)
                    let tempChange = (Double(derivative?.converted_volume?.usd ?? "0.0") ?? 0) - previousValue
                    let valueChange = "\(tempChange > 0 ? "up" : "down") \(tempChange.currencyAccessible(currency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()))"
                    
                    HStack(spacing: 0) {
                        
                        Text("\(derivative?.h24_percentage_change?.getPriceWithSymbol(currentPrice: Double(derivative?.converted_volume?.usd ?? "0.0")) ?? "0.0")\((SettingsManager.shared.get(key: GlobalSettingKey.changesInPercent) ?? true) ? "%" : "")")
                           // .foregroundColor(derivative?.h24_percentage_change?.getPriceChangeColor(currentPrice: Double(derivative?.converted_volume?.usd ?? "0.0")))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        ScaledBezier(bezierPath: derivative?.h24_percentage_change?.getPriceDirectionShape(currentPrice: Double(derivative?.converted_volume?.usd ?? "0.0")) ?? UIBezierPath.priceStillTriangle )
                           // .fill(derivative?.h24_percentage_change?.getPriceChangeColor(currentPrice: Double(derivative?.converted_volume?.usd ?? "0.0")) ?? Color.onSurfaceDim)
                            .frame(width: 12 * min(scale, 1.5), height: 8 * min(scale, 1.5))
                            .padding(.leading, 3)
                        
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(inValue ? valueChange : changePercent)
                    
                    
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isHorizontal ? 0 : 8)
                .accessibilityElement(children: .combine)
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                    
                    Text("Last price")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Last price:")

                    Text((Double(derivative?.converted_last?.usd ?? "0.0"))?.getFormattedString(dontShort: true, selectedCurrency: CurrencyModel()) ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(Double(derivative?.converted_last?.usd ?? "0.0")?.currencyAccessible(currency: CurrencyModel()) ?? "")
                    
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isHorizontal ? 0 : 8)
                .accessibilityElement(children: .combine)
                
                Button(action: {
                    guard let urlString = derivative?.trade_url,
                          !urlString.isEmpty, let url = URL(string: urlString) else {
                        return
                    }
                    
                    openURL(url)
                }) {
                    HStack(spacing: 8) {
                        Image.external
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                           // .foregroundColor(.buttonTextColor)
                        
                        Text("View exchange")
                           // .foregroundColor(.buttonTextColor)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(minWidth: 100)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .font(.poppinsRegular(16))
                    .padding(.horizontal, 16)
                    //.background(Color.buttonBackgroundColor.gradient)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .accessibilityLabel("View exchange")
            }
            .font(.poppinsRegular(16))
        }
    }
}
