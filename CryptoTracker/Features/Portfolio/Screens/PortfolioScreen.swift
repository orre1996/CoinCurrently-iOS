//
//  PortfolioScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2020-12-11.
//

import SwiftUI
import Combine
import UIKit

@MainActor
struct PortfolioScreen: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var viewModel = PortfolioViewModelImp()
    @State private var id = UUID()
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
    @State private var isPieChartShowing: Bool = false
    @State private var selectedPieSliceId: String?

    @State private var showPortfolioCloudRecovery = false
    @State private var showPortfolioTip = false
    @State private var showPortfolioCurrencySelector = false
    
    @State private var biggestChartValue: CGSize = .zero
    @State private var lineChartHeight: CGFloat = 0
    @State private var currentPage: Int? = 0
    @State private var isActionMenuExpanded = false
    @State private var isTransactionTypeSheetShowing = false
    @State private var isExportFormatSheetShowing = false
    @State private var isBenchmarkCoinSelectorShowing = false
    @State private var pendingExportFormat: PortfolioExportFormat?
    
    @State private var isSelectingTypeFilter = false
    @State private var isSelectingDateFilter = false
    @State private var isSelectingCoinFilter = false
    @State private var isSelectingDates = false
    @State private var isDatePickerShowing = false
    
    @State private var temporaryCustomDate = DateOption.custom(startDate: nil, endDate: nil)
    @State private var isPickingStartDate = true
    
    @State private var selectedEvent: PortfolioEventWrapper?
    
    @State private var scrollToTop = false
    @State private var tabId = UUID()
    @State private var appLanguage = AppLanguagePreference.stored
    
    private static let portfolioPageTabTitles = ["Assets", "Transactions", "Wallets"]
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        portfolioContent()
        .overlay(alignment: .bottomTrailing) {
            PortfolioActionMenu(
                viewModel: viewModel,
                isActionMenuExpanded: $isActionMenuExpanded,
                isTransactionTypeSheetShowing: $isTransactionTypeSheetShowing,
                isExportFormatSheetShowing: $isExportFormatSheetShowing,
                isBenchmarkCoinSelectorShowing: $isBenchmarkCoinSelectorShowing
            )
        }
        .onChange(of: currentPage) { _, page in
            if let page, page >= 0, page < Self.portfolioPageTabTitles.count {
                AnalyticsManager.shared.log(
                    TabChanged(fromScreen: .portfolio, selectedTabName: Self.portfolioPageTabTitles[page])
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTransaction, object: nil)) { notification in
            Task {
                await viewModel.refreshPortfolioData()
                await viewModel.getCoinColors()

                guard
                    let transaction = notification.userInfo?["transaction"] as? String else {
                    return
                }
                
                let (event, coin) = await viewModel.findTransaction(transaction: transaction)
                guard let event, let coin else {
                    return
                }
                
                if let transaction = event as? PortfolioTransaction {
                    navigationViewModel.showSnackbar(
                        message: Localization.format("%@ transaction added to your portfolio!", coin.symbol?.uppercased() ?? Localization.string("Coin")),
                        buttonTitle: Localization.string("View Details"),
                        snackBarType: .success,
                        buttonCallback: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                            )
                            selectedEvent = PortfolioEventWrapper.transaction(transaction)
                        }
                    )
                } else if let swap = event as? PortfolioSwapTransaction {
                    navigationViewModel.showSnackbar(
                        message: Localization.format("%@ transaction added to your portfolio!", coin.symbol?.uppercased() ?? Localization.string("Coin")),
                        buttonTitle: Localization.string("View Details"),
                        snackBarType: .success,
                        buttonCallback: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                            )
                            selectedEvent = PortfolioEventWrapper.swap(swap)
                        }
                    )
                } else if event is AddressImport {
                    guard let wallet = event as? AddressImport else {
                        return
                    }
                    
                    navigationViewModel.showSnackbar(
                        message: Localization.format(
                            "%1$@ (%2$@) imported to your portfolio!",
                            "\(wallet.address.uppercased().prefix(5))...\(wallet.address.uppercased().suffix(5))",
                            coin.symbol?.uppercased() ?? Localization.string("Coin")
                        ),
                        buttonTitle: Localization.string("View Details"),
                        snackBarType: .success,
                        buttonCallback: {
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
        .sheet(isPresented: $isExportFormatSheetShowing, onDismiss: {
            performPendingExport()
        }) {
            SelectExportFormatSheet(
                formatSelected: { format in
                    pendingExportFormat = format
                }
            )
        }
        .sheet(isPresented: $isBenchmarkCoinSelectorShowing) {
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .portfolio,
                highlightId: viewModel.benchmarkCoin?.id,
                hideId: nil,
                close: { id, _, _ in
                    isBenchmarkCoinSelectorShowing = false
                    
                    guard let id else {
                        return
                    }
                    
                    Task {
                        await viewModel.setBenchmarkCoin(id: id)
                    }
                }
            )
        }
        .sheet(isPresented: $isTransactionTypeSheetShowing) {
            SelectTransactionTypeSheet(
                transactionSelected: { type in
                    AnalyticsManager.shared.log(
                        Navigate(fromScreen: .portfolio, toScreen: .search)
                    )
                    navigationViewModel.navPath.append(
                        NavigationScreens.Search(
                            screenCase: .transaction(
                                transactionType: type
                            )
                        )
                    )
                }
            )
        }
        .sheet(isPresented: $isSelectingCoinFilter) {
            SelectCoinsSheet(
                fromScreen: .portfolio,
                coins: viewModel.holdings.coinFilterList,
                selectedCoins: $viewModel.transactions.coinFilters
            )
        }
        .sheet(isPresented: $isSelectingTypeFilter) {
            SelectTypesSheet(
                fromScreen: .portfolio,
                transactionTypes: $viewModel.transactions.typeFilters
            )
        }
        .sheet(isPresented: $isSelectingDateFilter) {
            SelectDateSheet(
                fromScreen: .portfolio,
                selectedOption: $viewModel.transactions.dateFilter,
                selectCustomDate: {
                    isSelectingDates = true
                }
            )
        }
        .sheet(isPresented: $isSelectingDates) {
            DateFilterSheet(
                startDate: temporaryCustomDate.startDate,
                endDate: temporaryCustomDate.endDate,
                fromScreen: .portfolio,
                selectDate: {
                    isPickingStartDate = $0 == .start
                    isDatePickerShowing = true
                },
                clearDate: {
                    viewModel.transactions.dateFilter = .all
                },
                applyDate: {
                    viewModel.transactions.dateFilter = $0
                    
                }
            )
        }
        .sheet(isPresented: $isDatePickerShowing, onDismiss: {
            isSelectingDates = true
        }) {
            DateRangePickerSheet(
                fromScreen: .portfolio,
                dateComponents: .date,
                initialDate: isPickingStartDate
                    ? (temporaryCustomDate.startDate ?? Date())
                    : (temporaryCustomDate.endDate ?? Date()),
                applyDate: { selectedDate in
                    var start = temporaryCustomDate.startDate
                    var end = temporaryCustomDate.endDate
                    
                    if isPickingStartDate {
                        start = selectedDate
                    } else {
                        end = selectedDate
                    }
                    
                    // 🔒 Enforce valid order
                    if let s = start, let e = end, s > e {
                        if isPickingStartDate {
                            end = s
                        } else {
                            start = e
                        }
                    }
                    
                    temporaryCustomDate = .custom(
                        startDate: start,
                        endDate: end
                    )
                }
            )
        }
        .sheet(item: $selectedEvent) { event in
            switch event {
            case .transaction(let transaction):
                let coin = viewModel.portfolio?.pie(containing: transaction)?.data
                
                TransactionDetailSheet(
                    coin: coin,
                    transaction: transaction,
                    hideData: viewModel.hideData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .portfolio,
                                toScreen: .newPortfolioTransaction,
                                coinName: coin?.name ?? ""
                            )
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.AddPortfolioTransaction(
                                transactionType: $0.transactionType,
                                currencyDataModel: coin?.toCryptoDetail,
                                transaction: $0
                            )
                        )
                    },
                    deleteTransaction: { transaction in
                        AnalyticsManager.shared.log(
                            PortfolioTransactionDeleted(
                                fromScreen: .portfolio,
                                coinName: coin?.name ?? "",
                                kind: .transaction
                            )
                        )
                        Task {
                            await viewModel.deleteTransaction(transaction)
                        }
                    }
                )
                
            case .swap(let swap):
                let coin = viewModel.portfolio?.pie(containing: swap)?.data
                
                SwapDetailSheet(
                    coin: coin,
                    transaction: swap,
                    portfolio: viewModel.portfolio,
                    hideData: viewModel.hideData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .portfolio,
                                toScreen: .newSwapTransaction,
                                coinName: coin?.name ?? ""
                            )
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.PortfolioSwapTransaction(
                                transactionType: .swap,
                                currencyDataModel: CurrencyDataModel(
                                    id: $0.fromCurrencyId,
                                    symbol: $0.fromCurrencySymbol
                                ),
                                transaction: $0
                            )
                        )
                    },
                    deleteTransaction: { transaction in
                        AnalyticsManager.shared.log(
                            PortfolioTransactionDeleted(
                                fromScreen: .portfolio,
                                coinName: coin?.name ?? "",
                                kind: .swap
                            )
                        )
                        Task {
                            await viewModel.deleteTransaction(transaction)
                        }
                    }
                )
                
            default:
                EmptyView()
            }
        }
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .id(colorBlindnessFilterEnabled)
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
    
    @ViewBuilder
    private func portfolioContent() -> some View {
        ZStack(alignment: .top) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            PortfolioSummaryHeader(
                                viewModel: viewModel,
                                isPieChartShowing: $isPieChartShowing,
                                selectedPieSliceId: $selectedPieSliceId
                            )
                            
                            PortfolioPerformanceChart(
                                viewModel: viewModel,
                                isPieChartShowing: isPieChartShowing,
                                selectedPieSliceId: $selectedPieSliceId,
                                biggestChartValue: $biggestChartValue,
                                lineChartHeight: $lineChartHeight,
                                chartHeight: reader.size.height * 0.35
                            )
                            
                            Section(header: pageSelector) {
                                PortfolioTabPages(
                                    viewModel: viewModel,
                                    currentPage: currentPage,
                                    isSelectingTypeFilter: $isSelectingTypeFilter,
                                    isSelectingDateFilter: $isSelectingDateFilter,
                                    isSelectingCoinFilter: $isSelectingCoinFilter,
                                    temporaryCustomDate: $temporaryCustomDate,
                                    selectedEvent: $selectedEvent
                                )
                            }
                            .accessibilitySortPriority(-2)
                        }
                        .padding(.top, 16)
                        .id(id)
                        .onChange(of: viewModel.scrollToTopActive) {
                            withAnimation {
                                scrollViewReader.scrollTo(id, anchor: .top)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
                            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 1 {
                                AnalyticsManager.shared.log(
                                    TabBarDoubleTapped(fromScreen: .portfolio)
                                )
                                
                                withAnimation {
                                    scrollViewReader.scrollTo(id, anchor: .top)
                                }
                            }
                        }
                    }
                    .scrollDisabled(viewModel.isDragging)
                    .onChange(of: scrollToTop) {
                        withAnimation {
                            scrollViewReader.scrollTo(tabId, anchor: .top)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshPortfolioData()
                    await viewModel.refreshImportWallets()
                    await viewModel.getCoinColors()
                }
                .task {
                    // try? await Task.sleep(for: .seconds(0.1))
                    var transaction = SwiftUI.Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        isPieChartShowing = SettingsManager.shared.get(key: AppSettingKey.isPortfolioPieChartShowing) ?? false
                    }
                }
                .task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.setStartData() }
                        group.addTask { await viewModel.refreshPortfolioData() }
                    }

                    await viewModel.refreshImportWallets()
                    await viewModel.getCoinColors()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        Task {
                            await withTaskGroup(of: Void.self) { group in
                                group.addTask { await viewModel.refreshPortfolioData() }
                                group.addTask { await viewModel.refreshImportWallets() }
                            }
                            await viewModel.getCoinColors()
                        }
                    default:
                        break
                    }
                }
                .task(id: viewModel.transactions.dateFilter) {
                    await viewModel.reloadTransactions()
                }
                .task(id: viewModel.transactions.typeFilters) {
                    await viewModel.reloadTransactions()
                }
                .task(id: viewModel.transactions.coinFilters) {
                    await viewModel.reloadTransactions()
                }
                .accessibilityHidden(showPortfolioCurrencySelector || showPortfolioCloudRecovery)
                .animation(.none, value: viewModel.hideData)
                .onReceive(NotificationCenter.default.publisher(for: .closeAllOverlays, object: nil)) { _ in
                    showPortfolioCloudRecovery = false
                    showPortfolioTip = false
                    showPortfolioCurrencySelector = false
                }
            }
            
            Color.surface
                .frame(maxWidth: .infinity, minHeight: safeAreaInsets.top, maxHeight: safeAreaInsets.top)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var pageSelector: some View {
        VStack(spacing: 0) {
            PageSelectorView(currentPage: $currentPage, titles: Self.portfolioPageTabTitles, pageSelected: { page in
                scrollToTop.toggle()
                
                withAnimation {
                    currentPage = page
                }
            })
            
            Separator()
        }
        .background(Color.surface)
        .id(tabId)
    }
    
    private func performPendingExport() {
        guard let format = pendingExportFormat else { return }
        pendingExportFormat = nil
        
        if format.isTaxSoftware {
            Task {
                if await viewModel.hasBoughtPro() {
                    runExport(format: format)
                } else {
                    AnalyticsManager.shared.log(
                        BuyProOpened(fromScreen: .portfolio, action: .ExportPortfolio)
                    )
                    navigationViewModel.showBuyPro = true
                }
            }
            return
        }
        
        runExport(format: format)
    }
    
    private func runExport(format: PortfolioExportFormat) {
        viewModel.export(format)
    }
}
