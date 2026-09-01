//
//  HeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-10.
//

import SwiftUI

struct HeaderView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let title: String
    var tabBarItems: [AnyView] = []
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .font(verticalSizeClass == .compact ? .semibold26 : .semibold32)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            ForEach(0..<tabBarItems.count, id: \.self) { index in
                if let item = tabBarItems[safely: index] {
                    item
                }
            }
        }
        .animation(.none, value: UUID())
        .padding(.horizontal, 16)
        .frame(height: verticalSizeClass == .compact ? 40 : 52)
        .foregroundColor(.onSurface)
    }
}
