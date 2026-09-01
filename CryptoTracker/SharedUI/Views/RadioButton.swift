//
//  RadioButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/19/25.
//

import SwiftUI

struct RadioButton: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let isSelected: Bool
    
    var body: some View {
        Circle()
            .fill(isSelected ? Color.primary : Color.outline)
            .frame(width: 10 * min(scale, 1.5), height: 10 * min(scale, 1.5))
            .opacity(isSelected ? 1 : 0)
            .padding(3)
            .background(
                Circle()
                    .stroke(isSelected ? Color.primary : Color.outline, lineWidth: 2)
            )
    }
}
