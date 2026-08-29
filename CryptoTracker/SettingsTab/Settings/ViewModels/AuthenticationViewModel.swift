//
//  AuthenticationViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-10-02.
//

import SwiftUI
import LocalAuthentication

@MainActor
protocol AuthenticationViewModel {
    var isAppLocked: Bool { get set }
    var showLoadingScreen: Bool { get set }
    var askForAuthAgain: Bool { get set }
    var showError: Bool { get set }

    func authenticate(toggling: Bool, forceAsk: Bool) async -> Bool
    func lockApp()
}

@MainActor @Observable
final class AuthenticationViewModelImp: AuthenticationViewModel, ObservableObject {
    var isAppLocked = false
    var showLoadingScreen = false
    var askForAuthAgain = false
    var showError = false
    
    init() {
        isAppLocked = SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false
    }
    
    // Completion bool is if it's locked
    func authenticate(toggling: Bool = false, forceAsk: Bool = false) async -> Bool {
        if !(SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false) && !forceAsk {
            return false
        }
        
        if !toggling && !(SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false) && !forceAsk {
            return false
        }

        let context = LAContext()
        var error: NSError?
        
        return await withCheckedContinuation { continuation in
            // check whether biometric authentication is possible
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                // it's possible, so go ahead and use it
                let reason = "Unlock to access the app"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                    guard success else { return }

                    Task { @MainActor in
                        self.isAppLocked = false
                        self.askForAuthAgain = false
                    }
                    
                    if success {
                        continuation.resume(returning: false)
                    }
                }
            } else {
                Task { @MainActor in
                    showSnackBar(
                        message: "Something went wrong. Make sure Face ID/Touch ID is enabled and try again.",
                        type: .failure
                    )
                }
                    
                continuation.resume(returning: true)
            }
        }
    }
    
    func lockApp() {
        guard SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false else { return }

        isAppLocked = true
        askForAuthAgain = true
        showError = false
    }
}
