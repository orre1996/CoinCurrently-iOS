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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
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
    
    @AccessibilityFocusState private var actionMenuFocus: ActionMenuFocus?
    
    private static let portfolioPageTabTitles = ["Assets", "Transactions", "Wallets"]
    
    private enum ActionMenuFocus: Hashable {
        case addTransaction
        case importWallet
        case exportPortfolio
        case benchmark
        case removeBenchmark
        case fab
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        portfolioContent(
            halfBiggestChartValueHeight: halfBiggestChartValueHeight,
            isHorizontal: isHorizontal
        )
        .overlay(alignment: .bottomTrailing) {
            actionButtons
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
                let previousTransactionCount = notification.userInfo?["previousTransactionCount"] as? Int

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
                
                if let transaction = event as? NewTransaction {
                    navigationViewModel.showSnackbar(
                        message: "\(coin.symbol?.uppercased() ?? "Coin") transaction added to your portfolio!",
                        buttonTitle: "View Details",
                        snackBarType: .success,
                        buttonCallback: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                            )
                            selectedEvent = PortfolioEventWrapper.transaction(transaction)
                        }
                    )
                } else if let swap = event as? NewSwapTransaction {
                    navigationViewModel.showSnackbar(
                        message: "\(coin.symbol?.uppercased() ?? "Coin") transaction added to your portfolio!",
                        buttonTitle: "View Details",
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
                        message: "\(wallet.address.uppercased().prefix(5))...\(wallet.address.uppercased().suffix(5)) (\(coin.symbol?.uppercased() ?? "Coin")) imported to your portfolio!",
                        buttonTitle: "View Details",
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

                if let previousTransactionCount, previousTransactionCount >= 0 {
                    try? await Task.sleep(for: .milliseconds(150))
                    await AchievementManager.shared.checkPortfolioTransactionUnlock(
                        previousCount: previousTransactionCount
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
                coins: viewModel.coinFilterList,
                selectedCoins: $viewModel.coinFilters
            )
        }
        .sheet(isPresented: $isSelectingTypeFilter) {
            SelectTypesSheet(
                fromScreen: .portfolio,
                transactionTypes: $viewModel.typeFilters
            )
        }
        .sheet(isPresented: $isSelectingDateFilter) {
            SelectDateSheet(
                fromScreen: .portfolio,
                selectedOption: $viewModel.dateFilter,
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
                    viewModel.dateFilter = .all
                },
                applyDate: {
                    viewModel.dateFilter = $0
                    
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
                            NavigationScreens.NewPortfolioTransaction(
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
                            NavigationScreens.NewSwapTransaction(
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
        .id(colorBlindnessFilterEnabled)
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
    
    @ViewBuilder
    private func portfolioContent(halfBiggestChartValueHeight: CGFloat, isHorizontal: Bool) -> some View {
        ZStack(alignment: .top) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            totalValueView
                            
                            HStack(spacing: 16) {
                                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                                    valueChangeView
                                    
                                    profitLossView
                                }
                            }
                            .padding(
                                EdgeInsets(
                                    top: 12,
                                    leading: 16,
                                    bottom: 16,
                                    trailing: 16
                                )
                            )
                            Group {
                                if isPieChartShowing {
                                    PortfolioPieChartView(
                                        slices: viewModel.portfolioPieSlices,
                                        selectedSliceId: $selectedPieSliceId,
                                        isLoading: viewModel.reloading,
                                        hideData: viewModel.hideData
                                    )
                                    .padding(EdgeInsets(top: 48, leading: 16, bottom: 48, trailing: 16))
                                    .frame(height: max(1, lineChartHeight))
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    ))
                                } else {
                                    VStack(spacing: 0) {
                                        hoverTexts
                                            .accessibilityHidden(!viewModel.isDragging)
                                        
                                        ZStack {
                                            ChartBackground(
                                                biggestValue: $biggestChartValue,
                                                values: viewModel.graphStats
                                            )
                                            
                                            if viewModel.reloading {
                                                ActivityIndicator()
                                                    .padding(.trailing, biggestChartValue.width)
                                                    .accessibilityHidden(true)
                                            } else {
                                                NewChartView(
                                                    prices: viewModel.prices,
                                                    color: viewModel.graphColor,
                                                    lineWidth: 2,
                                                    dragPositions: viewModel.dragPositions,
                                                    size: viewModel.chartSize,
                                                    isDragging: viewModel.isDragging,
                                                    dropCount: viewModel.chartDropCount,
                                                    isEmptyAtBottom: true
                                                )
                                                .readSize {
                                                    viewModel.chartSize = $0
                                                }
                                                .padding(
                                                    EdgeInsets(
                                                        top: halfBiggestChartValueHeight,
                                                        leading: 0,
                                                        bottom: halfBiggestChartValueHeight,
                                                        trailing: biggestChartValue.width
                                                    )
                                                )
                                                .frame(height: max(1, reader.size.height * 0.35))
                                                
                                                if !viewModel.benchmarkPrices.isEmpty {
                                                    NewChartView(
                                                        prices: viewModel.benchmarkPrices,
                                                        color: Color.primary,
                                                        isGraphFilled: false,
                                                        lineWidth: 2,
                                                        dragPositions: viewModel.dragPositions,
                                                        size: viewModel.chartSize,
                                                        isDragging: viewModel.isDragging,
                                                        dropCount: viewModel.chartDropCount,
                                                        dash: [6, 4]
                                                    )
                                                    .padding(
                                                        EdgeInsets(
                                                            top: halfBiggestChartValueHeight,
                                                            leading: 0,
                                                            bottom: halfBiggestChartValueHeight,
                                                            trailing: biggestChartValue.width
                                                        )
                                                    )
                                                    .frame(height: max(1, reader.size.height * 0.35))
                                                    .allowsHitTesting(false)
                                                }
                                                
                                                ChartHoverView(
                                                    positions: viewModel.dragPositions,
                                                    size: viewModel.chartSize,
                                                    color: viewModel.graphColor,
                                                    topPadding: halfBiggestChartValueHeight
                                                )
                                                .opacity(viewModel.isDragging ? 1 : 0)
                                                .frame(height: viewModel.chartSize.height + halfBiggestChartValueHeight)
                                                .padding(.bottom, halfBiggestChartValueHeight)
                                                
                                                MultiTouchView { touches in
                                                    viewModel.updateHoverStats(touches: touches)
                                                }
                                                .accessibilityHidden(true)
                                            }
                                        }
                                        .animation(.none, value: viewModel.isDragging)
                                        .delayTouches()
                                        .padding(.horizontal, 16)
                                        .frame(height: max(1, reader.size.height * 0.35))
                                        .chartAccessibilityOverlay(
                                            timeStamps: viewModel.portfolio?.isEmpty ?? true ? [] : viewModel.getTimeStamps(dropLastTwo: viewModel.benchmarkCoin != nil),
                                            prices: viewModel.getPrices(dropLastTwo: viewModel.benchmarkCoin != nil),
                                            timeChart: .aWeek,
                                            comparePrices: viewModel.benchmarkPrices.isEmpty ? nil : viewModel.getBenchmarkPrices(dropLastTwo: true),
                                            mainSeriesName: viewModel.benchmarkCoin == nil ? nil : "Portfolio",
                                            compareSeriesName: viewModel.benchmarkCoin?.name,
                                            priceFormatter: { price in
                                                viewModel.hideData ? String.stars : price.formatAccessibleCurrency()
                                            },
                                            trailingPadding: biggestChartValue.width
                                        )
                                        
                                        ChartTimeStamps(
                                            currentTimeChart: .aWeek,
                                            timeStamps: viewModel.getTimeStamps(dropLastTwo: viewModel.benchmarkCoin != nil),
                                            accessibilityTexts: viewModel.chartValues
                                        )
                                        .accessibilityHidden(true)
                                        .padding(
                                            EdgeInsets(
                                                top: -biggestChartValue.height / 2,
                                                leading: 16,
                                                bottom: (viewModel.benchmarkCoin == nil ? 32 : 16) + biggestChartValue.height / 2,
                                                trailing: 16 + biggestChartValue.width
                                            )
                                        )
                                        
                                        if let benchmarkCoin = viewModel.benchmarkCoin {
                                            HStack(spacing: 8) {
                                                CompareRectangleView(color: viewModel.graphColor)
                                                
                                                Text("Portfolio")
                                                    .foregroundStyle(Color.onSurfaceDimmer)
                                                    .font(.satoshiBold(16))
                                                    .padding(.trailing, 24)
                                                
                                                CompareRectangleView(color: Color.primary)
                                                
                                                Text(benchmarkCoin.symbol?.uppercased() ?? "")
                                                    .foregroundStyle(Color.onSurfaceDimmer)
                                                    .font(.satoshiBold(16))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.bottom, 32)
                                            .accessibilityElement(children: .contain)
                                        }
                                    }
                                    .readSize {
                                        lineChartHeight = $0.height
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading),
                                        removal: .move(edge: .trailing)
                                    ))
                                }
                            }
                            
                            Section(header: pageSelector) {
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
                                        groupedTransactions: viewModel.groupedTransactions,
                                        prices: viewModel.allPrices,
                                        hideData: viewModel.hideData,
                                        typeFilters: viewModel.typeFilters,
                                        dateFilter: viewModel.dateFilter,
                                        coinFilters: viewModel.coinFilters,
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
                                            viewModel.dateFilter = .all
                                            viewModel.typeFilters = []
                                            viewModel.coinFilters = []
                                            temporaryCustomDate = DateOption.custom(startDate: nil, endDate: nil)
                                        },
                                        showTransactionDetails: { event in
                                            if let transaction = event as? NewTransaction {
                                                AnalyticsManager.shared.log(
                                                    SheetOpened(fromScreen: .portfolio, sheet: .portfolioTransactionDetails)
                                                )
                                                selectedEvent = PortfolioEventWrapper.transaction(transaction)
                                            } else if let swap = event as? NewSwapTransaction {
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
                .onAppear {
                    isPieChartShowing = SettingsManager.shared.get(key: AppSettingKey.isPortfolioPieChartShowing) ?? false
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
                .task(id: viewModel.dateFilter) {
                    await viewModel.setGroupTransactions()
                }
                .task(id: viewModel.typeFilters) {
                    await viewModel.setGroupTransactions()
                }
                .task(id: viewModel.coinFilters) {
                    await viewModel.setGroupTransactions()
                }
                .accessibilityHidden(showPortfolioCurrencySelector || showPortfolioCloudRecovery)
                .animation(.none, value: viewModel.hideData)
                .onReceive(NotificationCenter.default.publisher(for: .closeAllOverlays, object: nil)) { notification in
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
    private var totalValueView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Value")
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            HStack(alignment: .center, spacing: 8) {
                let totalValue = viewModel.totalValue?.formatCurrency(threshold: isHorizontal ? FormattingThreshold.billion : FormattingThreshold.thousand) ?? "000000000"
                
                NewShimmeringText(
                    text: viewModel.hideData ? String.stars : totalValue,
                    isDownloading: viewModel.totalValue == nil
                )
                .font(.satoshiBold(36))
                .foregroundStyle(Color.onSurface)
                .accessibilityLabel("Portfolio value: \(viewModel.hideData ? String.stars : totalValue)")
                
                (viewModel.hideData ? Image.unhide : Image.hide)
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(12)
                    .onTapGesture {
                        viewModel.toggleHideData()
                        if viewModel.hideData {
                            AnalyticsManager.shared.log(PortfolioDataHide(fromScreen: .portfolio))
                        } else {
                            AnalyticsManager.shared.log(PortfolioDataShow(fromScreen: .portfolio))
                        }
                    }
                    .accessibilityLabel("\(viewModel.hideData ? "show" : "hide") portfolio data")
                
                Spacer(minLength: 0)
                
                pieChartToggleButton
            }
        }
        .animation(.none, value: viewModel.hideData)
        .padding(.horizontal, 16)
    }
    
    private var pieChartToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                selectedPieSliceId = nil
                isPieChartShowing.toggle()
            }

            SettingsManager.shared.set(data: isPieChartShowing, key: AppSettingKey.isPortfolioPieChartShowing)
        }, label: {
            (isPieChartShowing ? Image.lineChart : Image.portfolio)
                .resizable()
                .frame(width: 24 * min(1.5, scale), height: 24 * min(1.5, scale))
                .foregroundStyle(Color.onSurface)
                .padding(12)
                .optionalGlassEffect(
                    color: Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                .accessibilityLabel(pieChartToggleAccessibilityLabel)
                .accessibilityAddTraits(.isToggle)
        })
    }
    
    private var pieChartToggleAccessibilityLabel: String {
        "Switch to \(isPieChartShowing ? "line chart" : "pie chart")"
    }
    
    @ViewBuilder
    private var valueChangeView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Value Change (7d)")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            OverflowLayout(spacing: 4) {
                if viewModel.hideData {
                    HStack(spacing: 4) {
                        NewShimmerImageDirection(
                            change: 0,
                            size: .medium,
                            isDownloading: viewModel.changePercent == nil
                        )
                        
                        Text(String.stars)
                            .font(.satoshiBold(14))
                            .foregroundStyle(Color.onSurfaceDim)
                    }
                } else {
                    NewPriceChangeValueView(
                        change: viewModel.changeValue,
                        size: .small,
                        accessibleTimeframe: "7 days",
                        isDownloading: viewModel.changeValue == nil
                    )
                }
                
                let formattedChange = (viewModel.changePercent ?? 0).formatted(
                    isHorizontal
                    ? .number.notation(.compactName).precision(.fractionLength(2))
                    : .number.precision(.fractionLength(2))
                ).changeWithSymbol
                
                NewShimmeringText(
                    text: "(\(((viewModel.changePercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? "-" : (formattedChange + "%")))",
                    isDownloading: viewModel.changePercent == nil
                )
                .foregroundStyle((viewModel.changePercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true) ? Color.onSurfaceDim : viewModel.hideData ? Color.onSurfaceDim : viewModel.changePercent?.changeColor ?? .onSurfaceDim)
                .font(.satoshiBold(14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(valueChangeAccessibilityLabel)
    }
    
    private var valueChangeAccessibilityLabel: String {
        portfolioChangeAccessibilityLabel(
            title: "7 days value change",
            value: viewModel.changeValue,
            percent: viewModel.changePercent
        )
    }
    
    @ViewBuilder
    private var profitLossView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Profit/Loss")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            OverflowLayout(spacing: 4) {
                if viewModel.hideData {
                    HStack(spacing: 4) {
                        NewShimmerImageDirection(
                            change: 0,
                            size: .medium,
                            isDownloading: viewModel.profitLossValue == nil
                        )
                        
                        Text(String.stars)
                            .font(.satoshiBold(14))
                            .foregroundStyle(Color.onSurfaceDim)
                    }
                } else {
                    NewPriceChangeValueView(
                        change: viewModel.profitLossValue,
                        size: .small,
                        hideData: viewModel.hideData,
                        accessibleTimeframe: "",
                        isDownloading: viewModel.profitLossValue == nil
                    )
                }
                
                let formattedChange = (viewModel.profitLossPercent ?? 0).formatted(
                    isHorizontal
                    ? .number.notation(.compactName).precision(.fractionLength(2))
                    : .number.precision(.fractionLength(2))
                ).changeWithSymbol
                
                NewShimmeringText(
                    text: "(\(((viewModel.profitLossPercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? "-" : (formattedChange + "%")))",
                    isDownloading: viewModel.profitLossPercent == nil
                )
                .foregroundStyle(((viewModel.profitLossPercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? Color.onSurfaceDim : viewModel.profitLossPercent?.changeColor ?? .onSurfaceDim)
                .font(.satoshiBold(14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(profitLossAccessibilityLabel)
    }
    
    private var profitLossAccessibilityLabel: String {
        portfolioChangeAccessibilityLabel(
            title: "Profit/Loss",
            value: viewModel.profitLossValue,
            percent: viewModel.profitLossPercent
        )
    }
    
    private func portfolioChangeAccessibilityLabel(
        title: String,
        value: Double?,
        percent: Double?
    ) -> String {
        let isEmpty = viewModel.portfolio?.isEmpty ?? true
        let changePercent = isEmpty ? 0 : (percent ?? 0)
        let safeChange = changePercent.isInfinite ? 0 : changePercent
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        let percentText = "\(direction) \(accessiblePercent) percent"
        
        if viewModel.hideData {
            return "\(title), \(percentText)"
        }
        
        let changeValue = isEmpty ? 0 : (value ?? 0)
        let valueDirection = changeValue.directionAccessible.lowercased()
        let valueText = abs(changeValue).formatAccessibleCurrency()
        
        return "\(title), \(valueDirection) \(valueText), \(percentText)"
    }
    
    @ViewBuilder
    private var hoverTexts: some View {
        if viewModel.hoverHelper.hoverPrices.count == 2 {
            NewMultiHoverTextView(
                hoverTimes: viewModel.hoverHelper.hoverTimes,
                differenceValue: viewModel.differenceValue,
                differencePercent: viewModel.differencePercent,
                color: viewModel.graphColor,
                xPosition: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize)
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: .onSurface,
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
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
    
    @ViewBuilder
    private var actionButtons: some View {
        ZStack(alignment: .bottomTrailing) {
            if isActionMenuExpanded {
                Color.black.opacity(0.00001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isActionMenuExpanded = false
                    }
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                if isActionMenuExpanded {
                    PrimaryButton(
                        text: "Add Transaction",
                        action: {
                            Task {
                                let hasPro = await viewModel.hasBoughtPro()
                                if (viewModel.portfolio?.allTransactionsCount ?? 0) >= 3 && !hasPro {
                                    AnalyticsManager.shared.log(
                                        BuyProOpened(fromScreen: .portfolio, action: .AddTransaction)
                                    )
                                    showBuyPro()
                                } else {
                                    AnalyticsManager.shared.log(
                                        SheetOpened(fromScreen: .portfolio, sheet: .portfolioAddTransactionType)
                                    )
                                    isTransactionTypeSheetShowing = true
                                }
                            }
                            
                            isActionMenuExpanded = false
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityFocused($actionMenuFocus, equals: .addTransaction)
                    .onAppear {
                        focusAddTransactionButton()
                    }
                    
                    PrimaryButton(
                        text: "Import Wallet (Pro)",
                        action: {
                            isActionMenuExpanded = false
                            
                            Task {
                                if await viewModel.hasBoughtPro() {
                                    AnalyticsManager.shared.log(
                                        Navigate(fromScreen: .portfolio, toScreen: .newImportTransaction)
                                    )
                                    navigationViewModel.navPath.append(
                                        NavigationScreens.NewImportTransaction
                                    )
                                } else {
                                    AnalyticsManager.shared.log(
                                        BuyProOpened(fromScreen: .portfolio, action: .ImportWallet)
                                    )
                                    navigationViewModel.showBuyPro = true
                                }
                            }
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityLabel("Import wallet, pro feature")
                    .accessibilityFocused($actionMenuFocus, equals: .importWallet)
                    
                    PrimaryButton(
                        text: "Export Portfolio",
                        action: {
                            isActionMenuExpanded = false
                            
                            guard (viewModel.portfolio?.allTransactionsCount ?? 0) > 0 else { return }
                            
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .portfolioExportFormat)
                            )
                            isExportFormatSheetShowing = true
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .disabled((viewModel.portfolio?.allTransactionsCount ?? 0) == 0)
                    .accessibilityLabel("Export portfolio")
                    .accessibilityFocused($actionMenuFocus, equals: .exportPortfolio)
                    
                    #if DEBUG
                    PrimaryButton(
                        text: viewModel.benchmarkCoin == nil
                            ? "Benchmark"
                            : "Benchmark (\(viewModel.benchmarkCoin?.symbol?.uppercased() ?? ""))",
                        action: {
                            isActionMenuExpanded = false
                            
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .portfolio, sheet: .coinSearch)
                            )
                            isBenchmarkCoinSelectorShowing = true
                        }
                    )
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .accessibilityLabel(
                        viewModel.benchmarkCoin == nil
                            ? "Benchmark portfolio"
                            : "Change benchmark, currently \(viewModel.benchmarkCoin?.name ?? "")"
                    )
                    .accessibilityFocused($actionMenuFocus, equals: .benchmark)
                    
                    if viewModel.benchmarkCoin != nil {
                        PrimaryButton(
                            text: "Remove Benchmark",
                            action: {
                                isActionMenuExpanded = false
                                viewModel.clearBenchmark()
                            }
                        )
                        .padding(.trailing, 16)
                        .transition(.move(edge: .trailing))
                        .accessibilityLabel("Remove benchmark")
                        .accessibilityFocused($actionMenuFocus, equals: .removeBenchmark)
                    }
                    #endif
                }
                
                Button(action: {
                    if isActionMenuExpanded {
                        isActionMenuExpanded = false
                    } else {
                        isActionMenuExpanded = true
                        focusAddTransactionButton()
                    }
                }, label: {
                    Image.plus
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(isActionMenuExpanded ? Color.onSurfaceContainerDim : Color.onPrimary)
                        .padding(16)
                        .optionalGlassEffect(
                            color: isActionMenuExpanded ? Color.surfaceContainerHighest : Color.primary,
                            radius: 1000,
                            isInteractive: true
                        )
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: 16,
                                trailing: 16
                            )
                        )
                })
                .accessibilityLabel(isActionMenuExpanded ? "Close add menu" : "Add portfolio item")
                .accessibilityHint(
                    isActionMenuExpanded
                        ? ""
                        : {
                            #if DEBUG
                            "Shows add transaction, import wallet, export portfolio, and benchmark options"
                            #else
                            "Shows add transaction, import wallet, and export portfolio options"
                            #endif
                        }()
                )
                .accessibilityFocused($actionMenuFocus, equals: .fab)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.default, value: isActionMenuExpanded)
        .onChange(of: actionMenuFocus) { old, new in
            if old == .removeBenchmark && new != .benchmark {
                isActionMenuExpanded = false
            } else if old == .benchmark && new != .exportPortfolio && new != .removeBenchmark {
                isActionMenuExpanded = false
            } else if old == .exportPortfolio && new != .importWallet && new != .benchmark {
                isActionMenuExpanded = false
            } else if old == .importWallet && new != .addTransaction && new != .exportPortfolio {
                isActionMenuExpanded = false
            }
        }
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
        let onComplete: (Bool) -> Void = { completed in
            guard completed else { return }
            AchievementManager.shared.increment(.portfolioExports)
        }
        
        switch format {
        case .csv:
            viewModel.exportPortfolioCSV(onComplete: onComplete)
        case .json:
            viewModel.exportPortfolioJSON(onComplete: onComplete)
        case .plainText:
            viewModel.exportPortfolioText(onComplete: onComplete)
        case .koinly:
            viewModel.exportPortfolioKoinly(onComplete: onComplete)
        case .coinTracker:
            viewModel.exportPortfolioCoinTracker(onComplete: onComplete)
        case .tokenTax:
            viewModel.exportPortfolioTokenTax(onComplete: onComplete)
        case .zenLedger:
            viewModel.exportPortfolioZenLedger(onComplete: onComplete)
        }
    }
    
    private func focusAddTransactionButton() {
        asyncMain(delay: 0.35) {
            actionMenuFocus = .addTransaction
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }
}
