//
//  NFTListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-29.
//

import SwiftUI

struct NFTListView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1

    let currentPage: Int?
    let nftSelected: (NFTToplist) -> Void
    
    @State private var viewModel = NFTsViewModelImp()
    @State private var showScrollToTopButton = false
    @State private var nftsScrollToTop = false
    @State private var isSearchShowing = false
    @State private var isSortShowing = false
    @State private var isPlatformsShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(spacing: 0) {
                    filterButtons
                    
                    NFTsHeaderView()
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: 6,
                                trailing: 0
                            )
                        )
                    
                    Group {
                        if viewModel.nftToplist.isEmpty {
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
                .onChange(of: nftsScrollToTop) {
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
                            ScrollToTopPressed(fromScreen: .nfts)
                        )
                        nftsScrollToTop.toggle()
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
                    await viewModel.getNftToplist(
                        newPlatform: viewModel.selectedPlatform,
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask { await viewModel.getNFTPlatforms() }
                group.addTask { await viewModel.getBitcoin() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await viewModel.getNftToplist(
                                newPlatform: viewModel.selectedPlatform,
                                newSortOption: viewModel.selectedSortOption
                            )
                        }
                        group.addTask { await viewModel.getNFTPlatforms() }
                        group.addTask { await viewModel.getBitcoin() }
                        group.addTask { await viewModel.getAllCoins() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getNftToplist(
                        newPlatform: viewModel.selectedPlatform,
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask { await viewModel.getBitcoin() }
                group.addTask { await viewModel.getAllCoins() }
            }
        }
        .sheet(isPresented: $isSearchShowing) {
            SearchScreen(
                screenCase: .search(list: .nfts),
                fromScreen: .nfts,
                isSheet: true,
                highlightId: nil,
                hideId: nil,
                isSearch: true,
                close: { _, _, _ in }
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.nftOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .nfts, option: option)
                    )

                    Task {
                        await viewModel.getNftToplist(
                            newPlatform: viewModel.selectedPlatform,
                            newSortOption: option
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $isPlatformsShowing) {
            NFTsPlatformsSheet(
                allPlatforms: viewModel.nftPlatforms ?? [],
                selectedPlatform: viewModel.selectedPlatform,
                newPlatformSelected: { option in
                    Task {
                        await viewModel.getNftToplist(
                            newPlatform: option,
                            newSortOption: viewModel.selectedSortOption
                        )
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 1 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .nfts)
                )

                nftsScrollToTop.toggle()
            }
        }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .nfts, sheet: .coinSearch)
                    )
                    isSearchShowing = true
                }, label: {
                    Image.search
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                })
                .accessibilityLabel(Localization.string("Search for NFTs"))
                .padding(12)
                .optionalGlassEffect(
                    color: Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                
                SecondaryButton(
                    text: Localization.string(viewModel.selectedSortOption.title),
                    accessibilityLabel: Localization.format("Sort, currently selected: %@", Localization.string(viewModel.selectedSortOption.accessibilityTitle)),
                    icon: .sort,
                    action: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .nfts, sheet: .sortBy)
                        )
                        isSortShowing = true
                    }
                )

                SecondaryButton(
                    text: viewModel.selectedPlatform.id == "all" ? Localization.string("Chain") : viewModel.selectedPlatform.name ?? Localization.string("All Chains"),
                    accessibilityLabel: Localization.format("Chain, currently selected: %@", viewModel.selectedPlatform.id == "all" ? Localization.string("All Chains") : viewModel.selectedPlatform.accessibilityTitle),
                    icon: .chevronDown,
                    isEnabled: viewModel.nftPlatforms != nil,
                    action: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .nfts, sheet: .platform)
                        )
                        isPlatformsShowing = true
                    }
                )
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: 32,
                    leading: 16 + safeAreaInsets.leading,
                    bottom: 8,
                    trailing: 16 + safeAreaInsets.trailing
                )
            )
        }
    }
    
    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 30 : 15), id: \.self) { _ in
            NFTListCell(
                nftToplist: nil,
                chainCurrency: nil,
                priceMultiplier: nil
            ) { }
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.nftToplist, id: \.self) { currentNFT in
            let chainCurrency = viewModel.getChainSymbol(for: currentNFT.native_currency)
            let index = viewModel.nftToplist.firstIndex(where: { $0.id == currentNFT.id }) ?? -1
            
            NFTListCell(
                nftToplist: currentNFT,
                chainCurrency: chainCurrency,
                priceMultiplier: viewModel.multiplier,
                listIndex: index,
                listCount: viewModel.nftToplist.count
            ) {
                nftSelected(currentNFT)
            }
        }
    }
}

