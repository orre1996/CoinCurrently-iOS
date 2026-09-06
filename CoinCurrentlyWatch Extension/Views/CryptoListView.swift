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
        HStack(spacing: 8) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 24 * min(scale, 1.5)
            )

            VStack(alignment: .leading, spacing: 4) {
                ShimmeringText(
                    text: coin == nil ? "00000000" : rankName,
                    isDownloading: coin == nil
                )
                .font(.satoshiBold(14))
                
                ShimmeringText(
                    text: coin?.current_price?.formatCurrency(threshold: FormattingThreshold.none) ?? "",
                    isDownloading: coin == nil
                )
                .font(.satoshiBold(16))
                
                HStack(spacing: 0) {
                    Text("7d: ")
                    .font(.satoshiBold(12))
                    
                    PriceChangePercentView(
                        change: coin?.price_change_percentage_7d_in_currency,
                        size: .small,
                        accessibleTimeframe: "7 days",
                        directionPosition: .right,
                        isDownloading: coin == nil
                    )
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
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
