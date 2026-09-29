//
//  TreasuriesListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/21/26.
//

import SwiftUI

struct TreasuriesListView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    let currentPage: Int?
    let treasurySelected: (TreasuryListItem) -> Void
    
    @State private var viewModel = TreasuriesViewModelImp()
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var showScrollToTopButton = false
    @State private var treasuriesScrollToTop = false
    @State private var isEntityFilterShowing = false
    @State private var isCoinShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(alignment: .leading, spacing: 0) {
                    TreasuriesSummaryView(
                        totalHoldings: viewModel.filteredTotalHoldings,
                        marketCapDominance: viewModel.filteredMarketCapDominance,
                        coinSymbol: viewModel.selectedCoin?.symbol
                    )
                    .padding(
                        EdgeInsets(
                            top: 16,
                            leading: 16 + safeAreaInsets.leading,
                            bottom: 0,
                            trailing: 16 + safeAreaInsets.trailing
                        )
                    )

                    filterButtons
                    
                    TreasuriesHeaderView()
                        .opacity(viewModel.holders.isEmpty && viewModel.treasury != nil ? 0 : 1)
                        .padding(
                            EdgeInsets(
                                top: 8,
                                leading: 0,
                                bottom: 6,
                                trailing: 0
                            )
                        )
                    
                    Group {
                        if viewModel.treasury == nil {
                            tempList
                        } else if viewModel.holders.isEmpty {
                            emptyView
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
                .onChange(of: treasuriesScrollToTop) {
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
                            ScrollToTopPressed(fromScreen: .treasuries)
                        )
                        treasuriesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getTreasuries() }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getTreasuries() }
                        group.addTask { await viewModel.getBitcoin() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getTreasuries() }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .sheet(isPresented: $isEntityFilterShowing) {
            TreasuryEntityFilterSheet(
                selectedFilter: viewModel.selectedEntityFilter,
                newFilterSelected: { filter in
                    Task {
                        await viewModel.setEntityFilter(filter)
                    }
                }
            )
        }
        .sheet(isPresented: $isCoinShowing) {
            TreasuryCoinSheet(
                coins: viewModel.availableCoins,
                selectedCoinId: viewModel.selectedCoinId,
                newCoinSelected: { coin in
                    Task {
                        await viewModel.setSelectedCoin(coin)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 2 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .treasuries)
                )

                treasuriesScrollToTop.toggle()
            }
        }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SecondaryButton(
                    text: Localization.string(viewModel.selectedEntityFilter.title),
                    accessibilityLabel: Localization.format("Type, currently selected: %@", Localization.string(viewModel.selectedEntityFilter.accessibilityTitle)),
                    icon: .chevronDown,
                    action: {
                        isEntityFilterShowing = true
                    }
                )

                SecondaryButton(
                    text: viewModel.selectedCoin?.name ?? viewModel.selectedCoinId.capitalized,
                    accessibilityLabel: Localization.format("Coin, currently selected: %@", viewModel.selectedCoin?.name ?? viewModel.selectedCoinId),
                    icon: .chevronDown,
                    isEnabled: !viewModel.availableCoins.isEmpty,
                    action: {
                        isCoinShowing = true
                    }
                )
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: 24,
                    leading: 16 + safeAreaInsets.leading,
                    bottom: 8,
                    trailing: 16 + safeAreaInsets.trailing
                )
            )
        }
    }
    
    private var emptyView: some View {
        EmptyContent(
            title: emptyTitle,
            subTitle: emptySubTitle
        )
        .padding(
            EdgeInsets(
                top: 40,
                leading: 16,
                bottom: 40,
                trailing: 16
            )
        )
    }

    private var emptyTitle: String {
        switch viewModel.selectedEntityFilter {
        case .all:
            Localization.string("No treasuries yet")
        case .companies:
            Localization.string("No company treasuries yet")
        case .governments:
            Localization.string("No government treasuries yet")
        }
    }

    private var emptySubTitle: String {
        let coinName = viewModel.selectedCoin?.name ?? viewModel.selectedCoinId.capitalized

        switch viewModel.selectedEntityFilter {
        case .all:
            return Localization.format("No one currently holds %@.", coinName)
        case .companies:
            return Localization.format("No companies currently hold %@.", coinName)
        case .governments:
            return Localization.format("No governments currently hold %@.", coinName)
        }
    }

    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 30 : 15), id: \.self) { _ in
            TreasuriesItemView(
                data: nil,
                entity: nil,
                coinSymbol: viewModel.selectedCoin?.symbol,
                priceMultiplier: viewModel.multiplier,
                handleTreasuryClick: { }
            )
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.holders, id: \.self) { treasury in
            let index = viewModel.holders.firstIndex(of: treasury) ?? -1
            
            TreasuriesItemView(
                data: treasury.holder,
                entity: treasury.entity,
                coinSymbol: viewModel.selectedCoin?.symbol,
                priceMultiplier: viewModel.multiplier,
                listIndex: index,
                listCount: viewModel.holders.count,
                handleTreasuryClick: {
                    treasurySelected(treasury)
                }
            )
        }
    }
}
