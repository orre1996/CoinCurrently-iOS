//
//  EdgeSwipe.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-05.
//

import SwiftUI

struct EdgeSwipe: View {
    let isDragging: Bool

    var body: some View {
        Color.black.opacity(0.00001)
            .frame(width: 24)
            .allowsHitTesting(!isDragging)
            .accessibilityHidden(true)
    }
}
