//
//  HistoricDataChangeView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct HistoricDataChangeView: View {
    let timeframe: String
    let change: Double?

    private var changeSize: ChangeSize {
        #if IS_WATCH
        .small
        #else
        .medium
        #endif
    }

    private var localizedTimeframe: String {
        #if IS_APP
        Localization.string(timeframe)
        #else
        timeframe
        #endif
    }

    private var localizedAccessibleTimeframe: String {
        #if IS_APP
        timeframe
        #else
        timeframe.lowercased()
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(localizedTimeframe) %")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
                .accessibilityHidden(true)
            
            PriceChangePercentView(
                change: change,
                size: changeSize,
                accessibleTimeframe: localizedAccessibleTimeframe,
                isDownloading: change == nil
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
