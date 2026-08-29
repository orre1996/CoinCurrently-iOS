//
//  SafeAreaInsetsKey.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-04-26.
//

import SwiftUI
import UIKit

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets { EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

private struct SafeAreaInsetsInjectionModifier: ViewModifier {
    @State private var insets = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .environment(\.safeAreaInsets, insets)
            .onAppear(perform: refreshInsets)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                refreshInsets()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshInsets()
            }
    }

    private func refreshInsets() {
        Task { @MainActor in
            let newInsets = (UIApplication.shared.window?.safeAreaInsets ?? .zero).insets
            guard insets != newInsets else { return }
            insets = newInsets
        }
    }
}

extension View {
    func injectSafeAreaInsetsEnvironment() -> some View {
        modifier(SafeAreaInsetsInjectionModifier())
    }
}

private extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension EdgeInsets {
    @MainActor
    var resolvedBottom: CGFloat {
        bottom > 0 ? bottom : UIDevice.current.getSafeAreaBottom()
    }

    @MainActor
    var resolvedTop: CGFloat {
        top > 0 ? top : UIDevice.current.getSafeAreaTop()
    }
}
