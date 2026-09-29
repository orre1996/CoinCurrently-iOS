//
//  ExchangeDetailSummaryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/11/26.
//

import SwiftUI

struct ExchangeDetailSummaryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let exchangeDetail: Exchange?
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        AdaptiveStack(
            isHorizontal: isHorizontal,
            spacing: isHorizontal ? 32 : 16,
            horizontalAlignment: .leading,
            verticalAlignment: .top
        ) {
            coinsView
            
            if !isHorizontal {
                Separator()
            }
            
            pairsView
            
            if !isHorizontal {
                Separator()
            }
            
            trustScoreItem
        }
        .minimumScaleFactor(0.7)
        .cardBackground(
            cornerRadius: 12
        )
        .overlay {
            if isHorizontal {
                dividers
            }
        }
    }
    
    private var dividers: some View {
        HStack(spacing: 0) {
            Spacer()
            
            VerticalSeparator(width: 2)
                .accessibilityHidden(true)
            
            Spacer()
            
            VerticalSeparator(width: 2)
                .accessibilityHidden(true)
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var coinsView: some View {
        statItem(
            label: "Coins",
            value: "\(exchangeDetail?.coins ?? 0)",
            isDownloading: exchangeDetail?.coins == nil
        )
    }
    
    private var pairsView: some View {
        statItem(
            label: "Pairs",
            value: "\(exchangeDetail?.pairs ?? 0)",
            isDownloading: exchangeDetail?.pairs == nil
        )
    }
    
    private func statItem(label: String, value: String, isDownloading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string(label))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityLabel(Localization.string(label) + ": ")
            
            ShimmeringText(
                text: value,
                isDownloading: isDownloading
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private var trustScoreItem: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Trust Score"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityLabel(Localization.string("Trust score: "))
            
            ShimmeringText(
                text: "\(exchangeDetail?.trust_score ?? 0)/10",
                isDownloading: exchangeDetail?.trust_score == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(exchangeDetail?.trust_score?.trustColor ?? Color.onSurfaceDim)
            .accessibilityLabel(Localization.format("%d of 10", exchangeDetail?.trust_score ?? 0))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
