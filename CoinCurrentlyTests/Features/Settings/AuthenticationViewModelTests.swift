import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("AuthenticationViewModel Tests")
struct AuthenticationViewModelTests {

    @Test("authenticate returns unlocked when authentication is disabled")
    func authenticateReturnsUnlockedWhenDisabled() async {
        let previous: Bool = SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false
        SettingsManager.shared.set(data: false, key: AppSettingKey.authenticationEnabled)
        defer { SettingsManager.shared.set(data: previous, key: AppSettingKey.authenticationEnabled) }

        let viewModel = AuthenticationViewModelImp()

        let locked = await viewModel.authenticate(toggling: false, forceAsk: false)

        #expect(locked == false)
        #expect(viewModel.isAppLocked == false)
    }

    @Test("lockApp does nothing while authentication is disabled")
    func lockAppDoesNothingWhenDisabled() async {
        let previous: Bool = SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false
        SettingsManager.shared.set(data: false, key: AppSettingKey.authenticationEnabled)
        defer { SettingsManager.shared.set(data: previous, key: AppSettingKey.authenticationEnabled) }

        let viewModel = AuthenticationViewModelImp()
        viewModel.lockApp()

        #expect(viewModel.isAppLocked == false)
        #expect(viewModel.askForAuthAgain == false)
    }
}
