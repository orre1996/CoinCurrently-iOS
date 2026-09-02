//
//  View+SubscriptionStatus.swift
//  CoinCurrently
//

import SwiftUI

extension View {
    /// Keeps local subscription state in sync with `StoreKitManager`.
    /// Use only when a view needs `@State` for subscription UI; otherwise read the manager directly.
    func syncSubscriptionStatus(
        _ subscription: Binding<String?>,
        expirationDate: Binding<Date?> = .constant(nil),
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) -> some View {
        modifier(
            SubscriptionStatusSyncModifier(
                subscription: subscription,
                expirationDate: expirationDate,
                storeKitManager: storeKitManager
            )
        )
    }
}

private struct SubscriptionStatusSyncModifier: ViewModifier {
    @Binding var subscription: String?
    @Binding var expirationDate: Date?
    let storeKitManager: StoreKitManager

    func body(content: Content) -> some View {
        content
            .task {
                await syncFromManager()
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionStatusDidChange)) { _ in
                Task {
                    await syncFromManager()
                }
            }
    }

    private func syncFromManager() async {
        subscription = await storeKitManager.currentSubscription
        expirationDate = await storeKitManager.subscriptionExpirationDate
    }
}
