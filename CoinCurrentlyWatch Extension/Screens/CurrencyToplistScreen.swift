//
//  CurrencyToplistScreen.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-23.
//

import SwiftUI

@MainActor
struct CurrencyToplistScreen: View {
    @Environment(NavigationViewModel.self) var navigationViewModel

    @State var viewModel = ToplistViewModelImp()
    @State var searchViewModel = SearchViewModelImp()
    @State var searchInput = ""
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                searchField
                
                if searchViewModel.currentlySearching || viewModel.toplist.isEmpty {
                    tempList
                } else if let searchResult = searchViewModel.searchResult, !(searchResult.coins?.isEmpty ?? true) {
                    searchList(list: searchResult.coins?.compactMap({ $0.toToplistCoin }) ?? [])
                } else if let searchResult = searchViewModel.searchResult, (searchResult.coins?.isEmpty ?? true) {
                    emptyView
                } else {
                    realList
                }
            }
        }
        .navigationBarTitle("CoinCurrently")
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.setStartData()
            await viewModel.getToplist(
                newSortOption: .mktCapDesc,
                newPriceChangeOption: .sevenDays
            )
        }
    }
    
    private var searchField: some View {
        TextField(
            "Search for coin",
            text: $searchInput,
            onCommit: {
                Task {
                    await searchViewModel.getSearchResult(query: searchInput)
                }
            }
        )
        .background(Color.surfaceContainerHigh.opacity(0.4))
        .cornerRadius(10)
        .submitLabel(.search)
    }
    
    private var tempList: some View {
        ForEach(0..<5, id: \.self) { _ in
            CryptoListView(
                coin: nil,
                currencySelected:  { _ in  }
            )
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.toplist, id: \.self) { currentCurrency in
            CryptoListView(
                coin: currentCurrency,
                currencySelected: { currency in
                    navigationViewModel.navPath.append(
                        .CryptoDetail(
                            currencyDataModel: currency.toCryptoDetail
                        )
                    )
                }
            )
        }
    }
    
    @ViewBuilder
    private func searchList(list: [Toplist]) -> some View {
        ForEach(list, id: \.self) { currentCurrency in
            SearchListView(
                coin: currentCurrency,
                currencySelected: { currency in
                    navigationViewModel.navPath.append(
                        .CryptoDetail(
                            currencyDataModel: currency.toCryptoDetail
                        )
                    )
                }
            )
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 4) {
            Text("No results found.")
                .foregroundColor(.onSurface)
                .font(.poppinsSemibold(16))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Try searching for something else.")
                .foregroundColor(.onSurface)
                .font(.poppinsRegular(14))
                .fixedSize(horizontal: false, vertical: true)
            
        }
        .accessibilityElement(children: .combine)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
