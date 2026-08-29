//
//  ToplistView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-18.
//

import SwiftUI

struct ToplistView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @Binding var currentPage: Int?
    let handleCurrencyClick: (Toplist) -> Void
    
    @State private var viewModel: ToplistViewModelImp
    @State private var showScrollToTopButton = false
    @State private var currenciesScrollToTop = false
    @State private var isSearchShowing = false
    @State private var isSortShowing = false
    @State private var isPriceChangeShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0

    init(
        currentPage: Binding<Int?>,
        category: CryptoCategory? = nil,
        handleCurrencyClick: @escaping (Toplist) -> Void
    ) {
        _currentPage = currentPage
        _viewModel = State(initialValue: ToplistViewModelImp(category: category))
        self.handleCurrencyClick = handleCurrencyClick
    }
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.category != nil {
                        GlobalMarketSummaryView(
                            marketCap: viewModel.category?.market_cap,
                            changePercent: viewModel.category?.market_cap_change_24h,
                            selectedTimeframe: .aDay
                        )
                        .padding(
                            EdgeInsets(
                                top: 16,
                                leading: 16 + safeAreaInsets.leading,
                                bottom: 0,
                                trailing: 16 + safeAreaInsets.trailing
                            )
                        )
                    }
                    
                    filterButtons
                    
                    #if DEBUG
                    heatmapButton
                    #endif
                    
                    ToplistHeaderView(
                        selectedChangeOption: viewModel.selectedPriceChangeOption
                    )
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 0,
                            bottom: 6,
                            trailing: 0
                        )
                    )
                    
                    Group {
                        if viewModel.toplist.isEmpty {
                            tempList
                        } else {
                            realList
                        }
                    }
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 16 + safeAreaInsets.leading,
                            bottom: 0,
                            trailing: 16 + safeAreaInsets.trailing
                        )
                    )
                }
                .padding(.bottom, 16)
                .id(id)
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
        .if(viewModel.category != nil) { view in
            view.ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .bottomTrailing) {
            if !accessibilityVoiceOverEnabled {
                ScrollUpButton(
                    action: {
                        AnalyticsManager.shared.log(
                            ScrollToTopPressed(fromScreen: .toplist)
                        )
                        currenciesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .task {
            await viewModel.setStartData()
            await viewModel.getToplist(
                newSortOption: viewModel.selectedSortOption,
                newPriceChangeOption: viewModel.selectedPriceChangeOption
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.getToplist(
                        newSortOption: viewModel.selectedSortOption,
                        newPriceChangeOption: viewModel.selectedPriceChangeOption
                    )
                }
            default:
                break
            }
        }
        .refreshable {
            await viewModel.getToplist(
                newSortOption: viewModel.selectedSortOption,
                newPriceChangeOption: viewModel.selectedPriceChangeOption
            )
        }
        .sheet(isPresented: $isSearchShowing) {
            SearchScreen(
                screenCase: .search(list: .coins),
                fromScreen: .toplist,
                isSheet: true,
                highlightId: nil,
                hideId: nil,
                isSearch: true,
                close: { _, _, _ in }
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: viewModel.category == nil ? SortOption.toplistOptions : SortOption.sectorOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .toplist, option: option)
                    )
                    
                    Task {
                        await viewModel.getToplist(
                            newSortOption: option,
                            newPriceChangeOption: viewModel.selectedPriceChangeOption
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $isPriceChangeShowing) {
            PriceChangeSheet(
                selectedPriceChangeOption: viewModel.selectedPriceChangeOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        PriceChangeOptionSelected(fromScreen: .toplist, option: option)
                    )
                    
                    Task {
                        if viewModel.selectedSortOption == .priceChangeDesc || viewModel.selectedSortOption == .priceChangeAsc {
                            await viewModel.getToplist(
                                newSortOption: viewModel.selectedSortOption,
                                newPriceChangeOption: option
                            )
                        } else {
                            viewModel.setNewPriceChangeOption(
                                newPriceChangeOption: option
                            )
                        }
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 0 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .toplist)
                )
                
                currenciesScrollToTop.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeMarketPage, object: nil)) { notification in
            if let page = notification.userInfo?["page"] as? Int, page == 0 {
                currentPage = 0

                let currentSort: SortOption = (notification.userInfo?["sortOption"] as? String).flatMap(SortOption.init(rawValue:))
                    ?? viewModel.selectedSortOption
                
                Task {
                    await viewModel.getToplist(
                        newSortOption: currentSort,
                        newPriceChangeOption: viewModel.selectedPriceChangeOption
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .downloadNewToplist, object: nil)) { _ in
            Task {
                await viewModel.setStartData()
                await viewModel.getToplist(
                    newSortOption: viewModel.selectedSortOption,
                    newPriceChangeOption: viewModel.selectedPriceChangeOption
                )
            }
        }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .toplist, sheet: .coinSearch)
                    )
                    isSearchShowing = true
                }, label: {
                    Image.search
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                })
                .accessibilityLabel("Search for coins")
                .padding(12)
                .optionalGlassEffect(
                    color: Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                
                SecondaryButton(
                    text: viewModel.selectedSortOption.title,
                    accessibilityLabel: "Sort, currently selected: \(viewModel.selectedSortOption.accessibilityTitle)",
                    icon: .sort,
                    action: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .toplist, sheet: .sortBy)
                        )
                        isSortShowing = true
                    }
                )

                SecondaryButton(
                    text: viewModel.selectedPriceChangeOption.rawValue,
                    accessibilityLabel: "Timeframe, currently selected: \(viewModel.selectedPriceChangeOption.accessibilityTimeframe)",
                    icon: .percent,
                    action: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .toplist, sheet: .priceChange)
                        )
                        isPriceChangeShowing = true
                    }
                )
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: viewModel.category == nil ? 32 : 24,
                    leading: 16 + safeAreaInsets.leading,
                    bottom: 8,
                    trailing: 16 + safeAreaInsets.trailing
                )
            )
        }
    }
    
    private var heatmapButton: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: "Heatmap",
                accessibilityLabel: "Open heatmap",
                icon: .heatmap,
                action: {
                    AnalyticsManager.shared.log(
                        Navigate(
                            fromScreen: viewModel.category == nil ? .toplist : .categoryDetail,
                            toScreen: .heatmap
                        )
                    )
                    
                    navigationViewModel.navPath.append(
                        NavigationScreens.Heatmap(category: viewModel.category)
                    )
                }
            )
            
            Spacer(minLength: 0)
        }
        .optionalGlassEffectContainer(spacing: 8)
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16 + safeAreaInsets.leading,
                bottom: 8,
                trailing: 16 + safeAreaInsets.trailing
            )
        )
    }

    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 30 : 15), id: \.self) { index in
            ToplistCardView(
                coin: nil,
                selectedChangeOption: viewModel.selectedPriceChangeOption,
                isFirstElement: false,
                listIndex: index,
                listCount: isPad ? 30 : 15,
                navigateToCryptoDetail: { }
            )
        }
    }

    @ViewBuilder
    private var realList: some View {
        let toplist = viewModel.toplist

        ForEach(toplist, id: \.self) { coin in
            let isFavorited = viewModel.favoritesList.contains(where: { $0.id == coin.id })
            let index = toplist.firstIndex(where: { $0.id == coin.id }) ?? -1
            
            ToplistCardView(
                coin: coin,
                selectedChangeOption: viewModel.selectedPriceChangeOption,
                isFirstElement: false,
                listIndex: index,
                listCount: toplist.count,
                navigateToCryptoDetail: {
                    handleCurrencyClick(coin)
                }
            )
            .contextMenu {
                Button {
                    Task {
                        await viewModel.favouriteButtonPressed(toplistItem: coin)
                    }
                } label: {
                    Label(title: {
                        Text(isFavorited ? "Remove from favorites" : "Add to favorites")
                    }, icon: {
                        isFavorited ? Image.starFill : Image.star
                    })
                }
            }
        }
    }
}
