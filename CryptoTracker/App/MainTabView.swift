//
//  MainTabView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-08.
//

import SwiftUI

struct MainTabView: View {
    @Environment(NavigationViewModel.self) private var viewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var appLanguage = AppLanguagePreference.stored
    
    var binding: Binding<Int> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectedTab = $0 }
        )
    }
    
    var body: some View {
        TabView(selection: binding) {
            Tab(tabTitle("Home"), image: .homeTab, value: 0) {
                HomeScreen()
            }
            
            Tab(tabTitle("Portfolio"), image: .portfolioTab, value: 1) {
                PortfolioScreen()
            }
            
            Tab(tabTitle("Market"), image: .marketTab, value: 2) {
                MarketScreen()
            }
            
            Tab(tabTitle("Settings"), image: .settingsTab, value: 3) {
                SettingsScreen()
            }
        }
        .accentColor(.onSurface)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
    }

    private func tabTitle(_ key: String) -> String {
        Localization.string(key, locale: appLanguage.resolve().locale)
    }
}
