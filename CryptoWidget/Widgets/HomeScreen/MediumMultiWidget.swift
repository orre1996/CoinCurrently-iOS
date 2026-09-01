//
//  MediumMultiWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-27.
//

import SwiftUI

struct MediumMultiWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    let hasBoughtPro: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                
                MultiWidgetCell(data: data?.first, image: image?.first, selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .foregroundStyle(.tertiary)
                
                MultiWidgetCell(data: data?[safely: 1], image: image?[safely: 1], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            Separator()
            
            HStack(alignment: .center, spacing: 0) {
                
                MultiWidgetCell(data: data?[safely: 2], image: image?[safely: 2], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .foregroundStyle(.tertiary)
                
                MultiWidgetCell(data: data?[safely: 3], image: image?[safely: 3], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
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
