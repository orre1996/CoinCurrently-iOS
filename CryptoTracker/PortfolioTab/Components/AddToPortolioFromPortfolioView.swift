//
//  AddToPortolioFromPortfolioView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-02-09.
//

import SwiftUI

struct AddToPortolioFromPortfolioView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let name: String?
    let symbol: String?
    let id: String?
    let cellPressed: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name ?? "")
                    .font(.poppinsRegular(16))
                    .fixedSize(horizontal: false, vertical: true)
                
                if let symbol {
                    Text("(\(symbol.uppercased())")
                        .font(.poppinsRegular(14))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image.chevronRight
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .frame(width: 8 * min(scale, 1.5), height: 16 * min(scale, 1.5), alignment: .center)
        }
        .modifier(CardBackground())
        .onTapGesture {
            cellPressed()
        }
    }
}
