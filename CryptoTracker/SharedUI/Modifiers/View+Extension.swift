//
//  View+Extension.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-01-10.
//

import Foundation
import SwiftUI
import UIKit

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct DelayTouchesModifier: ViewModifier {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled

    func body(content: Content) -> some View {
        if accessibilityVoiceOverEnabled {
            content
        } else {
            Button(action: {}) {
                content
                    .highPriorityGesture(TapGesture())
            }
            .buttonStyle(NoButtonStyle())
        }
    }
}

extension View {
#if os(iOS)
    var snapshot: UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = Color.surface.uiColor

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
#endif
    
    func delayTouches() -> some View {
        modifier(DelayTouchesModifier())
    }
    
    func anyView() -> AnyView {
        AnyView(self)
    }
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder func whenBelowIOS26<Content: View>(@ViewBuilder content: (Self) -> Content) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            content(self)
        }
    }

    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: {
            onChange($0)
        }
    }

    @ViewBuilder
    func optionalGlassEffect(
        color: Color = Color.surfaceContainerHigh,
        radius: CGFloat = 8,
        isInteractive: Bool = false,
        forceOpaque: Bool = false
    ) -> some View {
        #if os(iOS)
        if forceOpaque {
            self
                .background(color)
                .cornerRadius(radius)
        } else if #available(iOS 26, *) {
            let glass: Glass = isInteractive
                ? .clear.interactive().tint(color)
                : .clear.tint(color)
            self.glassEffect(glass, in: .rect(cornerRadius: radius))
        } else {
            self
                .background(color)
                .cornerRadius(radius)
        }
        #else
        self
            .background(color)
            .cornerRadius(radius)
        #endif
    }

    @ViewBuilder
    func optionalGlassEffectContainer(spacing: CGFloat = 8) -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                self
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if os(iOS)
extension View {
    func endTextEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    func onAppDidBecomeActive(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            action()
        }
    }

    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }

    /// Disables all dismissal gestures (swipe-from-edge, zoom swipe-down, pinch) when `disabled` is true.
    /// Use when dragging a graph to prevent accidental dismissal on iPad.
    func navigationPopGestureDisabled(_ disabled: Bool) -> some View {
        self
            .interactiveDismissDisabled(disabled)
            .background {
                NavigationDismissalGestureDisabler(disabled: disabled)
            }
    }
}

private struct NavigationDismissalGestureDisabler: UIViewControllerRepresentable {
    let disabled: Bool

    private static let dismissTypes: Set<String> = [
        "_UIParallaxTransitionPanGestureRecognizer",
        "_UISwipeDownGestureRecognizer",
        "_UIContentSwipeDismissGestureRecognizer",
        "_UITransformGestureRecognizer"
    ]

    @MainActor
    private static func collectGestures(
        from view: UIView?,
        chartGestures: inout [UIGestureRecognizer],
        dismissGestures: inout [UIGestureRecognizer]
    ) {
        guard let view else { return }
        for gesture in view.gestureRecognizers ?? [] {
            if gesture is MultiTouchGestureRecognizer {
                chartGestures.append(gesture)
            } else if dismissTypes.contains(String(describing: type(of: gesture))) {
                dismissGestures.append(gesture)
            }
        }
        for subview in view.subviews {
            collectGestures(from: subview, chartGestures: &chartGestures, dismissGestures: &dismissGestures)
        }
    }

    @MainActor
    private static func setDismissGestureEnabled(_ enabled: Bool, from rootView: UIView?) {
        for view in sequence(first: rootView, next: { $0?.superview }) {
            guard let view else { break }
            for gesture in view.gestureRecognizers ?? [] {
                if dismissTypes.contains(String(describing: type(of: gesture))) {
                    gesture.isEnabled = enabled
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(requirementAdded: false) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        return vc
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        let disabled = self.disabled
        let coordinator = context.coordinator
        Task { @MainActor in
            for attempt in 0..<5 {
                guard let parentVC = viewController.parent else {
                    try? await Task.sleep(nanoseconds: 50_000_000 * UInt64(attempt + 1))
                    continue
                }
                guard let navController = parentVC.navigationController,
                      navController.topViewController == parentVC else {
                    try? await Task.sleep(nanoseconds: 50_000_000 * UInt64(attempt + 1))
                    continue
                }

                navController.interactivePopGestureRecognizer?.isEnabled = !disabled

                var chartGestures: [UIGestureRecognizer] = []
                var dismissGestures: [UIGestureRecognizer] = []
                Self.collectGestures(from: parentVC.view, chartGestures: &chartGestures, dismissGestures: &dismissGestures)

                if !coordinator.requirementAdded, !chartGestures.isEmpty, !dismissGestures.isEmpty {
                    for dismiss in dismissGestures {
                        for chart in chartGestures {
                            dismiss.require(toFail: chart)
                        }
                    }
                    coordinator.requirementAdded = true
                }

                Self.setDismissGestureEnabled(!disabled, from: parentVC.view)
                return
            }
        }
    }

    @MainActor
    static func dismantleUIViewController(_ viewController: UIViewController, coordinator: Coordinator) {
        guard let parentVC = viewController.parent else { return }
        parentVC.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        Self.setDismissGestureEnabled(true, from: parentVC.view)
    }

    class Coordinator {
        var requirementAdded: Bool
        init(requirementAdded: Bool) { self.requirementAdded = requirementAdded }
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 2
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                asyncMain {
                    action(UIDevice.current.orientation)
                }
            }
    }
}

#endif
