//
//  MeasureTextSize.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/3/25.
//

import SwiftUI

struct MinimumTextSize<Content>: View where Content: View {
    let content: Content
    let text: String
    let extraSize: CGFloat
    let alignment: Alignment
    
    init(
        text: String,
        extraSize: CGFloat = 0,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.text = text
        self.extraSize = extraSize
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: alignment) {
            Text(text)
                .padding(.horizontal, extraSize / 2)
                .accessibilityHidden(true)
                .opacity(0)
                .fixedSize(horizontal: true, vertical: false)
            
            content
        }
    }
}
