//
//  StartMarketPageView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-19.
//

import SwiftUI

struct StartMarketPageView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let page: StartMarketPage
    let selectedPage: StartMarketPage
    let action: (StartMarketPage) -> Void

    var body: some View {
        Button(action: {
            action(page)
        }) {
            HStack(spacing: 16) {
                Circle()
                    .stroke(Color.primary, lineWidth: 3)
                    .frame(width: 32 * min(scale, 1.5), height: 32 * min(scale, 1.5), alignment: .center)
                    .background(page == selectedPage ? Color.primary : .clear)
                    .clipShape(Circle())
                
                Text(page.rawValue)
                    .font(.poppinsRegular(16))
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .multilineTextAlignment(.leading)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
    }
}

#Preview {
    StartMarketPageView(page: .currencies,
                        selectedPage: .currencies,
                        action: { _ in })
}
