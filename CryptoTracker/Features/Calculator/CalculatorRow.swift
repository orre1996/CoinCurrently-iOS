//
//  CalculatorRow.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-16.
//

import SwiftUI

struct CalculatorRow: View {    
    @ScaledMetric private var scale: CGFloat = 1
    
    var coin: Toplist?
    var amount: String?
    
    var body: some View {
        HStack(spacing: 16) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 32 * min(scale, 1.5)
            )
            
            VStack(alignment: .leading, spacing: 0) {
                ShimmeringText(
                    text: coin?.symbol?.uppercased() ?? "0000",
                    isDownloading: coin?.symbol == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                
                ShimmeringText(
                    text: coin?.name ?? "00000",
                    isDownloading: coin?.name == nil
                )
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ShimmeringText(
                text: amount ?? "000000",
                isDownloading: amount == nil
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            .multilineTextAlignment(.trailing)
        }
        .padding(
            EdgeInsets(
                top: 16,
                leading: 40,
                bottom: 16,
                trailing: 40
            )
        )
    }
}
