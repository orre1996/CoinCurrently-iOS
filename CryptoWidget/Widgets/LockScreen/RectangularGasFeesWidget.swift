//
//  RectangularGasFeesWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2024-03-21.
//

import SwiftUI
import WidgetKit

struct RectangularGasFeesWidget: View {
    var gasFees: GasFees?
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Slow:")
                        
                        Text("\(Double(gasFees?.gasFeeData?.first?.safeGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Text("Standard:")
                        
                        Text("\(Double(gasFees?.gasFeeData?.first?.proposeGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Text("Fast:")
                        
                        Text("\(Double(gasFees?.gasFeeData?.first?.fastGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .padding(4)
                .font(.system(size: 14, weight: .semibold))
            }
        }
        .multilineTextAlignment(.center)
    }
}
