//
//  ShimmeringModifier.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-31.
//

import SwiftUI

struct ShimmeringModifier: ViewModifier {
    @State private var show = false
    
    func body(content: Content) -> some View {
        content
            .mask(
                Capsule()
                    .fill(LinearGradient(gradient: .init(colors: [.clear, .onSurface, .clear]), startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.init(degrees: 180))
                    .offset(x: show ? -380 : 380)
            )
            .animation(.linear(duration: 2), value: show)
            .onAppear {
                show.toggle()

                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    Task { @MainActor in
                        show.toggle()
                    }
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmeringModifier())
    }
}
