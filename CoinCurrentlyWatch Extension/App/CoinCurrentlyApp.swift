//
//  CoinCurrentlyApp.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-23.
//

import SwiftUI
import WatchKit
import ClockKit

@main
struct CoinCurrentlyApp: App {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var scheme
    
    @StateObject private var connectivityVM = WatchConnectivityViewModel.shared
    
    @State private var viewModel = NavigationViewModel()
    
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) private var extensionDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationStack(path: Binding(
                get: { viewModel.navPath },
                set: { viewModel.navPath = $0 }
            )) {
                LoadingScreen()
                    .navigationDestination(for: NavigationScreens.self, destination: { screen in
                        if screen == .MainFlow {
                            CurrencyToplistScreen()
                                .environment(viewModel)
                        } else if screen == .CurrencySelector {
                            WatchCurrencySelectorScreen()
                                .environment(viewModel)
                        } else if case .CryptoDetail(let currencyDataModel) = screen {
                            CurrencyDetailScreen(
                                cryptoInfo: currencyDataModel
                            )
                            .environment(viewModel)
                        }
                    })
                    .environment(viewModel)
                    .colorScheme(.light)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .preferredColorScheme(.dark)
            }
            .task {
                viewModel.navPath.append(.MainFlow)
                
                _ = await extensionDelegate.applicationDidFinishLaunching(refresh: true)
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    connectivityVM.isActive = true
                case .inactive, .background:
                    connectivityVM.isActive = false
                @unknown default:
                    break
                }
            }
        }
    }
}
