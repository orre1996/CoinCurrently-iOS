//
//  MarketScreen.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-11-12.
//

import SwiftUI

@MainActor
struct MarketScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var currentPage: Int? = 0
    @State private var viewID = UUID()
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false

    private let categories = ["Coins", "NFTs", "Treasuries", "Sectors", "Exchanges", "Derivatives"]
    private let sectorsPageIndex = 3
    private let exchangesPageIndex = 4
    private let derivativesPageIndex = 5
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                PageSelectorView(
                    currentPage: $currentPage,
                    titles: categories,
                    pageSelected: { page in
                        withAnimation {
                            currentPage = page
                        }
                    }
                )
                
                Separator()
                
                tabView
            }
            .animation(.default, value: currentPage)
            .padding(.top, 16)
            .id(viewID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadViews, object: nil)) { notification in
            viewID = UUID()
        }
        .onChange(of: currentPage) { _, newPage in
            guard let page = newPage, categories.indices.contains(page) else { return }
            AnalyticsManager.shared.log(
                TabChanged(fromScreen: .market, selectedTabName: categories[page])
            )
        }
        .id(colorBlindnessFilterEnabled)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
    
    private var tabView: some View {
        GeometryReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ToplistView(
                        currentPage: $currentPage,
                        handleCurrencyClick: { coin in
                            AnalyticsManager.shared.log(
                                Navigate(
                                    fromScreen: .toplist,
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
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(0)
                    .accessibilityHidden(currentPage != 0)
                    
                    NFTListView(
                        currentPage: currentPage,
                        nftSelected: { nft in
                            AnalyticsManager.shared.log(
                                Navigate(
                                    fromScreen: .nfts,
                                    toScreen: .nftDetail,
                                    nftName: nft.name ?? ""
                                )
                            )

                            navigationViewModel.navPath.append(
                                NavigationScreens.NFTDetail(
                                    nftToplist: nft
                                )
                            )
                        }
                    )
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(1)
                    .accessibilityHidden(currentPage != 1)
                    
                    TreasuriesListView(
                        currentPage: currentPage,
                        treasurySelected: { treasury in
                            Task {
                                guard let treasuryId = await PublicTreasuryRepositoryImp.shared.entityId(
                                    for: treasury.holder,
                                    entity: treasury.entity
                                ) else {
                                    return
                                }

                                AnalyticsManager.shared.log(
                                    Navigate(
                                        fromScreen: .treasuries,
                                        toScreen: .treasuryDetail,
                                        treasuryName: treasury.holder.name ?? ""
                                    )
                                )

                                navigationViewModel.navPath.append(
                                    NavigationScreens.TreasuryDetail(
                                        treasuryId: treasuryId,
                                        treasuryDetail: treasury.holder.toTreasuryDetail(
                                            treasuryId: treasuryId,
                                            coinId: treasury.coinId
                                        ),
                                        coinId: treasury.coinId
                                    )
                                )
                            }
                        }
                    )
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(2)
                    .accessibilityHidden(currentPage != 2)
                    
                    CategoriesListView(
                        currentPage: currentPage,
                        categorySelected: { category in
                            AnalyticsManager.shared.log(
                                Navigate(
                                    fromScreen: .sectors,
                                    toScreen: .categoryDetail,
                                    sectorName: category.name ?? ""
                                )
                            )

                            navigationViewModel.navPath.append(
                                NavigationScreens.CategoryDetail(
                                    category: category
                                )
                            )
                        }
                    )
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(sectorsPageIndex)
                    .accessibilityHidden(currentPage != sectorsPageIndex)
                    
                    ExchangesView(
                        currentPage: currentPage,
                        exchangeClicked: { exchange in
                            AnalyticsManager.shared.log(
                                Navigate(
                                    fromScreen: .exchanges,
                                    toScreen: .exchangeDetail,
                                    exchangeName: exchange.name ?? ""
                                )
                            )

                            navigationViewModel.navPath.append(
                                NavigationScreens.ExchangeDetail(
                                    exchange: exchange.toExchange
                                )
                            )
                        }
                    )
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(exchangesPageIndex)
                    .accessibilityHidden(currentPage != exchangesPageIndex)
                    
                    DerivativesListView(
                        currentPage: currentPage,
                        derivativeSelected: { derivative in
                            AnalyticsManager.shared.log(
                                Navigate(
                                    fromScreen: .derivatives,
                                    toScreen: .derivativeDetail,
                                    derivativeName: derivative.name ?? ""
                                )
                            )

                            navigationViewModel.navPath.append(
                                NavigationScreens.DerivativeDetail(
                                    derivative: derivative,
                                )
                            )
                        }
                    )
                    .frame(width: reader.size.width, height: reader.size.height)
                    .id(derivativesPageIndex)
                    .accessibilityHidden(currentPage != derivativesPageIndex)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
        }
        .ignoresSafeArea(edges: .horizontal)
    }
}
