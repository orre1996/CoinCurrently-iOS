//
//  LoadingScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-23.
//

import SwiftUI

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image.bannerTransparent
                    .resizable()
                    .scaledToFit()
                
                ActivityIndicator(
                    size: 24
                )
            }
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea()
    }
}
