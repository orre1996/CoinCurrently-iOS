//
//  FearGreedHistoricView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/7/25.
//

import SwiftUI

struct GasFeesHistoricView: View {
    let timeframe: String
    let indexValue: String?
    let status: String?
    
    var body: some View {
        let roundedChange = Double(indexValue ?? "0")?.roundTo(places: 3) ?? 0
        
        VStack(spacing: 0) {
            MinimumTextSize(
                text: Localization.string("Current Average"),
                alignment: .top,
            ) {
                Text(Localization.string(timeframe))
            }
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDimmer)
            .padding(.bottom, 4)
            
            ShimmeringText(
                text: roundedChange.formatCurrency(
                    currency: CurrencyModel.empty,
                    minDecimals: 3,
                    maxDecimals: 3
                ),
                isDownloading: indexValue == nil
            )
            .font(.satoshiBold(18))
            .foregroundStyle(Color.onSurface)
            
            MinimumTextSize(
                text: Localization.string("Very High")
            ) {
                ShimmeringText(
                    text: status.map { Localization.string($0) } ?? "000000",
                    isDownloading: indexValue == nil
                )
            }
            .font(.satoshiBold(12))
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(getGasIndexColor(indexValue: indexValue ?? "0"))
        .padding(
            EdgeInsets(
                top: 12,
                leading: 8,
                bottom: 12,
                trailing: 8
            )
        )
        .cardBackground(hasPadding: false)
    }
}

func getGasIndexColor(indexValue: String) -> Color {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 3) { return .extremeGreed }
    else if (intValue < 10)  { return .greed }
    else if (intValue < 30)  { return .neutral }
    else if (intValue < 80)  { return .fear }
    else { return .extremeFear }
}

func getGasIndexString(indexValue: String) -> String {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 3) { return "Very Low" }
    else if (intValue < 10)  { return "Low" }
    else if (intValue < 30)  { return "Neutral" }
    else if (intValue < 80)  { return "High" }
    else { return "Very High" }
}
