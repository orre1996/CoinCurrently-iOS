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
                text: "Last Month",
                alignment: .top
            ) {
                Text(timeframe)
            }
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDimmer)
            .padding(.bottom, 4)
            
            ShimmeringText(
                text: indexValue ?? "000",
                isDownloading: indexValue == nil
            )
            .font(.satoshiBold(18))
            .foregroundStyle(Color.onSurface)
            
            MinimumTextSize(
                text: longestStatus?.replacingOccurrences(of: " ", with: isAccessibilityEnabled ? " " : "\n") ?? "",
                alignment: .top
            ) {
                ShimmeringText(
                    text: status?.replacingOccurrences(of: " ", with: isAccessibilityEnabled ? " " : "\n") ?? "000000",
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
}
