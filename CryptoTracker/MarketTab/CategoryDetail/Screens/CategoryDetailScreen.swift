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
    @Environment(\.openURL) private var openURL
    
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
                    if coin.symbol == "Secret message" {
                        Task {
                            let secret: HiddenSecret? = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message)
                            if let urlString = secret?.secret_url, let url = URL(string: urlString) {
                                openURL(url)
                            }
                        }
                        
                        return
                    }

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
