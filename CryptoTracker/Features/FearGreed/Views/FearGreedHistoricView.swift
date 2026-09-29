//
//  FearGreedHistoricView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/7/25.
//

import SwiftUI

struct FearGreedHistoricView: View {
    @Environment(\.sizeCategory) private var category
    
    let timeframe: String
    let indexValue: String?
    let longestStatus: String?
    let status: String?
    
    var body: some View {
        let isAccessibilityEnabled = category.isAccessibilityCategory
        
        VStack(spacing: 0) {
            MinimumTextSize(
                text: Localization.string("Last month"),
                alignment: .top,
                fixesWidth: false
            ) {
                Text(Localization.string(timeframe))
            }
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDimmer)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .padding(.bottom, 4)
            
            ShimmeringText(
                text: indexValue ?? "000",
                isDownloading: indexValue == nil
            )
            .font(.satoshiBold(18))
            .foregroundStyle(Color.onSurface)
            
            MinimumTextSize(
                text: wrappedStatus(longestStatus, isAccessibilityEnabled: isAccessibilityEnabled),
                alignment: .top
            ) {
                ShimmeringText(
                    text: status == nil ? "000000" : wrappedStatus(status, isAccessibilityEnabled: isAccessibilityEnabled),
                    isDownloading: status == nil
                )
            }
            .font(.satoshiBold(12))
            .foregroundStyle(getIndexColor(indexValue: indexValue ?? "0"))
            .lineLimit(isAccessibilityEnabled ? 1 : 2)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
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
    
    private func wrappedStatus(_ status: String?, isAccessibilityEnabled: Bool) -> String {
        guard let status, !status.isEmpty else { return "" }
        let localized = Localization.string(status)
        guard !isAccessibilityEnabled else { return localized }
        
        let parts = localized.split(separator: " ", maxSplits: 1).map(String.init)
        return parts.joined(separator: "\n")
    }
}
