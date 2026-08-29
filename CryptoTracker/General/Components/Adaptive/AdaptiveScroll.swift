//
//  AdaptiveScroll.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-02-09.
//

import SwiftUI

struct AdaptiveScroll<Content>: View where Content: View {
    private let isScrollable: Bool
    private let direction: Axis.Set
    private let showsIndicator: Bool
    private let content: Content

    init(
        isScrollable: Bool,
        direction: Axis.Set = .vertical,
        showsIndicator: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.isScrollable = isScrollable
        self.direction = direction
        self.showsIndicator = showsIndicator
        self.content = content()
    }

    var body: some View {
        if isScrollable {
            ScrollView(direction, showsIndicators: showsIndicator) {
                content
            }
        } else {
            content
        }
    }
}
