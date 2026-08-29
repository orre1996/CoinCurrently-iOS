//
//  Separator.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/3/26.
//

import SwiftUI

struct Separator: View {
    var height: CGFloat = 1
    var color: Color = Color.outlineVariant
    
    var body: some View {
        Rectangle()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .center)
            .foregroundStyle(color)
    }
}

struct VerticalSeparator: View {
    var width: CGFloat = 1
    var color: Color = Color.outlineVariant
    
    var body: some View {
        Rectangle()
            .frame(minWidth: width, maxWidth: width, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .foregroundStyle(color)
            .ignoresSafeArea(edges: .horizontal)
    }
}
