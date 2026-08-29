//
//  ViewRect.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-06-10.
//

import SwiftUI

struct ViewRectModifier: ViewModifier {
    let action: (CGRect) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry -> Color in
                    asyncMain {
                        let rect = geometry.frame(in: .named("OuterV"))
                        action(rect)
                    }

                    return .clear
                }
            )
    }
}

extension View {
    func viewRect(perform action: @escaping (CGRect) -> Void) -> some View {
        self.modifier(ViewRectModifier(action: action))
    }
}
