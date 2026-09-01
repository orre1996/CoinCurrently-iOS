//
//  TabBarButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-28.
//

import SwiftUI

struct TabBarButton: View {
    let image: Image
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        })
        .frame(width: 40, height: 40)
    }
}
