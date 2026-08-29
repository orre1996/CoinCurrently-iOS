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
    
    var binding: Binding<Int> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectedTab = $0 }
        )
    }
    
    var body: some View {
        TabView(selection: binding) {
            Tab("Home", image: .homeTab, value: 0) {
                HomeScreen()
            }
            
            Tab("Portfolio", image: .portfolioTab, value: 1) {
                PortfolioScreen()
            }
            
            Tab("Market", image: .marketTab, value: 2) {
                MarketScreen()
            }
            
            Tab("News", image: .newsTab, value: 3) {
                NewsScreen()
            }
            
            Tab("Settings", image: .settingsTab, value: 4) {
                SettingsScreen()
            }
        }
        .accentColor(.onSurface)
    }
}
