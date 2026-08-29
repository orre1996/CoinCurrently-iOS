//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI


struct FearGreedLevelExplanation: Hashable {
    let title: String
    let color: Color
    let percent: String
    let body: String
}

struct FearGreedPercentExplanation: Hashable {
    let title: String
    let percent: String
    let body: String
}

struct FearGreedHelpSheet: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private let levelExplanations: [FearGreedLevelExplanation] = [
        FearGreedLevelExplanation(
            title: "Extreme Greed",
            color: .extremeGreed,
            percent: " (80-100)",
            body: "Optimism is elevated and pullbacks become more likely. Consider reducing high-risk exposure."
        ),
        FearGreedLevelExplanation(
            title: "Greed",
            color: .greed,
            percent: " (60-79)",
            body: "Confidence is rising and buying activity is increasing. Stay selective and avoid chasing rallies."
        ),
        FearGreedLevelExplanation(
            title: "Neutral",
            color: .neutral,
            percent: " (40-59)",
            body: "Sentiment is balanced with no strong trend direction. Watch for momentum shifts."
        ),
        FearGreedLevelExplanation(
            title: "Fear",
            color: .fear,
            percent: " (20-39)",
            body: "Caution is increasing across the market. Look for discounted quality assets."
        ),
        FearGreedLevelExplanation(
            title: "Extreme Fear",
            color: .extremeFear,
            percent: " (0-19)",
            body: "Panic selling is widespread. Long-term investors often accumulate during these periods."
        )
    ]
    
    private let percentExplanations: [FearGreedPercentExplanation] = [
        FearGreedPercentExplanation(
            title: "Volatility",
            percent: " (25%)",
            body: "Compares Bitcoin’s recent volatility and drawdowns to its 30- and 90-day averages. Higher volatility often signals fearful market conditions."
        ),
        FearGreedPercentExplanation(
            title: "Market Momentum / Volume",
            percent: " (25%)",
            body: "Measures trading volume and price momentum against recent averages. Strong momentum typically reflects growing market confidence."
        ),
        FearGreedPercentExplanation(
            title: "Social Media",
            percent: " (15%)",
            body: "Analyzes engagement across crypto discussions on X. Sudden increases often signal a bullish market."
        ),
        FearGreedPercentExplanation(
            title: "Surveys",
            percent: " (15%) - Currently paused",
            body: "Weekly surveys are conducted on a polling platform to see what individuals are thinking of the markets."
        ),
        FearGreedPercentExplanation(
            title: "Dominance",
            percent: " (10%)",
            body: "Tracks Bitcoin’s share of total crypto market capitalization. Higher dominance suggests a shift toward safer assets."
        ),
        FearGreedPercentExplanation(
            title: "Trends",
            percent: " (10%)",
            body: "Weekly surveys were conducted to see what investors are thinking of the markets."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: "Fear & Greed",
                leadingIcon: .info
            )
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(levelExplanations, id: \.self) {
                        levelSection(explanation: $0)
                            .padding(.bottom, 8)
                    }
                    
                    Separator()
                        .padding(.bottom, 8)
                    
                    Text("Index Factors")
                        .foregroundStyle(Color.onSurfaceDim)
                        .accessibilityAddTraits(.isHeader)
                    
                    ForEach(percentExplanations, id: \.self) {
                        helpSection(explanation: $0)
                            .padding(.bottom, 8)
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
            }
            .foregroundColor(.onSurface)
            .font(.satoshiBold(22))
        }
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func levelSection(explanation: FearGreedLevelExplanation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                explanation.color
                    .frame(width: 12 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                    .cornerRadius(4)
                    .accessibilityHidden(true)
                
                ((Text(explanation.title)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface))
                 
                +
                 
                (Text(explanation.percent)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDimmer)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(titlePercentAccessibilityLabel(
                    title: explanation.title,
                    percent: explanation.percent
                ))
            }
            
            Text(explanation.body)
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func helpSection(explanation: FearGreedPercentExplanation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ((Text(explanation.title)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface))
            +
            (Text(explanation.percent)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurfaceDimmer)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(titlePercentAccessibilityLabel(
                title: explanation.title,
                percent: explanation.percent
            ))
            
            Text(explanation.body)
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func titlePercentAccessibilityLabel(title: String, percent: String) -> String {
        " \(title.lowercased()), \(accessiblePercent(percent))"
    }
    
    private func accessiblePercent(_ percent: String) -> String {
        percent
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: " to ")
            .trimmingCharacters(in: .whitespaces)
    }
}

