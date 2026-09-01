//
//  SearchCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-17.
//

import SwiftUI

struct TrendingCoinView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist?
    let action: (Toplist?) -> Void
    
    var body: some View {
        Button(action: {
            action(coin)
        }, label: {
            HStack(spacing: 8) {
                ShimmeringImage(
                    imageUrl: coin?.image,
                    downloading: coin == nil,
                    size: 28 * min(scale, 1.5)
                )

                VStack(alignment: .leading, spacing: 0) {
                    if !getText.isEmpty {
                        NewShimmeringText(
                            text: getText,
                            isDownloading: coin == nil
                        )
                        .foregroundStyle(Color.onSurface)
                        .font(.satoshiBold(16))
                    }
                    
                    if coin == nil || coin?.name != nil {
                        NewShimmeringText(
                            text: coin?.name ?? "000000",
                            isDownloading: coin?.name == nil
                        )
                        .foregroundStyle(Color.onSurfaceDim)
                        .font(.satoshiBold(12))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(
                EdgeInsets(
                    top: 10,
                    leading: 16,
                    bottom: 10,
                    trailing: 16
                )
            )
            .multilineTextAlignment(.leading)
        })
        .contentShape(Rectangle())
    }
    
    var getText: String {
        var text = ""
        
        if let rank = coin?.market_cap_rank {
            text += "#\(rank) "
        }

        if let symbol = coin?.symbol {
            text += symbol.uppercased()
        }
        
        return text
    }
}
