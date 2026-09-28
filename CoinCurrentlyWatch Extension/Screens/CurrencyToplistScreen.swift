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
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                searchField
                currencyButton
                listHeader
                
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
        .onChange(of: navigationViewModel.navPath) { _, path in
            guard !path.contains(.CurrencySelector) else { return }
            reloadToplistIfCurrencyChanged()
        }
    }
    
    private var searchField: some View {
        TextField(
            "eg. BTC or Ethereum",
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

    private var currencyButton: some View {
        Button {
            navigationViewModel.navPath.append(.CurrencySelector)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Currency")
                        .font(.satoshiBold(14))
                        .foregroundStyle(Color.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(selectedCurrency.code) (\(selectedCurrency.symbol))")
                        .font(.satoshiBold(12))
                        .foregroundStyle(Color.onSurfaceDim)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityHidden(true)
            }
            .padding(8)
            .background(Color.surfaceContainerHigh)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Currency, currently selected \(selectedCurrency.currency)")
    }
    
    private var listHeader: some View {
        HStack(spacing: 16) {
            Text("Price")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("7d %")
                .font(.satoshiBold(14))
                .lineLimit(1)
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .padding(.top, 8)
        .background(Color.surface)
        .accessibilityHidden(true)
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

    private func reloadToplistIfCurrencyChanged() {
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard currency != selectedCurrency else { return }

        selectedCurrency = currency
        Task {
            await viewModel.getToplist(
                newSortOption: .mktCapDesc,
                newPriceChangeOption: .sevenDays
            )
        }
    }
}
