//
//  VideoNewsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-21.
//

import SwiftUI

struct VideoNewsView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
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
                    let totalCount = viewModel.newsVideos?.count ?? 10
                    
                    ForEach(0..<totalCount, id: \.self) { index in
                        let currentNews = viewModel.newsVideos?[safely: index]
                        
                        AdaptiveButton(buttonAction: {
                            guard let url = currentNews?.news_url, !url.isEmpty else { return }
                            
                            navigationViewModel.newsUrl = url
                        }, content: {
                            NewsCard(
                                news: currentNews,
                                index: index + 1,
                                totalCount: totalCount
                            )
                        })
                    }
                }
                .id(id)
                .padding(.bottom, 16)
                .onChange(of: scrollToTopActive) {
                    guard let currentPage else { return }
                    
                    if currentPage == 1 {
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
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNewsVideos() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getNewsVideos() }
                        group.addTask { await viewModel.getAllCoins() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getNewsVideos() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .animation(.none, value: currentPage)
    }
}
