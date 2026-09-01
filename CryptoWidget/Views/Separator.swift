//
//  Separator.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-09.
//

import SwiftUI

struct Separator: View {
    @Environment(\.colorScheme) var scheme

    var height: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: height,
                maxHeight: height,
                alignment: .center
            )
            .foregroundStyle(.tertiary)
    }
}

struct VerticalSeparator: View {
    @Environment(\.colorScheme) var scheme

    var width: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .frame(
                minWidth: width,
                maxWidth: width,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center
            )
            .foregroundStyle(.tertiary)
    }
}
