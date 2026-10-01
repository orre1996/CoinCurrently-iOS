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

    private var valueFont: Font {
        #if IS_WATCH
        .satoshiBold(14)
        #else
        .satoshiBold(16)
        #endif
    }
    
    private var horizontalPadding: CGFloat {
        #if IS_WATCH
        8
        #else
        16
        #endif
    }

    var body: some View {
        VStack(spacing: 4) {
            headerView
            
            votesView
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 0) {
            sentimentTitle
            
            Spacer(minLength: 16)
            
#if !IS_WATCH
            sentimentInfoButton
#endif
        }
    }

    private var sentimentTitle: some View {
        Text(AppCopy.string("Community Sentiment"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }

    #if !IS_WATCH
    private var sentimentInfoButton: some View {
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
        .accessibilityLabel(AppCopy.string("Community sentiment info"))
    }
    #endif
    
    private var votesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AppCopy.string("Sentiment Votes"))
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
        .cardBackground(padding: horizontalPadding)
        .accessibilityElement(children: .combine)
    }
    
    private var sentimentMeterTitles: some View {
        HStack(spacing: 0) {
            bullishVotes
            
            Spacer(minLength: 16)
            
            bearishVotes
        }
    }
    
    private var bullishVotes: some View {
        VStack(alignment: .leading, spacing: 4) {
            ShimmeringText(
                text: "\((sentimentVotesUpPercentage ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                isDownloading: sentimentVotesUpPercentage == nil
            )
            .foregroundStyle(Color.extremeGreed)
            .font(valueFont)
            
            Text(AppCopy.string("Bullish"))
                .foregroundStyle(Color.onSurfaceDimmer)
                .font(.satoshiBold(12))
        }
        .accessibilityElement(children: .combine)
    }

    private var bearishVotes: some View {
        VStack(alignment: bearishTextAlignment, spacing: 4) {
            ShimmeringText(
                text: "\((sentimentVotesDownPercentage ?? 0).formatted(.number.precision(.fractionLength(0))))%",
                isDownloading: sentimentVotesDownPercentage == nil
            )
            .foregroundStyle(Color.extremeFear)
            .font(valueFont)
            
            Text(AppCopy.string("Bearish"))
                .foregroundStyle(Color.onSurfaceDimmer)
                .font(.satoshiBold(12))
        }
        .accessibilityElement(children: .combine)
    }

    private var bearishTextAlignment: HorizontalAlignment {
        #if IS_WATCH
        .leading
        #else
        .trailing
        #endif
    }
}
