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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(timeframe) %")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
                .accessibilityHidden(true)
            
            PriceChangePercentView(
                change: change,
                size: changeSize,
                accessibleTimeframe: timeframe.lowercased(),
                isDownloading: change == nil
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
