//
//  HomeScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-14.
//

import SwiftUI

struct HomeScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    
    @State private var viewModel = HomeViewModelImp()
    @State private var id = UUID()
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                ScrollView {
                    ScrollViewReader { swReader in
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            if let title = viewModel.promotionTitle,
                               let message = viewModel.promotionMessage {
                                PremiumView(
                                    title: title,
                                    message: message,
                                    accessibleMessage: viewModel.promotionMessageAccessible,
                                    timeLeft: viewModel.offerTimeLeft,
                                    timeLeftDate: viewModel.offerTimeLeftDate,
                                    viewPressed: {
                                        AnalyticsManager.shared.log(
                                            BuyProOpened(fromScreen: .home, action: .HomePromotion)
                                        )
                                        showBuyPro()
                                    }, closeAction: { message in
                                        viewModel.premiumViewClosed(title: title)
                                    }
                                )
                            }
                            
                            MarketStatsView(
                                globalMarket: viewModel.globalMarket,
                                gasFees: viewModel.gasFees,
                                fearGreed: viewModel.fearGreed,
                                navigateToGlobalMarket: {
                                    AnalyticsManager.shared.log(
                                        Navigate(fromScreen: .home, toScreen: .globalMarket)
                                    )
                                    navigationViewModel.navPath.append(.GlobalMarket)
                                }, navigateToGasFees: {
                                    AnalyticsManager.shared.log(
                                        Navigate(fromScreen: .home, toScreen: .gasFees)
                                    )
                                    navigationViewModel.navPath.append(.GasFees)
                                }, navigateToFearGreed: {
                                    AnalyticsManager.shared.log(
                                        Navigate(fromScreen: .home, toScreen: .fearGreed)
                                    )
                                    navigationViewModel.navPath.append(.FearGreed)
                                }
                            )
                            
                            Section(header: sectionHeader) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: 0) {
                                        ForEach(CarouselFilter.homeFilters, id: \.self) { filter in
                                            ToplistCategoryView(
                                                toplist: viewModel.getList(filter: filter),
                                                favoriteList: viewModel.favoritesList,
                                                showViewAll: filter.shouldShowViewAll,
                                                carouselFilter: filter,
                                                toggleFavorite: {
                                                    await viewModel.favouriteButtonPressed(toplistItem: $0)
                                                },
                                                navigateToCryptoDetail: { coin in
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
                                                        Navigate(fromScreen: .home, toScreen: .cryptoDetail, coinName: coin.name)
                                                    )
                                                    navigationViewModel.navPath.append(
                                                        .CryptoDetail(
                                                            currencyDataModel: coin.toCryptoDetail
                                                        )
                                                    )
                                                },
                                                viewAllPressed: {
                                                    Task {
                                                        AnalyticsManager.shared.log(
                                                            ViewAll(fromScreen: .home, filter: viewModel.selectedFilter ?? .topCoins)
                                                        )
                                                        await viewModel.toplistSeeAll()
                                                        navigationViewModel.selectedTab = 2
                                                    }
                                                },
                                                refresh: {
                                                    await viewModel.downloadData()
                                                }
                                            )
                                            .frame(width: proxy.size.width)
                                            .accessibilityHidden(filter != viewModel.selectedFilter)
                                        }
                                    }
                                    .scrollTargetLayout()
                                }
                                .scrollTargetBehavior(.viewAligned)
                                .scrollPosition(id: $viewModel.selectedFilter)
                                .animation(.default, value: viewModel.selectedFilter)
                            }
                        }
                        .animation(.default, value: viewModel.promotionTitle)
                        .padding(.top, 16)
                        .id(id)
                        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
                            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 0 {
                                AnalyticsManager.shared.log(
                                    TabBarDoubleTapped(fromScreen: .home)
                                )

                                withAnimation {
                                    swReader.scrollTo(id, anchor: .top)
                                }
                            }
                        }
                    }
                }
                .onChange(of: viewModel.selectedFilter) {
                    Task {
                        if !viewModel.consumeSkipNextHomeFilterAnalytics() {
                            AnalyticsManager.shared.log(
                                HomeFilterSelected(fromScreen: .home, filter: viewModel.selectedFilter ?? .topCoins)
                            )
                        }
                        await viewModel.downloadData()
                    }
                }
                .refreshable {
                    await downloadData()
                }
            }
            
            Color.surface
                .frame(maxWidth: .infinity, minHeight: safeAreaInsets.top, maxHeight: safeAreaInsets.top)
                .ignoresSafeArea()
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .ignoresSafeArea(edges: [.leading, .trailing])
        .task {
            await downloadData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await downloadData(includeSetStartData: false)
                }
            default:
                break
            }
        }
        .id(colorBlindnessFilterEnabled)
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
        .onReceive(NotificationCenter.default.publisher(for: .downloadNewToplist, object: nil)) { _ in
            Task {
                await downloadData()
            }
        }
    }
    
    private var sectionHeader: some View {
        VStack(spacing: 0) {
            ToplistFilterCarouselView(
                filters: CarouselFilter.homeFilters,
                selectedFilter: viewModel.selectedFilter ?? .topCoins,
                newFilterSelected: {
                    viewModel.selectedFilter = $0
                }
            )
            .padding(.top, 16)
            
            ToplistHeaderView(
                selectedChangeOption: .sevenDays
            )
            .opacity(viewModel.selectedFilter == .favorites && viewModel.favoritesList.isEmpty ? 0 : 1)
            .animation(.default, value: viewModel.selectedFilter)
        }
        .padding(.bottom, 16)
        .background(Color.surface)
    }
    
    private func downloadData(includeSetStartData: Bool = true) async {
        await withTaskGroup(of: Void.self) { group in
            if includeSetStartData {
                group.addTask { await viewModel.setStartData() }
            }
            group.addTask { await viewModel.downloadData() }
            group.addTask { await viewModel.getGlobalMarket() }
            group.addTask { await viewModel.getGasFees() }
            group.addTask { await viewModel.getFearGreed() }
        }
    }
}
