//
//  BannerLogoView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/11/26.
//

import SwiftUI

struct BannerLogoView: View {
    var body: some View {
        Image.bannerTransparent
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(Color.onSurface)
            .frame(width: 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(8)
            .padding(.bottom, 8)
            .opacity(0.3)
    }
}
