//
//  SearchCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-17.
//

import SwiftUI

struct SearchCoinView: View {
    @ScaledMetric private var scale: CGFloat = 1

    var searchCoin: SearchResult?
    var downloading: Bool
    var action: () -> () = { }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 0) {
                if searchCoin?.large != nil || searchCoin?.thumb != nil || downloading {
                    ShimmeringImage(
                        imageUrl: searchCoin?.large ?? searchCoin?.thumb,
                        downloading: downloading,
                        size: 32 * min(scale, 1.5)
                    )
                    .padding(.trailing, 16)
                }
                
                ShimmeringText(
                    text: getText,
                    isDownloading: searchCoin == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                
                if searchCoin == nil || searchCoin?.name != nil {
                    ShimmeringText(
                        text: searchCoin?.name ?? "000000",
                        isDownloading: searchCoin?.name == nil
                    )
                    .foregroundStyle(Color.onSurfaceDim)
                    .font(.satoshiBold(12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var getText: String {
        var text = ""
        
        if let rank = searchCoin?.market_cap_rank {
            text += "#\(rank) "
        }

        if let symbol = searchCoin?.symbol {
            text += symbol.uppercased()
        }
        
        return text
    }
}
