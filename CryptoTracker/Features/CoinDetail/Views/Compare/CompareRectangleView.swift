//
//  CompareRectangleView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/23/25.
//

import SwiftUI

struct CompareRectangleView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let color: Color
    var size: CGFloat = 16
    
    var body: some View {
        color
            .frame(width: size * min(scale, 1.5), height: size * min(scale, 1.5))
            .cornerRadius(4)
    }
}
