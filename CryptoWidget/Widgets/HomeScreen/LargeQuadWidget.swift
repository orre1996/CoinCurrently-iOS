//
//  LargeDuoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import SwiftUI

struct LargeQuadWidget: View {
    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    let selectedCoinIDs: [String]
    
    private var selectedCoinCount: Int {
        selectedCoinIDs.filter { !$0.isEmpty }.count
    }
    
    var body: some View {
        if selectedCoinCount == 0 {
            WidgetEmptyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    cellContent(at: 0)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                    
                    cellContent(at: 1)
                }
                
                HStack(spacing: 0) {
                    Separator()
                        .padding(.horizontal, 16)
                    
                    Separator()
                        .padding(.horizontal, 16)
                }
                
                HStack(spacing: 0) {
                    cellContent(at: 2)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                    
                    cellContent(at: 3)
                }
            }
        }
    }
    
    @ViewBuilder
    private func cellContent(at index: Int) -> some View {
        let coinID = selectedCoinIDs[safely: index] ?? data?[safely: index]?.id
        if !(coinID ?? "").isEmpty {
            SmallCryptoWidget(
                data: data?[safely: index],
                image: image?[safely: index],
                selectedCurrency: selectedCurrency,
                coinID: coinID
            )
        } else if index == WidgetEmptyView.nextPromptIndex(
            selectedIDs: selectedCoinIDs,
            data: data,
            slotCount: 4
        ) {
            WidgetEmptyView(plural: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
