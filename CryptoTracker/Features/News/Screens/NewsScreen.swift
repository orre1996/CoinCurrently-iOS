//
//  NewsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-24.
//

import SwiftUI

struct NewsScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled

    @State private var viewModel = NewsViewModelImp()
    @State private var showScrollToTopButton = false
    @State private var scrollToTop = false
    @State private var previousScrollOffset: CGFloat = 0
    @State private var viewID = UUID()
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()

            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(spacing: 0) {
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
                                },
                                content: {
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
                    .id("news-top")
                    .padding(.bottom, 16)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newOffset in
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
                                scrollToTop.toggle()
                            },
                            isVisible: showScrollToTopButton
                        )
                    }
                }
                .onChange(of: scrollToTop) {
                    withAnimation {
                        reader.scrollTo("news-top", anchor: .top)
                    }
                }
            }
        }
        .id("\(viewID)-\(colorBlindnessFilterEnabled)")
        .task {
            await viewModel.getNews()
        }
        .refreshable {
            await viewModel.getNews()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.getNews() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 3 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .news)
                )
                scrollToTop.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadViews, object: nil)) { _ in
            viewID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            Task { await viewModel.getNews() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
}
