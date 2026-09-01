//
//  StartTabScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-28.
//

import SwiftUI

struct StartTabScreen: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @ScaledMetric private var scale: CGFloat = 1

    @State private var selectedTab: StartTab = SettingsManager.shared.get(key: AppSettingKey.startTab) ?? .home
    @State private var selectedMarketPage: StartMarketPage = SettingsManager.shared.get(key: AppSettingKey.startMarketPage) ?? .currencies

    private let items: [StartTab] = [.lastUsed, .home, .portfolio, .market, .news, .more]

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0) {
                HeaderViewNavigated(presentationMode: presentationMode, title: "Start tab")
                
                Separator()
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(items, id: \.self.rawValue) { tab in
                            let index = items.firstIndex(of: tab) ?? 0
                            
                            StartTabView(tab: tab,
                                         index: index,
                                         totalCount: items.count,
                                         selectedTab: selectedTab,
                                         selectedMarketPage: selectedMarketPage,
                                         tabAction: { tab in
                                tabSelected(tab: tab)
                            }, pageAction: { page in
                                selectedMarketPage = page
                                SettingsManager.shared.set(data: page, key: AppSettingKey.startMarketPage)
                            })
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    private func tabSelected(tab: StartTab) {
        withAnimation {
            if selectedTab != .market {
                selectedMarketPage = .currencies
                SettingsManager.shared.set(data: StartMarketPage.currencies, key: AppSettingKey.startMarketPage)
            }
            
            selectedTab = tab
        }

        SettingsManager.shared.set(data: tab, key: AppSettingKey.startTab)
    }
}
