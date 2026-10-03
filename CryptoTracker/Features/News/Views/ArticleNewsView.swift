//
//  ArticleNewsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-21.
//

import SwiftUI

struct ArticleNewsView: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @State private var id = UUID()
    
    let viewModel: NewsViewModelImp
    let scrollToTopActive: Bool
    let currentPage: Int?
    
    @State private var showCoinsSheet = false
    @State private var showScrollToTopButton = false
    @State private var currenciesScrollToTop = false
    @State private var previousScrollOffset: CGFloat = 0
    @State private var hasPro = false
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(spacing: 0) {
                    ToplistFilterCarouselView(
                        filters: CarouselFilter.newsFilters,
                        selectedFilter: viewModel.selectedNewsType.toCarouselFilter,
                        hasPro: hasPro,
                        newFilterSelected: { filter in
                            Task {
                                let hasPro = await viewModel.hasPro()

                                if filter.requiresPro && !hasPro {
                                    AnalyticsManager.shared.log(
                                        BuyProOpened(fromScreen: .news, action: .NewsFilter)
                                    )
                                    navigationViewModel.showBuyPro = true
                                } else if case .coins = filter {
                                    AnalyticsManager.shared.log(
                                        SheetOpened(fromScreen: .news, sheet: .coinSearch)
                                    )
                                    showCoinsSheet = true
                                } else {
                                    AnalyticsManager.shared.log(
                                        NewsFilterSelected(fromScreen: .news, filter: filter)
                                    )
                                    await viewModel.getNews(type: filter.toNewsType)
                                }
                            }
                        }
                    )
                    .padding(.top, 16)
                    
                    let totalCount = viewModel.news?.count ?? 10

                    ForEach(0..<totalCount, id: \.self) { index in
                        let currentNews = viewModel.news?[safely: index]
                        
                        AdaptiveButton(
                            buttonAction: {
                                guard let url = currentNews?.news_url, !url.isEmpty else { return }
                                
                                AnalyticsManager.shared.log(
                                    NewsOpened(fromScreen: .news)
                                )
                                AchievementManager.shared.increment(.newsArticlesOpened)

                                navigationViewModel.newsUrl = url
                            }, content: {
                                NewsCard(
                                    news: currentNews,
                                    index: index + 1,
                                    totalCount: totalCount,
                                    topPadding: index == 0 ? 16 : 32
                                )
                            }
                        )
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: safeAreaInsets.leading,
                                bottom: 0,
                                trailing: safeAreaInsets.trailing
                            )
                        )
                    }
                }
                .id(id)
                .padding(.bottom, 16)
                .onChange(of: scrollToTopActive) {
                    guard let currentPage else { return }

                    if currentPage == 0 {
                        withAnimation {
                            reader.scrollTo(id, anchor: .top)
                        }
                    }
                }
                .onChange(of: currenciesScrollToTop) {
                    withAnimation {
                        reader.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldOffset, newOffset in
            let isScrollingUp = newOffset < previousScrollOffset
            
            if newOffset > 600 && !isScrollingUp {
                showScrollToTopButton = true
            } else if newOffset < 400 || isScrollingUp {
                showScrollToTopButton = false
            }
            
            previousScrollOffset = newOffset
        }
        .overlay(alignment: .bottomTrailing) {
            if !accessibilityVoiceOverEnabled {
                ScrollUpButton(
                    action: {
                        AnalyticsManager.shared.log(
                            ScrollToTopPressed(fromScreen: .news)
                        )
                        currenciesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .animation(.none, value: viewModel.news)
        .task {
            hasPro = await viewModel.hasPro()
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNews(type: viewModel.selectedNewsType) }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    hasPro = await viewModel.hasPro()
                    
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getNews(type: viewModel.selectedNewsType) }
                        group.addTask { await viewModel.getAllCoins() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNews(type: viewModel.selectedNewsType) }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .sheet(isPresented: $showCoinsSheet) {
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .news,
                highlightId: viewModel.selectedNewsType.selectedId,
                hideId: nil,
                close: { _, symbol, _ in
                    showCoinsSheet = false
                    
                    guard let symbol else {
                        return
                    }
                    
                    AnalyticsManager.shared.log(
                        NewsFilterSelected(fromScreen: .news, filter: CarouselFilter.coins(symbol.uppercased()))
                    )
                    
                    Task {
                        await viewModel.getNews(type: NewsType.coin(symbol: symbol.uppercased()))
                    }
                }
            )
        }
    }
}
