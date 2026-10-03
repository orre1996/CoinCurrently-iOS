//
//  PodcastNewsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-21.
//

import SwiftUI


struct PodcastNewsView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @State private var id = UUID()
    
    let viewModel: NewsViewModelImp
    let scrollToTopActive: Bool
    let currentPage: Int?
    
    @State private var showScrollToTopButton = false
    @State private var currenciesScrollToTop = false
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(spacing: 0) {
                    let totalCount = viewModel.podcastNews?.count ?? 10

                    ForEach(0..<totalCount, id: \.self) { index in
                        let news = viewModel.podcastNews?[safely: index]
                        
                        AdaptiveButton(buttonAction: {
                            guard let url = news?.news_url, !url.isEmpty else { return }
                            
                            AchievementManager.shared.increment(.newsArticlesOpened)
                            navigationViewModel.newsUrl = url
                        }) {
                            NewsCard(
                                news: news,
                                index: index + 1,
                                totalCount: totalCount,
                                newsType: .podcast
                            )
                        }
                    }
                }
                .id(id)
                .padding(.bottom, 16)
                .onChange(of: scrollToTopActive) {
                    guard let currentPage else { return }

                    if currentPage == 2 {
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
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNewsPodcasts() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getNewsPodcasts() }
                        group.addTask { await viewModel.getAllCoins() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNewsPodcasts() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
    }
}
