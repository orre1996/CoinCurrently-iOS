//
//  BuyProView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-14.
//

import SwiftUI

struct ProLockOverlayView: View {
    let viewPressed: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.45)

            Button(action: {
                viewPressed()
            }, label: {
                VStack(spacing: 12) {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Unlocked with\nCoinCurrently Pro")
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .font(.regular16)
                }
            })
            .foregroundColor(.onSurface)
            .minimumScaleFactor(0.3)
            .padding(16)
            .background(Color.black.opacity(0.65))
            .cornerRadius(8)
        }
    }
}
