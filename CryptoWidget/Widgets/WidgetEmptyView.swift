//
//  WidgetEmptyView.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/18/26.
//

import SwiftUI

struct WidgetEmptyView: View {
    @Environment(\.colorScheme) var scheme
    
    var plural: Bool = true
    
    var body: some View {
        Text("Long press to\nselect \(plural ? "coins" : "coin") to\ndisplay here.")
            .font(.satoshiRegular(16))
            .foregroundStyle(Color.onSurface(for: scheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
    }
}

#Preview {
    WidgetEmptyView()
}
