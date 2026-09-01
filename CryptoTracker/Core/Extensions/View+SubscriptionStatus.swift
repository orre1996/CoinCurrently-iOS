//
//  View+SubscriptionStatus.swift
//  CoinCurrently
//

import SwiftUI

extension View {
    /// Keeps a local `String?` in sync with `StoreKitManager.currentSubscription`.
    /// Use only when a view needs `@State` for subscription UI; otherwise read the manager directly.
    func syncSubscriptionStatus(
        _ subscription: Binding<String?>,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) -> some View {
        modifier(
            SubscriptionStatusSyncModifier(
                subscription: subscription,
                storeKitManager: storeKitManager
            )
        )
    }
}

private struct SubscriptionStatusSyncModifier: ViewModifier {
    @Binding var subscription: String?
    let storeKitManager: StoreKitManager

    func body(content: Content) -> some View {
        content
            .task {
                subscription = await storeKitManager.currentSubscription
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionStatusDidChange)) { _ in
                Task {
                    subscription = await storeKitManager.currentSubscription
                }
            }
    }
}
