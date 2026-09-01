//
//  LargeDuoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import SwiftUI


import SwiftUI
import WidgetKit

struct LargeDuoWidget: View {
    let data: [Toplist]?
    let image: [UIImage]?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            MediumCryptoWidget(data: data?[safely: 0], image: image?[safely: 0], selectedCurrency: selectedCurrency)
            
            Separator()
            
            MediumCryptoWidget(data: data?[safely: 1], image: image?[safely: 1], selectedCurrency: selectedCurrency)
            
        }
        .clipped()
    }
}
