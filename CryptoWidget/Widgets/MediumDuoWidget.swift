//
//  SmallWidget.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-24.
//

import SwiftUI
import WidgetKit

struct MediumDuoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    let selectedCoinIDs: [String]
    
    private var hasSelectedCoins: Bool {
        selectedCoinIDs.contains { !$0.isEmpty }
    }
    
    var body: some View {
        if !hasSelectedCoins {
            WidgetEmptyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 0) {
                SmallCryptoWidget(
                    data: data?[safely: 0],
                    image: image?[safely: 0],
                    selectedCurrency: selectedCurrency,
                    coinID: selectedCoinIDs[safely: 0]
                )
                
                Rectangle()
                    .frame(
                        minWidth: 1,
                        maxWidth: 1,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 16)
                
                SmallCryptoWidget(
                    data: data?[safely: 1],
                    image: image?[safely: 1],
                    selectedCurrency: selectedCurrency,
                    coinID: selectedCoinIDs[safely: 1]
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
