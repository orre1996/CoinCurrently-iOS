//
//  CompareSentimentView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/23/25.
//

import SwiftUI

struct CompareSentimentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let mainCryptoInfo: CurrencyDataModel?
    let compareCryptoInfo: CurrencyDataModel?
    let fromScreen: ScreenLabel
    @Binding var showCommunitySentimentHelp: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            headerView
            
            votesView
                .cardBackground()
        }
        .padding(.horizontal, 16)
    }
    
    private var headerView: some View {
        HStack(spacing: 0) {
            Text("Community Sentiment")
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(22))
                .accessibilityAddTraits(.isHeader)
            
            Spacer(minLength: 16)
            
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: fromScreen, sheet: .communitySentimentHelp)
                )
                showCommunitySentimentHelp = true
            }, label: {
                Image.info
                    .resizable()
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .padding(12)
            })
            .accessibilityLabel("Community sentiment info")
        }
    }
    
    private var votesView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sentiment Votes")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            CustomProgressBarView(
                progress: (mainCryptoInfo?.sentiment_votes_up_percentage ?? 0) / 100,
                foregroundColor: .primary50,
                downloading: mainCryptoInfo?.sentiment_votes_up_percentage == nil
            )
            .padding(.top, 8)
            .accessibilityHidden(true)
            
            CustomProgressBarView(
                progress: (compareCryptoInfo?.sentiment_votes_up_percentage ?? 0) / 100,
                foregroundColor: .blue50,
                downloading: compareCryptoInfo?.sentiment_votes_up_percentage == nil
            )
            .padding(.bottom, 8)
            .accessibilityHidden(true)
            
            sentimentMeterTitles
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var sentimentMeterTitles: some View {
        let mainUpVotes = mainCryptoInfo?.sentiment_votes_up_percentage
        let compareUpVotes = compareCryptoInfo?.sentiment_votes_up_percentage
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
            HStack(spacing: 4) {
                CompareRectangleView(
                    color: .primary50
                )
                .padding(.trailing, 4)
                .accessibilityHidden(true)
                
                ShimmeringText(
                    text: "\((mainUpVotes ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                    isDownloading: mainUpVotes == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityHidden(true)
                
                Text("Bullish")
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibleBullishLabel(name: mainCryptoInfo?.name, percent: mainUpVotes))
            
            HStack(spacing: 4) {
                CompareRectangleView(
                    color: .blue50
                )
                .padding(.trailing, 4)
                .accessibilityHidden(true)
                
                ShimmeringText(
                    text: "\((compareUpVotes ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                    isDownloading: compareUpVotes == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityHidden(true)
                
                Text("Bullish")
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibleBullishLabel(name: compareCryptoInfo?.name, percent: compareUpVotes))
        }
    }
    
    private func accessibleBullishLabel(name: String?, percent: Double?) -> String {
        let formattedPercent = (percent ?? 0).formatted(.number.precision(.fractionLength(0)))
        return "\(name ?? ""): \(formattedPercent) percent bullish"
    }
}
