//
//  AddToWidgetSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/25/25.
//

import SwiftUI
import Combine

struct SearchScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var toplistViewModel = ToplistViewModelImp()
    @State private var viewModel = SearchViewModelImp()
    @State private var trendingViewModel = TrendingViewModelImp()

    @State private var task: Task<Void, Never>?
    @State private var searchInput = ""
    @State private var filteredList: [Toplist]?
    
    let screenCase: SearchScreenCase
    let fromScreen: ScreenLabel
    
    var isSheet: Bool = true
    let highlightId: String?
    let hideId: String?
    var isSearch: Bool = false
    let close: (String?, String?, String?) -> Void
    
    var body: some View {
        ZStack {
            if !isSheet {
                Color.surface
                    .ignoresSafeArea()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                if isSheet {
                    DragHandle(title: isSearch ? "Search" : screenCase.title)
                }
                
                searchFieldView
                    .padding(
                        EdgeInsets(
                            top: isSheet ? 0 : 16,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
                
                Separator()
                    .padding(.horizontal, 16)
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 4) {
                        switch screenCase {
                        case .search(let list):
                            switch list {
                            case .onlyCoins:
                                if viewModel.currentlySearching || (toplistViewModel.toplist.isEmpty && viewModel.searchResult?.coins == nil) {
                                    tempList(isSelectable: true)
                                } else if viewModel.showError {
                                    errorView
                                } else if viewModel.searchResult?.isAllEmpty ?? false && !viewModel.currentlySearching {
                                    emptyView
                                } else {
                                    fixedListTransaction(
                                        coins: sortCoins(
                                            viewModel.searchResult?.coins?.map { $0.toToplistCoin } ?? toplistViewModel.toplist,
                                            highlightId: highlightId
                                        ).filter {
                                            $0.id != hideId
                                        },
                                        transactionType: nil,
                                        isSelectable: true,
                                    )
                                }
                            case .coins, .nfts, .categories, .exchanges:
                                if viewModel.currentlySearching {
                                    tempList(isSelectable: false)
                                } else if viewModel.showError {
                                    errorView
                                } else if viewModel.searchResult?.searchCaseCoins(searchCase: list).isEmpty ?? false && !viewModel.currentlySearching {
                                    emptyView
                                } else if let searchResult = viewModel.searchResult {
                                    searchList(
                                        searchCase: list,
                                        searchResult: searchResult,
                                    )
                                } else if let trendingCoins = trendingViewModel.getTrendingItems(searchCase: list) {
                                    trendingCoinsList(
                                        searchCase: list,
                                        searchHistory: viewModel.searchHistory[list.rawValue] ?? [],
                                        trendingList: trendingCoins
                                    )
                                } else {
                                    tempList(isSelectable: false)
                                }
                            }
                        case .transaction(let transactionType):
                            if viewModel.currentlySearching {
                                tempList(isSelectable: false)
                            } else if viewModel.showError {
                                errorView
                            } else if viewModel.searchResult?.isAllEmpty ?? false && !viewModel.currentlySearching {
                                emptyView
                            } else if let searchResult = viewModel.searchResult {
                                transactionSearchCoinsList(
                                    transactionType: transactionType,
                                    searchResult: searchResult
                                )
                            } else if toplistViewModel.toplist.isEmpty {
                                tempList(isSelectable: false)
                            } else {
                                fixedListTransaction(
                                    coins: toplistViewModel.toplist,
                                    transactionType: transactionType,
                                    isSelectable: false,
                                )
                            }
                        case .fixedList(let list):
                            fixedList(coins: filteredList ?? list)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(
                        EdgeInsets(
                            top: 24,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
                }
            }
        }
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
        .if(!isSheet) { view in
            view.navigationTitle(screenCase.title)
        }
        .task {
            await loadSearchScreenStartupData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await loadSearchScreenStartupData(includeSetStartData: false)
                }
            default:
                break
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Close") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel("Close keyboard")
            }
        }
        .onAppear {
            filteredList = getFilteredCoinsList()
        }
    }
    
    private func loadSearchScreenStartupData(includeSetStartData: Bool = true) async {
        switch screenCase {
        case .search(let list):
            if case .coins = list {
                if includeSetStartData {
                    await trendingViewModel.setStartData()
                }
                await trendingViewModel.getTrendingCoins()
            } else if case .nfts = list {
                if includeSetStartData {
                    await trendingViewModel.setStartData()
                }
                await trendingViewModel.getTrendingCoins()
            } else if case .categories = list {
                if includeSetStartData {
                    await trendingViewModel.setStartData()
                }
                await trendingViewModel.getTrendingCoins()
            } else if case .onlyCoins = list {
                if includeSetStartData {
                    await toplistViewModel.setStartData()
                }
                await toplistViewModel.getToplist(
                    newSortOption: .mktCapDesc,
                    newPriceChangeOption: .sevenDays
                )
            }
        case .transaction(_):
            if includeSetStartData {
                await toplistViewModel.setStartData()
            }
            await toplistViewModel.getToplist(
                newSortOption: .mktCapDesc,
                newPriceChangeOption: .sevenDays
            )
        case .fixedList(_):
            return
        }
    }
    
    private var searchFieldView: some View {
        TextInputField(
            input: $searchInput,
            placeholder: screenCase.textfieldPlaceholder,
            accessibilityValue: searchInput.isEmpty ? "Search for \(screenCase.textfieldPlaceholder)" : searchInput,
            inputDidChange: {
                if case .fixedList = screenCase {
                    filteredList = getFilteredCoinsList()
                }
            },
            onCommit: {
                let trimmedQuery = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedQuery.isEmpty {
                    switch screenCase {
                    case .search, .transaction:
                        AnalyticsManager.shared.log(
                            SearchPerformed(fromScreen: fromScreen, query: trimmedQuery)
                        )
                    case .fixedList:
                        break
                    }
                }
                Task {
                    if case .search = screenCase {
                        await viewModel.getSearchResult(query: searchInput)
                    } else if case .transaction = screenCase {
                        await viewModel.getSearchResult(query: searchInput)
                    }
                }
            }
        )
    }
    
    private var errorView: some View {
        EmptyContent(
            title: "Something went wrong.",
            subTitle: "Please try again later."
        )
        .accessibilityElement(children: .combine)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(
            EdgeInsets(
                top: 48,
                leading: 32,
                bottom: 0,
                trailing: 32
            )
        )
    }
    
    private var emptyView: some View {
        EmptyContent(
            title: "No results found",
            subTitle: "Please check your spelling or search for something else."
        )
        .accessibilityElement(children: .combine)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(
            EdgeInsets(
                top: 48,
                leading: 32,
                bottom: 0,
                trailing: 32
            )
        )
    }
    
    private func tempList(isSelectable: Bool) -> some View {
        ForEach(0..<10, id: \.self) { index in
            SelectCoinView(
                toplist: nil,
                isSelectable: isSelectable,
                isSelected: false,
                itemType: "Coin",
                index: index,
                totalCount: 10,
                onClick: { }
            )
        }
    }

    @ViewBuilder
    private func fixedList(
        coins: [Toplist]
    ) -> some View {
        ForEach(Array(coins.enumerated()), id: \.element) { index, coin in
            SelectCoinView(
                toplist: coin,
                isSelectable: false,
                isSelected: false,
                itemType: "Coin",
                index: index,
                totalCount: coins.count,
                onClick: {
                    guard let id = coin.id, let symbol = coin.symbol else {
                        return
                    }

                    close(id, symbol, coin.name)
                }
            )
        }
    }
    
    @ViewBuilder
    private func fixedListTransaction(
        coins: [Toplist],
        transactionType: NewTransactionType?,
        isSelectable: Bool
    ) -> some View {
        ForEach(Array(coins.enumerated()), id: \.element) { index, coin in
            SelectCoinView(
                toplist: coin,
                isSelectable: isSelectable,
                isSelected: coin.id == highlightId,
                itemType: "Coin",
                index: index,
                totalCount: coins.count,
                onClick: {
                    handleTransactionCoinSelection(coin: coin, transactionType: transactionType)
                }
            )
        }
    }

    private func handleTransactionCoinSelection(
        coin: Toplist,
        transactionType: NewTransactionType?
    ) {
        guard let id = coin.id, coin.id != highlightId, let symbol = coin.symbol else {
            return
        }

        if isSheet {
            close(id, symbol, coin.name)
        } else if let transactionType, transactionType == .swap {
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .newSwapTransaction, coinName: coin.name ?? "")
            )
            navigationViewModel.navPath.append(
                NavigationScreens.NewSwapTransaction(
                    transactionType: transactionType,
                    currencyDataModel: CurrencyDataModel(id: id, symbol: symbol),
                    transaction: nil
                )
            )
        } else if let transactionType {
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .newPortfolioTransaction, coinName: coin.name ?? "")
            )
            navigationViewModel.navPath.append(
                NavigationScreens.NewPortfolioTransaction(
                    transactionType: transactionType,
                    currencyDataModel: CurrencyDataModel(id: id, symbol: symbol),
                    transaction: nil
                )
            )
        }
    }

    @ViewBuilder
    private func transactionSearchCoinsList(
        transactionType: NewTransactionType,
        searchResult: SearchModel
    ) -> some View {
        let coins = searchResult.searchCaseCoins(searchCase: .coins)
        
        ForEach(Array(coins.enumerated()), id: \.element) { index, coin in
            SelectCoinView(
                toplist: coin.toToplistCoin,
                isSelectable: false,
                isSelected: coin.toToplistCoin.id == highlightId,
                itemType: "Coin",
                index: index,
                totalCount: coins.count,
                onClick: {
                    handleTransactionCoinSelection(coin: coin.toToplistCoin, transactionType: transactionType)
                }
            )
        }
    }
    
    @ViewBuilder
    private func trendingCoinsList(
        searchCase: SearchCase,
        searchHistory: [SearchResult],
        trendingList: [Toplist]
    ) -> some View {
        if !searchHistory.isEmpty {
            searchHeader(
                title: "Search History"
            )
            
            ForEach(Array(searchHistory.enumerated()), id: \.element) { index, coin in
                SelectCoinView(
                    toplist: coin.toToplistCoin,
                    isSector: searchCase == .categories,
                    isSelectable: false,
                    isSelected: false,
                    itemType: searchCase.accessibilityItemType,
                    index: index,
                    totalCount: searchHistory.count,
                    onClick: {
                        if coin.symbol == "Secret message" {
                            Task {
                                let secret: HiddenSecret? = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message)
                                if let urlString = secret?.secret_url, let url = URL(string: urlString) {
                                    openURL(url)
                                }
                            }
                            
                            return
                        }
                        
                        presentationMode.wrappedValue.dismiss()

                        logNavigateFromSearch(for: searchCase, itemName: coin.name)

                        switch searchCase {
                        case .onlyCoins, .coins:
                            navigationViewModel.navPath.append(
                                NavigationScreens.CryptoDetail(
                                    currencyDataModel: coin.toCryptoDetail
                                )
                            )
                        case .nfts:
                            navigationViewModel.navPath.append(
                                NavigationScreens.NFTDetail(
                                    nftToplist: coin.toNft
                                )
                            )
                        case .categories:
                            navigationViewModel.navPath.append(
                                NavigationScreens.CategoryDetail(
                                    category: coin.toCategory
                                )
                            )
                        case .exchanges:
                            navigationViewModel.navPath.append(
                                NavigationScreens.ExchangeDetail(
                                    exchange: coin.toExchange
                                )
                            )
                        }
                    }
                )
            }
        }
        
        if !trendingList.isEmpty {
            searchHeader(
                title: "Trending \(searchCase.rawValue) ↗"
            )
            .padding(.top, searchHistory.isEmpty ? 0 : 12)
            
            ForEach(Array(trendingList.enumerated()), id: \.element) { index, coin in
                SelectCoinView(
                    toplist: coin,
                    isSector: searchCase == .categories,
                    isSelectable: false,
                    isSelected: false,
                    itemType: searchCase.accessibilityItemType,
                    index: index,
                    totalCount: trendingList.count,
                    onClick: {
                        presentationMode.wrappedValue.dismiss()

                        logNavigateFromSearch(for: searchCase, itemName: coin.name)

                        switch searchCase {
                        case .onlyCoins, .coins:
                            if coin.symbol == "Secret message" {
                                Task {
                                    let secret: HiddenSecret? = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message)
                                    if let urlString = secret?.secret_url, let url = URL(string: urlString) {
                                        openURL(url)
                                    }
                                }
                                return
                            }
                            
                            navigationViewModel.navPath.append(
                                NavigationScreens.CryptoDetail(
                                    currencyDataModel: coin.toCryptoDetail
                                )
                            )
                        case .nfts:
                            navigationViewModel.navPath.append(
                                NavigationScreens.NFTDetail(
                                    nftToplist: coin.toNFTDetail
                                )
                            )
                        case .categories:
                            navigationViewModel.navPath.append(
                                NavigationScreens.CategoryDetail(
                                    category: coin.toCategory
                                )
                            )
                        case .exchanges:
                            navigationViewModel.navPath.append(
                                NavigationScreens.ExchangeDetail(
                                    exchange: coin.toExchange
                                )
                            )
                        }
                    }
                )
            }
        }
        
        if searchHistory.isEmpty && trendingList.isEmpty {
            EmptyContent(
                title: "No search history yet",
                subTitle: "Your past searches will appear here."
            )
            .padding(
                EdgeInsets(
                    top: 32,
                    leading: 16,
                    bottom: 0,
                    trailing: 16
                )
            )
        }
    }

    @ViewBuilder
    private func searchList(
        searchCase: SearchCase,
        searchResult: SearchModel
    ) -> some View {
        let coins = searchResult.searchCaseCoins(searchCase: searchCase)
        
        ForEach(Array(coins.enumerated()), id: \.element) { index, coin in
            SelectCoinView(
                toplist: coin.toToplistCoin,
                isSector: searchCase == .categories,
                isSelectable: false,
                isSelected: false,
                itemType: searchCase.accessibilityItemType,
                index: index,
                totalCount: coins.count,
                onClick: {
                    presentationMode.wrappedValue.dismiss()
                    
                    viewModel.appendSearchHistory(
                        newCoin: coin,
                        screenCase: searchCase
                    )

                    let trimmedQuery = viewModel.lastQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    AnalyticsManager.shared.log(
                        SearchHistoryItemAdded(
                            fromScreen: fromScreen,
                            itemName: coin.name,
                            query: trimmedQuery.isEmpty ? nil : trimmedQuery
                        )
                    )

                    logNavigateFromSearch(for: searchCase, itemName: coin.name)

                    switch searchCase {
                    case .onlyCoins, .coins:
                        navigationViewModel.navPath.append(
                            NavigationScreens.CryptoDetail(
                                currencyDataModel: coin.toCryptoDetail
                            )
                        )
                    case .nfts:
                        navigationViewModel.navPath.append(
                            NavigationScreens.NFTDetail(
                                nftToplist: coin.toNft
                            )
                        )
                    case .categories:
                        navigationViewModel.navPath.append(
                            NavigationScreens.CategoryDetail(
                                category: coin.toCategory
                            )
                        )
                    case .exchanges:
                        navigationViewModel.navPath.append(
                            NavigationScreens.ExchangeDetail(
                                exchange: coin.toExchange
                            )
                        )
                    }
                }
            )
        }
    }

    private func logNavigateFromSearch(for searchCase: SearchCase, itemName: String?) {
        switch searchCase {
        case .onlyCoins, .coins:
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .cryptoDetail, coinName: itemName ?? "")
            )
        case .nfts:
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .nftDetail, nftName: itemName ?? "")
            )
        case .categories:
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .categoryDetail, sectorName: itemName ?? "")
            )
        case .exchanges:
            AnalyticsManager.shared.log(
                Navigate(fromScreen: fromScreen, toScreen: .exchangeDetail, exchangeName: itemName ?? "")
            )
        }
    }

    private func searchHeader(title: String) -> some View {
        Text(title)
            .font(.satoshiBold(22))
            .foregroundColor(.onSurfaceDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, 12)
    }
    
    private func getFilteredCoinsList() -> [Toplist]? {
        let trimmedInput = searchInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmedInput.isEmpty {
            return screenCase.coins
                .filter { !($0.id?.isEmpty ?? true) }
        }

        var filteredList = screenCase.coins.filter { coin in
            guard let name = coin.name?.lowercased(), let symbol = coin.symbol?.lowercased() else {
                return false
            }
            
            return name.contains(trimmedInput) || symbol.contains(trimmedInput)
        }
        
        var exactSearch = filteredList.filter { coin in
            coin.name?.lowercased() == trimmedInput || coin.symbol?.lowercased() == trimmedInput
        }
        
        if !exactSearch.isEmpty {
            filteredList = filteredList.filter { coin in
                !exactSearch.contains(where: { $0.id == coin.id })
            }

            exactSearch.append(contentsOf: filteredList)
            return exactSearch.filter { !($0.id?.isEmpty ?? true) }
        }
        
        return filteredList.filter { !($0.id?.isEmpty ?? true) }
    }

    private func sortCoins(_ coins: [Toplist], highlightId: String?) -> [Toplist] {
        coins.sorted { lhs, rhs in
            if lhs.id == highlightId { return true }
            if rhs.id == highlightId { return false }
            return (lhs.market_cap_rank ?? Int.max) < (rhs.market_cap_rank ?? Int.max)
        }
    }
}
