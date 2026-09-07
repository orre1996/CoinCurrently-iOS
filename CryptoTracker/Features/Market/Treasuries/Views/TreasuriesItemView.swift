//
//  TreasuriesItemView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/21/26.
//

import SwiftUI

struct TreasuriesItemView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let data: PublicTreasuryHolder?
    let entity: TreasuryEntity?
    let coinSymbol: String?
    var priceMultiplier: Double? = nil
    var listIndex: Int? = nil
    var listCount: Int? = nil
    let handleTreasuryClick: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                AdaptiveStack(
                    isHorizontal: isHorizontal,
                    spacing: isHorizontal ? 4 : 0,
                    horizontalAlignment: .leading,
                    verticalAlignment: .center
                ) {
                    countryFlag
                    
                    exchangeName
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            holdingsView
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap for \(data?.name ?? "") details")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            handleTreasuryClick()
        }
    }
    
    private var accessibilityLabelText: String {
        guard data != nil else { return "Loading treasury" }
        
        var components: [String] = []
        
        if let listIndex, let listCount {
            components.append("Treasury \(listIndex + 1) of \(listCount), \(data?.name ?? "")")
        } else {
            components.append(data?.name ?? "")
        }
        
        if let entity {
            components.append(entity.displayName)
        }
        
        if let country = data?.country,
           let countryName = Locale.current.localizedString(forRegionCode: country),
           !countryName.isEmpty {
            components.append("Country: \(countryName)")
        }
        
        let holdings = data?.total_holdings ?? 0
        components.append(
            "Holdings: \(holdings.formatCurrency(threshold: FormattingThreshold.none, currency: accessibleHoldingsCurrency(), accessible: true))"
        )
        
        if let priceMultiplier {
            let convertedValue = (data?.total_current_value_usd ?? 0) * priceMultiplier
            components.append(
                "Current value: \(convertedValue.formatCurrency(threshold: FormattingThreshold.none, accessible: true))"
            )
        }
        
        return components.joined(separator: ". ")
    }
    
    private func accessibleHoldingsCurrency() -> CurrencyModel {
        if let symbol = coinSymbol?.uppercased(),
           let knownCurrency = CurrencyModel.allCurrencies.first(where: { $0.code == symbol }) {
            return knownCurrency
        }
        
        if let symbol = coinSymbol?.trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            let spelledSymbol = symbol.uppercased().map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol.uppercased(),
                symbol: symbol.uppercased(),
                locale: "en_US",
                suffix: true
            )
        }
        
        return holdingsCurrency
    }
    
    @ViewBuilder
    private var countryFlag: some View {
        if let country = data?.country, let flag = CountryFlagEmojis.flags[country] {
            Text(flag)
                .font(.satoshiBold(16))
                .accessibilityHidden(true)
        } else {
            ShimmeringText(
                text: data?.country ?? "00000",
                isDownloading: data?.name == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            .accessibilityHidden(true)
        }
    }

    private var exchangeName: some View {
        ShimmeringText(
            text: data?.name ?? "00000",
            isDownloading: data?.name == nil
        )
        .frame(minWidth: 80, alignment: .leading)
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var holdingsView: some View {
        VStack(alignment: isHorizontal ? .trailing : .leading, spacing: 0) {
            ShimmeringText(
                text: holdingsText,
                isDownloading: data == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)

            ShimmeringText(
                text: holdingsTextFiat,
                isDownloading: data == nil || priceMultiplier == nil
            )
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDim)
        }
        .multilineTextAlignment(isHorizontal ? .trailing : .leading)
        .accessibilityHidden(true)
        .layoutPriority(1)
    }

    private var holdingsText: String {
        guard let data else {
            return 8_437_380.0.formatCurrency(threshold: .million, currency: holdingsCurrency)
        }

        return (data.total_holdings ?? 0).formatCurrency(
            threshold: FormattingThreshold.none,
            currency: holdingsCurrency
        )
    }
    
    private var holdingsTextFiat: String {
        guard let data else {
            return 55_576_689_193.0.formatCurrency(threshold: .million)
        }

        return ((data.total_current_value_usd ?? 0) * (priceMultiplier ?? 0)).formatCurrency(
            threshold: FormattingThreshold.none
        )
    }

    private var holdingsCurrency: CurrencyModel {
        CurrencyModel(
            currency: "",
            code: "",
            symbol: coinSymbol?.uppercased() ?? "BTC",
            locale: "en_US",
            suffix: true
        )
    }
}

