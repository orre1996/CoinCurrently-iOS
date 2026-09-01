//
//  NewsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-24.
//

import SwiftUI

struct NewsScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var viewModel = NewsViewModelImp()
    @State private var scrollToTopActive = false
    @State private var showCoinsList = false
    @State private var currentPage: Int? = 0
    @State private var showBackground = false
    @State private var viewID = UUID()
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            ZStack {
                VStack(spacing: 0) {
                    PageSelectorView(currentPage: $currentPage, titles: ["Articles", "Videos", "Podcasts"], pageSelected: { page in
                        withAnimation {
                            currentPage = page
                        }
                        
                        Task {
                            if page == 0 {
                                await viewModel.getNews(type: viewModel.selectedNewsType)
                            } else if page == 1 {
                                await viewModel.getNewsVideos()
                            } else if page == 2 {
                                await viewModel.getNewsPodcasts()
                            }
                        }
                    })
                    
                    Separator()
                    
                    GeometryReader { reader in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 0) {
                                ArticleNewsView(
                                    viewModel: viewModel,
                                    scrollToTopActive: scrollToTopActive,
                                    currentPage: currentPage
                                )
                                .frame(width: reader.size.width, height: reader.size.height)
                                .id(0)
                                
                                VideoNewsView(
                                    viewModel: viewModel,
                                    scrollToTopActive: scrollToTopActive,
                                    currentPage: currentPage
                                )
                                .padding(
                                    EdgeInsets(
                                        top: 0,
                                        leading: safeAreaInsets.leading,
                                        bottom: 0,
                                        trailing: safeAreaInsets.trailing
                                    )
                                )
                                .frame(width: reader.size.width, height: reader.size.height)
                                .id(1)
                                
                                PodcastNewsView(
                                    viewModel: viewModel,
                                    scrollToTopActive: scrollToTopActive,
                                    currentPage: currentPage
                                )
                                .padding(
                                    EdgeInsets(
                                        top: 0,
                                        leading: safeAreaInsets.leading,
                                        bottom: 0,
                                        trailing: safeAreaInsets.trailing
                                    )
                                )
                                .frame(width: reader.size.width, height: reader.size.height)
                                .id(2)
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $currentPage)
                    }
                    .ignoresSafeArea(edges: .horizontal)
                }
                .padding(.top, 16)
            }
            .id(viewID)
            .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
                if let index = notification.userInfo?[String.tabIndex] as? Int {
                    if index == 3 {
                        AnalyticsManager.shared.log(
                            TabBarDoubleTapped(fromScreen: .news)
                        )

                        scrollToTopActive.toggle()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .reloadViews, object: nil)) { notification in
                viewID = UUID()
            }
            .onChange(of: currentPage) {
                AnalyticsManager.shared.log(
                    NewsTabSelected(fromScreen: .news, tab: (currentPage ?? 0).newsTab)
                )
            }
        }
        .task {
            await viewModel.setStartData()
        }
        .id(colorBlindnessFilterEnabled)
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
}
