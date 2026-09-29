//
//  PriceAlertGroupView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-23.
//

import SwiftUI

struct PriceAlertGroupView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) var category

    @ScaledMetric private var scale: CGFloat = 1

    let coin: Toplist?
    let alerts: [AlertCoin]
    let prices: [Cryptocurrency]
    let index: Int
    
    let addNewPriceAlert: (Toplist) -> Void
    let deleteAlert: (AlertCoin) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ShimmeringImage(
                    imageUrl: coin?.image,
                    downloading: coin == nil,
                    size: 32 * min(scale, 1.5)
                )
                .accessibilityHidden(true)
                
               // let currency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
               // let price = prices.first(where: { $0.id == coin?.id ?? "-1"})?.prices[currency.code.lowercased()]
               // let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

                /*AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                    ShimmeringText(text: "\(coin?.name ?? "-") (\(coin?.symbol?.uppercased() ?? ""))", font: .poppinsRegular(16), color: .onSurface, downloading: coin == nil)
                        .frame(minHeight: 32 * min(scale, 1.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Currency \(index + 1) of \(totalGroupsCount). \(coin?.name ?? "")")
                    
                    ShimmeringText(text: "\(price?.formatted(style: .exact(currency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel())) ?? "$0.00000")", font: .poppinsRegular(16), color: .onSurface, downloading: coin == nil)
                        .frame(minHeight: 32 * min(scale, 1.5))
                        .accessibilityLabel("Current price: \(price?.currencyAccessible(currency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()) ?? "$0.00")")
                }*/
            }
            .padding(16)
            
            Separator()
                .opacity(max(0.6, getSeparatorOpacity(currentCoin: coin)))
                .padding(EdgeInsets(top: 0, leading: 1, bottom: 8, trailing: 1))
            
            ForEach(0..<alerts.count, id: \.self) { index in
                let alert = alerts[safely: index]
                
                PriceAlertView(alert: alert,
                               index: index + 1,
                               alertsCount: alerts.count,
                               editAlert: { alert in
                    //editAlert(alert)
                }, deleteAlert: { alert in
                    deleteAlert(alert)
                })

                let first = Double(1.0 / Double(alerts.count))
                let second = (alerts.count) - 2 - index

                Separator()
                    .opacity(max(0.15, CGFloat(first * Double(second))))
                    .padding(EdgeInsets(top: 8, leading: 1, bottom: 8, trailing: 1))
            }
            
            Button(action: {
                guard let coin = coin else { return }

                addNewPriceAlert(coin)
            }) {
                Text(coin == nil ? Localization.string("+ Add new alert") : Localization.format("+ Add new %@ alert", coin?.name ?? ""))
                    .font(.poppinsRegular(14))
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 16, trailing: 0))
            .accessibilityLabel(Localization.format("Add new %@ price alert", coin?.name ?? ""))
        }
        .frame(maxWidth: .infinity)
        //.background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
               // .stroke(LinearGradient(colors: [Color.borderColor, Color.borderColor.opacity(0)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                .padding(0.5)
        )
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .accessibilityElement(children: .contain)
    }

    private func getSeparatorOpacity(currentCoin: Toplist?) -> CGFloat {
        let first = Double(1.0 / Double(alerts.count))
        let second = alerts.count - 1
        return CGFloat(first * Double(second))
    }
}
