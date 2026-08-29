//
//  LargeMultiWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-27.
//

import SwiftUI

struct LargeMultiWidget: View {
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
                    .padding(.bottom, 6)
                
                VerticalSeparator()
                
                MultiWidgetCell(data: data?[safely: 1], image: image?[safely: 1], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
            }
            
            Separator()
            
            
            HStack(alignment: .center, spacing: 0) {
                
                MultiWidgetCell(data: data?[safely: 2], image: image?[safely: 2], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.vertical, 6)
                
                VerticalSeparator()
                
                MultiWidgetCell(data: data?[safely: 3], image: image?[safely: 3], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.vertical, 6)
                
            }
            
            Separator()
            
            HStack(alignment: .center, spacing: 0) {
                
                MultiWidgetCell(data: data?[safely: 4], image: image?[safely: 4], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.vertical, 6)
                
                VerticalSeparator()
                
                MultiWidgetCell(data: data?[safely: 5], image: image?[safely: 5], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.vertical, 6)
                
            }
            
            Separator()
            
            
            HStack(alignment: .center, spacing: 0) {
                
                MultiWidgetCell(data: data?[safely: 6], image: image?[safely: 6], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                VerticalSeparator()
                
                MultiWidgetCell(data: data?[safely: 7], image: image?[safely: 7], selectedCurrency: selectedCurrency, hasPro: hasBoughtPro)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
            }
            
        }
        .overlay (
            BuyProView(
                hasBoughtPro: hasBoughtPro
            )
        )
    }
}
