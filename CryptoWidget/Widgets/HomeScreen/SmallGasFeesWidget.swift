//
//  SmallGasFeesWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2024-03-20.
//

import SwiftUI

struct SmallGasFeesWidget: View {
    @Environment(\.colorScheme) var scheme

    var gasFees: GasFees?
    
    var body: some View {
        GeometryReader { reader in
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Slow")
                        .font(.regularWidget14)
                        .foregroundStyle(Color.trendDown(for: scheme))
                    
                    Text("\(Double(gasFees?.gasFeeData?.first?.safeGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                        .font(.regularWidget18)
                        .foregroundStyle(Color.onSurface(for: scheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Standard")
                        .font(.regularWidget14)
                        .foregroundStyle(Color.neutral(for: scheme))
                    
                    Text("\(Double(gasFees?.gasFeeData?.first?.proposeGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                        .font(.regularWidget18)
                        .foregroundStyle(Color.onSurface(for: scheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fast")
                        .font(.regularWidget14)
                        .foregroundStyle(Color.trendUp(for: scheme))
                    
                    Text("\(Double(gasFees?.gasFeeData?.first?.fastGasPrice ?? "0")?.formatted(.number.precision(.fractionLength(2))) ?? "0") Gwei")
                        .font(.regularWidget18)
                        .foregroundStyle(Color.onSurface(for: scheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .multilineTextAlignment(.center)
    }
}
