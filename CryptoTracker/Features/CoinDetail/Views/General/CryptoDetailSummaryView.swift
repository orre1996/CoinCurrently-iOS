//
//  CryptoDetailSummaryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/30/25.
//

import Foundation
import SwiftUI

struct CryptoDetailSummaryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var priceColor: Color = .onSurface
    @State private var priceFlashToken = 0
    
    let name: String?
    let currentPrice: Double?
    let imageUrl: String?
    var countryCode: String? = nil
    let prices: [Double]?
    let isSharing: Bool
    let image: UIImage?
    let selectedTimeframe: TimeCharts
    let shortPrice: Bool
    let shortChange: Bool
    var valueAccessibilityLabel: String = "current price"
    var changeMetricLabel: String = "price"
    var changeAccessibilityTimeframe: String? = nil
    var changeCoinAccessibilityHint: String? = nil
    var currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    var isWebSocketEnabled: Bool = false
    let changeCoin: () -> Void
    
    private var displayFormattingThreshold: FormattingThreshold {
        shortPrice ? .thousand : .none
    }
    
    private var accessibilityFormattingThreshold: FormattingThreshold {
        shortPrice || changeMetricLabel == "volume" ? .thousand : .none
    }
    
    private var accessibilityChangePeriod: String {
        switch selectedTimeframe {
        case .anHour:
            return "in the last hour"
        case .aDay:
            return "in the last 24 hours"
        case .aWeek:
            return "in the last 7 days"
        case .aMonth:
            return "in the last 30 days"
        case .threeMonths:
            return "in the last 3 months"
        case .aYear:
            return "in the last year"
        case .max:
            return "over all time"
        case .sixMonths:
            return "in the last 6 months"
        case .twoYears:
            return "in the last 2 years"
        }
    }
    
    private var accessibilityCountryText: String {
        guard let countryCode,
              let countryName = Locale.current.localizedString(forRegionCode: countryCode),
              !countryName.isEmpty else {
            return ""
        }
        return ". Country: \(countryName)"
    }
    
    private var accessibilityLabel: String {
        let name = name ?? "coin"
        let roundedChange = Double.getDifferenceInPercent(between: prices?.last, and: prices?.first)?.roundTo(places: 2) ?? 0
        let formattedChangePercent = roundedChange.numberAccessible(maxPlaces: 2)
        let changeDirection = roundedChange >= 0 ? "up" : "down"
        
        if changeMetricLabel == "volume" || changeMetricLabel == "holdings" || changeMetricLabel == "price" {
            let valueText = currentPrice?.formatCurrency(threshold: accessibilityFormattingThreshold, currency: currency, accessible: true) ?? ""
            let direction = AppCopy.string(roundedChange >= 0 ? "Up" : "Down")
            let period = AppCopy.string(accessibilityChangePeriod)
            let valueLabel = AppCopy.string(valueAccessibilityLabel)
            #if IS_APP
            let regionLocale = Localization.locale
            #else
            let regionLocale = Locale.current
            #endif
            
            if changeMetricLabel == "holdings",
               let countryCode,
               let countryName = regionLocale.localizedString(forRegionCode: countryCode),
               !countryName.isEmpty {
                return AppCopy.format(
                    "%1$@. %2$@. %3$@: %4$@. %5$@ %6$@ percent %7$@",
                    name,
                    AppCopy.format("Country: %@", countryName),
                    valueLabel,
                    valueText,
                    direction,
                    formattedChangePercent,
                    period
                )
            }
            
            return AppCopy.format(
                "%1$@, %2$@: %3$@. %4$@ %5$@ percent %6$@",
                name,
                valueLabel,
                valueText,
                direction,
                formattedChangePercent,
                period
            )
        }
        
        let currentPriceText = ", \(valueAccessibilityLabel): \(currentPrice?.formatCurrency(threshold: accessibilityFormattingThreshold, currency: currency, accessible: true) ?? "")."
        let timeframe = changeAccessibilityTimeframe ?? selectedTimeframe.accessibilityTimeframe
        
        return "\(name)\(accessibilityCountryText)\(currentPriceText) \(timeframe) \(changeMetricLabel). change: \(changeDirection) \(formattedChangePercent) percent"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    cryptoImage
                    
                    ShimmeringText(
                        text: name ?? "000000",
                        isDownloading: name == nil
                    )
                    .foregroundStyle(Color.onSurfaceDim)
                    .font(.satoshiBold(18))
                }
                
                priceView
                
                changeView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .if(changeCoinAccessibilityHint != nil) { view in
                view.accessibilityHint(AppCopy.string(changeCoinAccessibilityHint ?? ""))
            }
            .onTapGesture {
                changeCoin()
            }
            .onChange(of: currentPrice) { oldValue, newValue in
                flashPriceColor(from: oldValue, to: newValue)
            }
            .onChange(of: isWebSocketEnabled) { _, isEnabled in
                if !isEnabled {
                    priceFlashToken += 1
                    priceColor = .onSurface
                }
            }
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var cryptoImage: some View {
        if let countryCode, let flag = CountryFlagEmojis.flags[countryCode] {
            Text(flag)
                .font(.satoshiBold(20 * min(scale, 1.5)))
                .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                .accessibilityHidden(true)
        } else if isSharing {
            Image(uiImage: image ?? UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .frame(width: 20, height: 20)
        } else {
            ShimmeringImage(
                imageUrl: imageUrl,
                downloading: name == nil,
                size: 20 * min(scale, 1.5)
            )
            .accessibilityHidden(true)
        }
    }
    
    @ViewBuilder
    private var priceView: some View {
        let priceText = ShimmeringText(
            text: currentPrice?.formatCurrency(threshold: displayFormattingThreshold, currency: currency) ?? "000000000",
            isDownloading: currentPrice == nil,
            useNumericContentTransition: isWebSocketEnabled
        )
        .font(.satoshiBold(36))
        .foregroundStyle(isWebSocketEnabled ? priceColor : Color.onSurface)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        
        if isWebSocketEnabled {
            priceText.animation(.default, value: currentPrice ?? 0)
        } else {
            priceText
        }
    }
    
    private var isHorizontalChangeLayout: Bool {
        category.isAccessibilityCategory && verticalSizeClass == .regular
    }
    
    private var roundedChange: Double {
        Double.getDifferenceInPercent(between: prices?.last, and: prices?.first)?.roundTo(places: 2) ?? 0
    }
    
    private var formattedChange: String {
        roundedChange.formatted(
            shortChange || isHorizontalChangeLayout
                ? .number.notation(.compactName).precision(.fractionLength(2))
                : .number.precision(.fractionLength(2))
        ).changeWithSymbol
    }
    
    private var changeValue: Double {
        guard let first = prices?.first, let last = prices?.last else { return 0 }
        return last - first
    }
    
    @ViewBuilder
    private var changeValueLabel: some View {
        let label = PriceChangeValueView(
            change: changeValue,
            size: .extraSmall,
            formattingThreshold: shortChange || isHorizontalChangeLayout ? FormattingThreshold.thousand : FormattingThreshold.none,
            selectedCurrency: currency,
            useNumericContentTransition: isWebSocketEnabled,
            isDownloading: prices?.isEmpty ?? true
        )
        
        if isWebSocketEnabled {
            label.animation(.default, value: changeValue)
        } else {
            label
        }
    }
    
    @ViewBuilder
    private var changePercentLabel: some View {
        let label = ShimmeringText(
            text: "(\(formattedChange)%)",
            isDownloading: prices?.isEmpty ?? true,
            useNumericContentTransition: isWebSocketEnabled
        )
        .foregroundStyle(roundedChange.changeColor)
        .font(.satoshiBold(12))
        
        if isWebSocketEnabled {
            label.animation(.default, value: roundedChange)
        } else {
            label
        }
    }
    
    @ViewBuilder
    private var changeView: some View {
        OverflowLayout(spacing: 4) {
            changeValueLabel
            changePercentLabel
            
            Text(AppCopy.string(selectedTimeframe.timeAgoText))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
        }
    }
    
    private func flashPriceColor(from oldValue: Double?, to newValue: Double?) {
        guard isWebSocketEnabled,
              let oldValue,
              let newValue,
              oldValue != newValue else {
            return
        }
        
        let oldFormatted = oldValue.formatCurrency(threshold: FormattingThreshold.none, currency: currency)
        let newFormatted = newValue.formatCurrency(threshold: FormattingThreshold.none, currency: currency)
        guard oldFormatted != newFormatted else {
            return
        }
        
        priceColor = newValue > oldValue ? .trendUp : .trendDown
        priceFlashToken += 1
        let token = priceFlashToken
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard priceFlashToken == token else { return }
            priceColor = .onSurface
        }
    }
}
