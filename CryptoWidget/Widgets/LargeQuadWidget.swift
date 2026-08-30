//
//  LargeDuoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import SwiftUI
import WidgetKit

struct LargeQuadWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    let selectedCoinIDs: [String]
    let hasBoughtPro: Bool
    
    private var selectedCoinCount: Int {
        selectedCoinIDs.filter { !$0.isEmpty }.count
    }

    private var displaySlotCount: Int {
        hasBoughtPro ? selectedCoinCount : 4
    }
    
    var body: some View {
        if displaySlotCount == 0 {
            WidgetEmptyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    cellContent(at: 0)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                        .blur(radius: hasBoughtPro ? 0 : 5)
                    
                    cellContent(at: 1)
                }
                
                HStack(spacing: 0) {
                    Separator()
                        .padding(.horizontal, 16)
                        .blur(radius: hasBoughtPro ? 0 : 5)
                    
                    Separator()
                        .padding(.horizontal, 16)
                        .blur(radius: hasBoughtPro ? 0 : 5)
                }
                
                HStack(spacing: 0) {
                    cellContent(at: 2)
                    
                    VerticalSeparator()
                        .padding(.vertical, 16)
                        .blur(radius: hasBoughtPro ? 0 : 5)
                    
                    cellContent(at: 3)
                }
            }
            .overlay (
                BuyProView(
                    hasBoughtPro: hasBoughtPro
                )
            )
            .widgetURL(hasBoughtPro ? nil : URL(string: "buyPro"))
        }
    }
    
    @ViewBuilder
    private func cellContent(at index: Int) -> some View {
        if !hasBoughtPro || index < selectedCoinCount {
            SmallCryptoWidget(
                data: data?[safely: index],
                image: image?[safely: index],
                selectedCurrency: selectedCurrency,
                coinID: selectedCoinIDs[safely: index],
                hasBoughtPro: hasBoughtPro
            )
        } else {
            WidgetEmptyView(plural: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
