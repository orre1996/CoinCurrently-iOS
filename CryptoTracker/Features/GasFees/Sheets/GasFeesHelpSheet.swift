//
//  GasFeesHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI

struct GasFeesHelpSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var appLanguage = AppLanguagePreference.stored
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private let levelExplanations: [FearGreedLevelExplanation] = [
        FearGreedLevelExplanation(
            title: "Very Low",
            color: .extremeGreed,
            percent: " (0-3 Gwei)",
            body: "Transactions are extremely cheap. Ideal time for swaps, transfers, and contract interactions."
        ),
        FearGreedLevelExplanation(
            title: "Low",
            color: .greed,
            percent: " (3.1-10 Gwei)",
            body: "Transactions are cheaper than usual. Most actions should confirm quickly at low cost."
        ),
        FearGreedLevelExplanation(
            title: "Neutral",
            color: .neutral,
            percent: " (10.1-30 Gwei)",
            body: "Standard fees and confirmation times expected. Typical network activity."
        ),
        FearGreedLevelExplanation(
            title: "High",
            color: .fear,
            percent: " (30.1-80 Gwei)",
            body: "Transactions cost more and may take longer without higher fees. Network is busy."
        ),
        FearGreedLevelExplanation(
            title: "Very High",
            color: .extremeFear,
            percent: " (80+ Gwei)",
            body: "Expect expensive fees and slower confirmations unless prioritized. Network congestion is heavy."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: Localization.string("ETH Gas Fee"),
                accessibilityTitle: Localization.string("Ethereum gas fee"),
                leadingIcon: .info
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(levelExplanations, id: \.self) {
                        levelSection(explanation: $0)
                    }
                }
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            .foregroundColor(.onSurface)
            .font(.satoshiBold(22))
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func levelSection(explanation: FearGreedLevelExplanation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                explanation.color
                    .frame(width: 12 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                    .cornerRadius(4)
                    .accessibilityHidden(true)
                
                ((Text(Localization.string(explanation.title))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface))
                 
                +
                 
                (Text(Localization.string(explanation.percent))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDimmer)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(titlePercentAccessibilityLabel(
                    title: explanation.title,
                    percent: explanation.percent
                ))
            }
            
            Text(Localization.string(explanation.body))
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func titlePercentAccessibilityLabel(title: String, percent: String) -> String {
        Localization.format("%@, %@", Localization.string(title), accessiblePercent(percent))
    }
    
    private func accessiblePercent(_ percent: String) -> String {
        switch percent {
        case " (0-3 Gwei)":
            return Localization.string("0 to 3 Gwei")
        case " (3.1-10 Gwei)":
            return Localization.string("3.1 to 10 Gwei")
        case " (10.1-30 Gwei)":
            return Localization.string("10.1 to 30 Gwei")
        case " (30.1-80 Gwei)":
            return Localization.string("30.1 to 80 Gwei")
        case " (80+ Gwei)":
            return Localization.string("80 or more Gwei")
        default:
            return percent
        }
    }
}
