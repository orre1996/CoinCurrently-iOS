//
//  CryptoListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-22.
//

import SwiftUI

struct CryptoListView: View {
    @Environment(\.colorScheme) var scheme
    
    @ScaledMetric private var scale: CGFloat = 1

    let coin: Toplist?
    let currencySelected: (Toplist) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 16 * min(scale, 1.5)
            )

            VStack(alignment: .leading, spacing: 0) {
                ShimmeringText(
                    text: coin == nil ? "00000000" : rankName,
                    isDownloading: coin == nil
                )
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                
                ShimmeringText(
                    text: coin?.current_price?.formatCurrency(threshold: FormattingThreshold.none) ?? "0000000",
                    isDownloading: coin == nil
                )
                .font(.satoshiBold(14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            PriceChangePercentView(
                change: coin?.price_change_percentage_7d_in_currency,
                size: .extraSmall,
                accessibleTimeframe: "7 days",
                isDownloading: coin == nil
            )
        }
        .padding(8)
        .background(Color.surfaceContainerHigh)
        .cornerRadius(10)
        .foregroundColor(Color.onSurface)
        .onTapGesture {
            if let coin {
                currencySelected(coin)
            }
        }
    }
    
    private var rankName: String {
        var text = ""
        
        if let rank = coin?.market_cap_rank {
            text += "#\(rank)"
        }
        
        if let symbol = coin?.symbol {
            text += " \(symbol.uppercased())"
        }
        
        return text
    }
}
