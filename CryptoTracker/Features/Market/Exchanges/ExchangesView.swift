//
//  ExchangesView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import SwiftUI

struct ExchangesView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let currentPage: Int?
    let exchangeClicked: (ExchangeModel) -> Void
    
    @State private var viewModel = ExchangesViewModelImp()
    @State private var showScrollToTopButton = false
    @State private var exchangesScrollToTop = false
    @State private var isSearchShowing = false
    @State private var isSortShowing = false
    @State private var isPriceChangeShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(spacing: 0) {
                    filterButtons
                    
                    ExchangesHeaderView()
                        .padding(
                            EdgeInsets(
                                top: 8,
                                leading: 0,
                                bottom: 6,
                                trailing: 0
                            )
                        )
                    
                    Group {
                        if viewModel.exchanges.isEmpty {
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
                .onChange(of: exchangesScrollToTop) {
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
                            ScrollToTopPressed(fromScreen: .exchanges)
                        )
                        exchangesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getBitcoin() }
                group.addTask { await viewModel.getExchanges() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getBitcoin() }
                        group.addTask { await viewModel.getExchanges() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getBitcoin() }
                group.addTask { await viewModel.getExchanges() }
            }
        }
        .sheet(isPresented: $isSearchShowing) {
            SearchScreen(
                screenCase: .search(list: .exchanges),
                fromScreen: .exchanges,
                isSheet: true,
                highlightId: nil,
                hideId: nil,
                isSearch: true,
                close: { _, _, _ in }
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.exchangesOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .exchanges, option: option)
                    )

                    Task {
                        await viewModel.setNewSortOption(newSortOption: option)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 3 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .exchanges)
                )

                exchangesScrollToTop.toggle()
            }
        }
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .exchanges, sheet: .coinSearch)
                    )
                    isSearchShowing = true
                }, label: {
                    Image.search
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                })
                .accessibilityLabel("Search for exchanges")
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
                            SheetOpened(fromScreen: .exchanges, sheet: .sortBy)
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
            ExchangeListItem(
                data: nil,
                bitcoin: nil,
                handleCurrencyClick: { }
            )
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.exchanges, id: \.self) { exchange in
            let index = viewModel.exchanges.firstIndex(of: exchange) ?? -1
            
            ExchangeListItem(
                data: exchange,
                bitcoin: viewModel.bitcoin,
                listIndex: index,
                listCount: viewModel.exchanges.count,
                handleCurrencyClick: {
                    exchangeClicked(exchange)
                }
            )
        }
    }
}

