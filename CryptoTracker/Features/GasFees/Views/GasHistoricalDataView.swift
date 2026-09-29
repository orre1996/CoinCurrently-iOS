//
//  EstimateGasFeeCost.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/28/25.
//

import SwiftUI

struct GasHistoricalDataView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let prices: [Double]
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(spacing: 16) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                gasFeeCostView(
                    title: "Today",
                    value: prices[safely: 0]
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                gasFeeCostView(
                    title: "Yesterday",
                    value: prices[safely: 1]
                )
            }
            
            Separator()
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                gasFeeCostView(
                    title: "Last Week",
                    value: prices[safely: 6]
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                gasFeeCostView(
                    title: "Last Month",
                    value: prices[safely: 30]
                )
            }
        }
        .cardBackground()
    }
    
    private func gasFeeCostView(
        title: String,
        value: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let currentStatus = getGasIndexString(indexValue: "\(value ?? 0)")

            Text(Localization.string(title))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityLabel(Localization.format("Estimated cost %@", Localization.string(title)))
                .padding(.bottom, 4)
            
            ShimmeringText(
                text: "\(value?.formatCurrency(currency: CurrencyModel.empty, minDecimals: 3, maxDecimals: 3) ?? " ") \(Localization.string("Gwei"))",
                isDownloading: value == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            
            ShimmeringText(
                text: Localization.string(currentStatus),
                isDownloading: value == nil
            )
            .font(.satoshiBold(12))
            .foregroundStyle(getGasIndexColor(indexValue: "\(value ?? 0)"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
