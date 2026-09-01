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
        Text("Long press and \"Edit Widget\" to\nselect \(plural ? "coins" : "a coin") to display here.")
        .font(.satoshiRegular(16))
        .foregroundStyle(Color.onSurface(for: scheme))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
    }
}
