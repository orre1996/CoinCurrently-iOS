//
//  PortfolioTabPages.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import SwiftUI

struct PortfolioTabPages: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel

    @Bindable var viewModel: PortfolioViewModelImp
    let currentPage: Int?
    @Binding var isSelectingTypeFilter: Bool
    @Binding var isSelectingDateFilter: Bool
    @Binding var isSelectingCoinFilter: Bool
    @Binding var temporaryCustomDate: DateOption
    @Binding var selectedEvent: PortfolioEventWrapper?

    var body: some View {
        if currentPage == 0 {
            MyAssetsView(
                portfolio: viewModel.portfolio,
                allPrices: viewModel.allPrices,
                hideData: viewModel.hideData,
                navigateToCoin: {
                    AnalyticsManager.shared.log(
                        Navigate(
                            fromScreen: .portfolio,
                            toScreen: .cryptoDetail,
                            coinName: $0.name ?? ""
                        )
                    )
                    navigationViewModel.navPath.append(
                        NavigationScreens.CryptoDetail(
                            currencyDataModel: $0.toCryptoDetail
                        )
                    )
                }
            )
        } else if currentPage == 1 {
            TransactionsView(
                portfolio: viewModel.portfolio,
                groupedTransactions: viewModel.transactions.groupedTransactions,
                prices: viewModel.allPrices,
                hideData: viewModel.hideData,
                typeFilters: viewModel.transactions.typeFilters,
                dateFilter: viewModel.transactions.dateFilter,
                coinFilters: viewModel.transactions.coinFilters,
                typeFilterPressed: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .portfolio, sheet: .portfolioTypeFilter)
                    )
                    isSelectingTypeFilter = true
                },
                dateFilterPressed: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .portfolio, sheet: .portfolioDateFilter)
                    )
                    isSelectingDateFilter = true
                },
                coinFilterPressed: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .portfolio, sheet: .portfolioCoinFilter)
                    )
                    isSelectingCoinFilter = true
                },
                clearFilters: {
                    AnalyticsManager.shared.log(
                        ClearFilters(fromScreen: .portfolio)
                    )
                    viewModel.transactions.dateFilter = .all
                    viewModel.transactions.typeFilters = []
                    viewModel.transactions.coinFilters = []
                    temporaryCustomDate = DateOption.custom(startDate: nil, endDate: nil)
                },
                showTransactionDetails: { event in
                    if let transaction = event as? PortfolioTransaction {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                        )
                        selectedEvent = PortfolioEventWrapper.transaction(transaction)
                    } else if let swap = event as? PortfolioSwapTransaction {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                        )
                        selectedEvent = PortfolioEventWrapper.swap(swap)
                    } else if event is AddressImport {
                        guard
                            let wallet = event as? AddressImport,
                            let coin = viewModel.portfolio?.pie(containing: event)?.data
                        else {
                            return
                        }

                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .portfolio,
                                toScreen: .walletDetails,
                                coinName: coin.name ?? ""
                            )
                        )

                        navigationViewModel.navPath.append(
                            NavigationScreens.WalletDetails(
                                wallet: wallet,
                                coin: coin
                            )
                        )
                    }
                }
            )
        } else {
            WalletsView(
                portfolio: viewModel.portfolio,
                prices: viewModel.allPrices,
                hideData: viewModel.hideData,
                showTransactionDetails: { event in
                    guard
                        let wallet = event as? AddressImport,
                        let coin = viewModel.portfolio?.pie(containing: event)?.data
                    else {
                        return
                    }

                    AnalyticsManager.shared.log(
                        Navigate(
                            fromScreen: .portfolio,
                            toScreen: .walletDetails,
                            coinName: coin.name ?? ""
                        )
                    )

                    navigationViewModel.navPath.append(
                        NavigationScreens.WalletDetails(
                            wallet: wallet,
                            coin: coin
                        )
                    )
                }
            )
        }
    }
}
