//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI

struct CommunitySentimentHelpSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    @ScaledMetric private var scale: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: "Community Sentiment",
                leadingIcon: .info
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Community Sentiment reflects votes from CoinGecko users on whether they feel bullish or bearish about this asset. It does not represent financial advice or market forecasts.")
                }
                .foregroundColor(.onSurfaceDim)
                .font(.satoshiRegular(18))
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
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
}

