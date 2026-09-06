//
//  CommunitySentimentView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/12/25.
//

import SwiftUI

struct CommunitySentimentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let sentimentVotesUpPercentage: Double?
    let sentimentVotesDownPercentage: Double?
    let fromScreen: ScreenLabel
    @Binding var showCommunitySentimentHelp: Bool

    var body: some View {
        VStack(spacing: 4) {
            headerView
            
            votesView
        }
    }
    
    @ViewBuilder
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
        VStack(alignment: .leading, spacing: 0) {
            Text("Sentiment Votes")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            CustomProgressBarView(
                progress: (sentimentVotesUpPercentage ?? 0) / 100,
                foregroundColor: .trendUp,
                backgroundColor: .trendDown,
                height: 24,
                capsuleShaped: false,
                downloading: sentimentVotesUpPercentage == nil || sentimentVotesDownPercentage == nil
            )
            .padding(.vertical, 12)
            .accessibilityHidden(true)

            sentimentMeterTitles
        }
        .cardBackground()
        .accessibilityElement(children: .combine)
    }
    
    private var sentimentMeterTitles: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                ShimmeringText(
                    text: "\((sentimentVotesUpPercentage ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                    isDownloading: sentimentVotesUpPercentage == nil
                )
                .foregroundStyle(Color.extremeGreed)
                .font(.satoshiBold(16))
                
                Text("Bullish")
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
            }
            .accessibilityElement(children: .combine)
            
            Spacer(minLength: 16)
            
            VStack(alignment: .trailing, spacing: 4) {
                ShimmeringText(
                    text: "\((sentimentVotesDownPercentage ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                    isDownloading: sentimentVotesDownPercentage == nil
                )
                .foregroundStyle(Color.extremeFear)
                .font(.satoshiBold(16))
                
                Text("Bearish")
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
            }
            .accessibilityElement(children: .combine)
        }
    }
}
