//
//  CryptoDetailAlertCellView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 6/30/25.
//

import SwiftUI

struct CryptoDetailAlertCellView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    @ScaledMetric private var scale: CGFloat = 1
    
    let name: String?
    let symbol: String?
    let alert: AlertCoin?
    let index: Int
    let alertsCount: Int
    let deleteAlert: () -> Void
    
    private var accessibilityLabelText: String {
        guard let alert else {
            return "Price alert \(index + 1) of \(alertsCount)"
        }
        
        let currency = CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == alert.preferredCurrency }) ?? CurrencyModel()
        let recurringText = alert.isRecurringAlert ? "Recurring" : "One-time"
        let createdText = alert.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.alertTimeAgoDisplay ?? ""
        let directionText = alert.direction.rawValue
        let targetText = alert.targetPrice.currencyAccessible(currency: currency)
        
        return "Price alert \(index + 1) of \(alertsCount), \(name ?? ""), trigger when \(directionText) \(targetText), \(recurringText) alert, created \(createdText)"
    }
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                let currency = CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == alert?.preferredCurrency ?? "" }) ?? CurrencyModel()

                AdaptiveStack(isHorizontal: isHorizontal, spacing: 4, horizontalAlignment: .leading) {
                    if let symbol {
                        NewShimmeringText(
                            text: symbol.uppercased(),
                            isDownloading: alert == nil
                        )
                        .foregroundStyle(Color.primary)
                        .font(.satoshiBold(16))
                    }

                    if alert == nil {
                        NewShimmeringText(
                            text: "0000000",
                            isDownloading: alert == nil
                        )
                        .foregroundStyle(Color.onSurface)
                        .font(.satoshiBold(16))
                    } else {
                        Text("\(alert?.direction.rawValue.capitalized ?? "") ")
                            .foregroundStyle(Color.onSurface)
                            .font(.satoshiRegular(16))
                        
                        +
                        
                        Text(alert?.targetPrice.formatCurrency(threshold: FormattingThreshold.none, currency: currency) ?? "00000000")
                            .foregroundStyle(Color.onSurface)
                            .font(.satoshiBold(16))
                    }
                }
                
                let recurringText = alert?.isRecurringAlert ?? false ? "Recurring" : "One-time"
                
                NewShimmeringText(
                    text: "\(recurringText) · Created \(alert?.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.alertTimeAgoDisplay ?? "000")",
                    isDownloading: alert == nil
                )
                .foregroundStyle(Color.onSurfaceDimmer)
                .font(.satoshiBold(12))
            }
            
            Spacer(minLength: 8)
            
            if alert != nil {
                Button(action: {
                    deleteAlert()
                }, label: {
                    Image.delete
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .padding(16)
                        .foregroundStyle(Color.onSurfaceDimmer)
                })
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(alert != nil ? "Swipe down to delete." : "")
        .accessibilityAction(named: "Delete") {
            guard alert != nil else { return }
            deleteAlert()
        }
    }
}
