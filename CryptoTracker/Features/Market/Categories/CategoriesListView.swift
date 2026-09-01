//
//  CategoriesListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-28.
//

import SwiftUI

struct CategoriesListView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1

    let currentPage: Int?
    let categorySelected: (CryptoCategory) -> Void
    
    @State private var viewModel = CategoriesViewModelImp()
    @State private var showScrollToTopButton = false
    @State private var categoriesScrollToTop = false
    @State private var isSearchShowing = false
    @State private var isSortShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(spacing: 0) {
                    filterButtons
                    
                    CategoriesHeaderView()
                        .padding(
                            EdgeInsets(
                                top: 8,
                                leading: 0,
                                bottom: 6,
                                trailing: 0
                            )
                        )
                    
                    Group {
                        if viewModel.categories.isEmpty {
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
                .onChange(of: categoriesScrollToTop) {
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
                            ScrollToTopPressed(fromScreen: .sectors)
                        )
                        categoriesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getCategories(
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await viewModel.getCategories(
                                newSortOption: viewModel.selectedSortOption
                            )
                        }
                        group.addTask { await viewModel.getBitcoin() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getCategories(
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask {
                    await viewModel.getBitcoin()
                }
            }
        }
        .sheet(isPresented: $isSearchShowing) {
            SearchScreen(
                screenCase: .search(list: .categories),
                fromScreen: .sectors,
                isSheet: true,
                highlightId: nil,
                hideId: nil,
                isSearch: true,
                close: { _, _, _ in }
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.sectorOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .sectors, option: option)
                    )

                    Task {
                        await viewModel.getCategories(
                            newSortOption: option
                        )
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 2 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .sectors)
                )

                categoriesScrollToTop.toggle()
            }
        }
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .sectors, sheet: .coinSearch)
                    )
                    isSearchShowing = true
                }, label: {
                    Image.search
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                })
                .accessibilityLabel("Search for sectors")
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
                            SheetOpened(fromScreen: .sectors, sheet: .sortBy)
                        )
                        isSortShowing = true
                    }
                )
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: 32,
                    leading: 16 + safeAreaInsets.leading,
                    bottom: 0,
                    trailing: 16 + safeAreaInsets.trailing
                )
            )
        }
    }
    
    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 30 : 15), id: \.self) { _ in
            CategoryItemView(
                currentCategory: nil,
                priceMultiplier: viewModel.multiplier
            ) { }
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.categories, id: \.self) { category in
            let index = viewModel.categories.firstIndex(of: category) ?? -1
            
            CategoryItemView(
                currentCategory: category,
                priceMultiplier: viewModel.multiplier,
                listIndex: index,
                listCount: viewModel.categories.count
            ) {
                categorySelected(category)
            }
        }
    }
}
