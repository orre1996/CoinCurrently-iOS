//
//  AdaptiveStack.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-12-12.
//

import SwiftUI

struct AdaptiveStack<Content>: View where Content: View {
    let content: Content
    let spacing: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let isHorizontal: Bool

    init(isHorizontal: Bool,
         spacing: CGFloat = 0,
         horizontalAlignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         @ViewBuilder content: () -> Content) {
        self.isHorizontal = isHorizontal
        self.spacing = spacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.content = content()
    }

    var body: some View {
        if isHorizontal {
            HStack(alignment: verticalAlignment, spacing: spacing) { content }
        } else {
            VStack(alignment: horizontalAlignment, spacing: spacing) { content }
        }
    }
}

struct AdaptiveButton<Content>: View where Content: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled

    let buttonAction: () -> Void
    let content: Content

    init(buttonAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.buttonAction = buttonAction
        self.content = content()
    }
    
    var body: some View {
        if accessibilityVoiceOverEnabled {
            content
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    buttonAction()
                }
        } else {
            Button(action: {
                buttonAction()
            }, label: {
                content
            })
        }
    }
}
