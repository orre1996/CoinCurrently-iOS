//
//  PriceAlertView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-23.
//

import SwiftUI

struct PriceAlertView: View {
    @ScaledMetric private var scale: CGFloat = 1

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let alert: AlertCoin?
    let index: Int
    let alertsCount: Int
    let editAlert: (AlertCoin) -> Void
    let deleteAlert: (AlertCoin) -> Void
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        HStack(spacing: 8) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 0 : 8, horizontalAlignment: .leading) {
                HStack(spacing: 8) {
                    ScaledBezier (bezierPath: alert?.direction == .above ? .priceUpTriangle : .priceDownTriangle )
                        .fill(alert?.direction == .above ? Color.trendUp : Color.trendDown)
                        .frame(width: 16 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                        .padding(.bottom, 1)
                    
                    Text(Localization.string(alert?.direction == .above ? "Above:" : "Below:"))
                        .font(.poppinsRegular(14))
                        .foregroundColor(.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                /*Text("\(alert?.targetPrice?.formatted(style: .exact(currency: getCurrencyModel(currencyCode: alert?.currency ?? "USD"))) ?? (0.0).formatted(style: .exact(currency: getCurrencyModel(currencyCode: alert?.currency ?? "USD"))))")
                    .font(.poppinsRegular(14))
                    .foregroundColor(.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
                    .fixedSize(horizontal: false, vertical: true)*/
            }
            .accessibilityElement(children: .combine)
            //.accessibilityLabel("Price alert \(index + 1) out of \(alertsCount): target: \(alert?.aboveOrBelow == .above ? "above" : "below")  \(alert?.targetPrice?.currencyAccessible(currency: getCurrencyModel(currencyCode: alert?.currency ?? "USD")) ?? "$0.00")")
            
            HStack(spacing: 8) {
                Button(action: {
                    if let alert {
                        editAlert(alert)
                    }
                }, label: {
                    Image(systemName: "pencil")
                        .resizable()
                        .padding(4)
                        .foregroundColor(.onSurface)
                })
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                .accessibilityLabel(Localization.string("Edit price alert"))
                
                Button(action: {
                    if let alert {
                        deleteAlert(alert)
                    }
                }, label: {
                    Image(systemName: "trash.fill")
                        .resizable()
                        .padding(4)
                        .foregroundColor(.onSurface)
                })
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                .padding(.leading, 4)
                .accessibilityLabel(Localization.string("Delete price alert"))
            }
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 12))
    }

    func getCurrencyModel(currencyCode: String?) -> CurrencyModel {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

        return CurrencyModel.allCurrencies.filter({ $0.code == currencyCode }).first ?? selectedCurrency
    }
}
