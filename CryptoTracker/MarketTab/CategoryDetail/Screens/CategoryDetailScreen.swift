//
//  CategoryDetailScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-29.
//

import SwiftUI

@MainActor
struct CategoryDetailScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private let category: CryptoCategory
    
    init(category: CryptoCategory) {
        self.category = category
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            ToplistView(
                currentPage: .constant(0),
                category: category,
                handleCurrencyClick: { coin in
                    AnalyticsManager.shared.log(
                        Navigate(
                            fromScreen: .categoryDetail,
                            toScreen: .cryptoDetail,
                            coinName: coin.name ?? ""
                        )
                    )
                    navigationViewModel.navPath.append(
                        NavigationScreens.CryptoDetail(
                            currencyDataModel: coin.toCryptoDetail
                        )
                    )
                }
            )
            .ignoresSafeArea(edges: .horizontal)
        }
        .navigationBarTitle(category.name ?? "", displayMode: .inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .onAppear {
            AchievementManager.shared.increment(.sectorDetailsViewed)
        }
    }
}
