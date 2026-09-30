//
//  ContentView.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-23.
//

import SwiftUI

struct CryptoDetailScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State var viewModel: CryptoDetailViewModelImp
    @State private var newsViewModel = CryptoDetailNewsViewModel()
    @State private var portfolioViewModel = CryptoDetailPortfolioViewModel()
    @State private var alertsViewModel = CryptoDetailAlertsViewModel()
    
    @State private var currentPage: Int? = 0
    
    @State private var showCompareCoinSelector = false
    @State private var isSelectingMainCoin = false
    
    @State private var biggestChartValue: CGSize = .zero
    
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var isSelectingCurrency = false
    
    @State private var showScrollToTopButton = false
    @State private var previousScrollOffset: CGFloat = 0
    
    private let newsErrorString = "coin"
    
    @State private var isSortShowing = false
    @State private var scrollToTop = false
    @State private var id = UUID()
    
    // Price alert
    @State private var selectedAlertCurrencyModel: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var showAddAlert = false
    @State private var showAlertError = false
    @State private var isAddingAlert = false
    @State private var isSelectingAlertCurrency = false
    
    @State private var isAlertByPriceSelected = true
    @State private var priceInput: Double? = 0.0
    @State private var percentInput: Double? = 10.0
    @State private var isRecurringAlertOn = false
    @State private var selectedDirection: ChangeDirection = .up
    
    @State private var showCommunitySentimentHelp = false
    
    @State private var showAddTransactionSheet = false
    @State private var selectedEvent: PortfolioEventWrapper?
    @State private var appLanguage = AppLanguagePreference.stored
    
    var binding: Binding<String?> {
        Binding(
            get: { navigationViewModel.newsUrl },
            set: { navigationViewModel.newsUrl = $0 }
        )
    }
    
    init(cryptoInfo: CurrencyDataModel) {
        _viewModel = State(wrappedValue: CryptoDetailViewModelImp(cryptoInfo: cryptoInfo))
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader  in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            CryptoDetailSummaryView(
                                name: viewModel.cryptoInfo?.name,
                                currentPrice: viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency(),
                                imageUrl: viewModel.cryptoInfo?.image?.small,
                                prices: viewModel.candleChartEnabled ? viewModel.candlePrices : viewModel.onlyPrices,
                                isSharing: false,
                                image: viewModel.currencyLogo,
                                selectedTimeframe: viewModel.selectedTimeFrame,
                                shortPrice: false,
                                shortChange: false,
                                changeCoinAccessibilityHint: "Double tap to change the coin",
                                isWebSocketEnabled: viewModel.isWebSocketEnabled,
                                changeCoin: {
                                    AnalyticsManager.shared.log(
                                        SheetOpened(fromScreen: .cryptoDetail, sheet: .coinSearch)
                                    )
                                    isSelectingMainCoin = true
                                    showCompareCoinSelector = true
                                }
                            )
                            .padding(.horizontal, 16)
                            
                            ChartTypeButtonsView(
                                fromScreen: .cryptoDetail,
                                selectedGraphType: viewModel.currentChartType,
                                isCandleChartEnabled: viewModel.isCandleChartEnabled,
                                imageCase: .fixed(viewModel.candleChartEnabled ? .lineChart : .candlestick),
                                chartTypeAction: { type in
                                    viewModel.setChartType(type: type)
                                }, toggleCandleChart: {
                                    let isCandleAfterToggle = !viewModel.candleChartEnabled
                                    AnalyticsManager.shared.log(
                                        ChartCandleModeChanged(fromScreen: .cryptoDetail, isCandleChart: isCandleAfterToggle)
                                    )
                                    await viewModel.toggleChart()
                                }
                            )
                            
                            ZStack {
                                CandleChartHoverStatsView(
                                    currentCandle: viewModel.hoverHelper.currentCandle,
                                    xPosition: viewModel.hoverCandleTimePosition,
                                    hoverCandleTimeWidthSize: $viewModel.hover.hoverCandleTimeWidthSize
                                )
                                .opacity(viewModel.isDragging && viewModel.isCandleChartEnabled ? 1 : 0)
                                .animation(.default, value: viewModel.isDragging)
                                
                                hoverTexts
                            }
                            
                            ZStack {
                                ChartBackground(
                                    biggestValue: $biggestChartValue,
                                    values: viewModel.mainGraphStats
                                )
                                
#if DEBUG
                                BannerLogoView()
                                    .padding(.trailing, biggestChartValue.width)
#endif
                                
                                if viewModel.mainReloading {
                                    ActivityIndicator()
                                        .padding(.trailing, biggestChartValue.width)
                                        .accessibilityHidden(true)
                                } else {
                                    if viewModel.isCandleChartEnabled {
                                        candleGraph(
                                            halfBiggestChartValueHeight: halfBiggestChartValueHeight,
                                        )
                                        .opacity(viewModel.showMainPriceError ? 0 : 1)
                                        .frame(height: max(1, reader.size.height * 0.35))
                                    } else {
                                        mainGraph(
                                            halfBiggestChartValueHeight: halfBiggestChartValueHeight,
                                        )
                                        .opacity(viewModel.showMainPriceError ? 0 : 1)
                                        .frame(height: max(1, reader.size.height * 0.35))
                                    }
                                    
                                    MultiTouchView { touches in
                                        viewModel.updateHoverStats(touches: touches)
                                    }
                                    .accessibilityHidden(true)
                                }
                            }
                            .animation(.none, value: viewModel.isDragging)
                            .delayTouches()
                            .frame(height: max(1, reader.size.height * 0.35))
                            .chartAccessibilityOverlay(
                                timeStamps: viewModel.isCandleChartEnabled ? [] : viewModel.getTimestamps(),
                                prices: viewModel.getPrices(),
                                timeChart: viewModel.selectedTimeFrame,
                                trailingPadding: biggestChartValue.width
                            )
                            .padding(.horizontal, 16)
                            
                            ChartTimeStamps(
                                currentTimeChart: viewModel.selectedTimeFrame,
                                timeStamps: viewModel.isCandleChartEnabled ? viewModel.candleTimestamps : viewModel.getTimestamps()
                            )
                            .accessibilityHidden(true)
                            .padding(
                                EdgeInsets(
                                    top: -biggestChartValue.height / 2,
                                    leading: 16,
                                    bottom: biggestChartValue.height / 2,
                                    trailing: 16 + biggestChartValue.width
                                )
                            )
                            
                            ChartTimeframeButtonsView(
                                fromScreen: .cryptoDetail,
                                chartButtons: ChartButton.getButtons(from: .anHour, to: .max),
                                selectedNumber: viewModel.selectedTimeFrame.rawValue,
                                reader: reader,
                                action: { button in
                                    if !viewModel.isDragging {
                                        await viewModel.refresh(
                                            newDays: button.days,
                                            newTimeChart: button.timeChart
                                        )
                                    }
                                }
                            )
                            
                            Section(header: pageSelector) {
                                if currentPage == 0 {
                                    CryptoDetailOverviewView(
                                        cryptoDetailModel: viewModel.cryptoInfo,
                                        timeChart: viewModel.selectedTimeFrame,
                                        prices: viewModel.isCandleChartEnabled ? viewModel.candlePrices : viewModel.onlyPrices,
                                        totalMarketCap: viewModel.globalMarketData?.data?.total_market_cap?.getConvertedCurrency(),
                                        alerts: alertsViewModel.alerts,
                                        fromScreen: .cryptoDetail,
                                        isSelectingCurrency: $isSelectingCurrency,
                                        selectedCurrency: $selectedCurrency,
                                        showCommunitySentimentHelp: $showCommunitySentimentHelp,
                                        addNewAlert: {
                                            Task {
                                                await openNewPriceAlertIfAllowed()
                                            }
                                        },
                                        deleteAlert: { alert in
                                            Task {
                                                showSnackBar(
                                                    message: Localization.string("Price alert deleted."),
                                                    type: .success
                                                )
                                                await alertsViewModel.deleteAlert(alert: alert)
                                                AnalyticsManager.shared.log(
                                                    PriceAlertDeleted(fromScreen: .cryptoDetail, coinName: viewModel.cryptoInfo?.name ?? "")
                                                )
                                            }
                                        }
                                    )
                                } else if currentPage == 1 {
                                    CryptoDetailAboutView(
                                        description: viewModel.cryptoInfo?.description,
                                        links: viewModel.cryptoInfo?.links,
                                        newsUrl: binding
                                    )
                                } else if currentPage == 2 {
                                    CryptoDetailPortfolioView(
                                        cryptoInfo: viewModel.cryptoInfo,
                                        groupedTransactions: portfolioViewModel.groupedTransactions,
                                        viewModel: portfolioViewModel,
                                        showAddTransactionSheet: $showAddTransactionSheet,
                                        showTransactionDetails: { event in
                                            if let transaction = event as? PortfolioTransaction {
                                                AnalyticsManager.shared.log(
                                                    SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
                                                )
                                                selectedEvent = PortfolioEventWrapper.transaction(transaction)
                                            } else if let swap = event as? PortfolioSwapTransaction {
                                                AnalyticsManager.shared.log(
                                                    SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
                                                )
                                                selectedEvent = PortfolioEventWrapper.swap(swap)
                                            } else if event is AddressImport {
                                                guard
                                                    let wallet = event as? AddressImport,
                                                    let coin = portfolioViewModel.pie?.data
                                                else {
                                                    return
                                                }

                                                AnalyticsManager.shared.log(
                                                    Navigate(
                                                        fromScreen: .cryptoDetail,
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
                                    .id(viewModel.cryptoInfo?.id)
                                } else if currentPage == 3 {
                                    CryptoDetailExchangesView(
                                        items: viewModel.exchangeMarketItems,
                                        headerLabel: "Exchange",
                                        showVolumeOverride: true,
                                        fromScreen: .cryptoDetail,
                                        selectedSortOption: viewModel.selectedSortOption,
                                        errorMessage: newsErrorString,
                                        isSortShowing: $isSortShowing
                                    )
                                } else if currentPage == 4 {
                                    DetailNews(
                                        title: viewModel.cryptoInfo?.name,
                                        fromScreen: .cryptoDetail,
                                        news: newsViewModel.news,
                                        showError: newsViewModel.showNewsError,
                                        errorMessage: newsErrorString,
                                        refresh: {
                                            await newsViewModel.getNews(coinId: viewModel.cryptoInfo?.id)
                                        }
                                    )
                                }
                            }
                            .animation(.none, value: currentPage)
                            .accessibilitySortPriority(-2)
                        }
                        .padding(.bottom, 32)
                    }
                    .scrollDisabled(viewModel.isDragging)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { oldOffset, newOffset in
                        let isScrollingUp = newOffset < previousScrollOffset
                        
                        if newOffset > (reader.size.height * 1.5) && !isScrollingUp {
                            showScrollToTopButton = true
                        } else if newOffset < reader.size.height || isScrollingUp {
                            showScrollToTopButton = false
                        }
                        
                        previousScrollOffset = newOffset
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .bottomTrailing) {
                        if !accessibilityVoiceOverEnabled {
                            ScrollUpButton(
                                action: {
                                    AnalyticsManager.shared.log(
                                        ScrollToTopPressed(
                                            fromScreen: .cryptoDetail,
                                            selectedTabName: currentPage.cryptoDetailPageTabName
                                        )
                                    )
                                    scrollToTop.toggle()
                                },
                                isVisible: showScrollToTopButton && (currentPage == 3 || currentPage == 4)
                            )
                        }
                    }
                    .onChange(of: scrollToTop) {
                        withAnimation(Animation.easeInOut(duration: 0.25)) {
                            scrollViewReader.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }
            
            EdgeSwipe(isDragging: viewModel.isDragging)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitle(viewModel.cryptoInfo?.name ?? "", displayMode: .inline)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
            if currentPage == 4 {
                Task { await newsViewModel.getNews(coinId: viewModel.cryptoInfo?.id) }
            }
        }
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbar {
            toolbarFavoriteButton
            
            toolbarMenuButton
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTransaction, object: nil)) { notification in
            Task {
                let previousTransactionCount = notification.userInfo?["previousTransactionCount"] as? Int

                guard
                    let transaction = notification.userInfo?["transaction"] as? String else {
                    return
                }

                let (event, coin) = await portfolioViewModel.findTransaction(transaction: transaction)
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
                                SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
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
                                SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
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
                                    fromScreen: .cryptoDetail,
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
        .task {
            AchievementManager.shared.increment(.cryptoDetailsViewed)
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await alertsViewModel.load(coinId: viewModel.cryptoInfo?.id) }
                group.addTask {
                    await viewModel.refresh(
                        showReload: viewModel.mainReloading
                    )
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await alertsViewModel.getPriceAlerts() }
                        group.addTask {
                            await viewModel.refresh(
                                showReload: viewModel.mainReloading
                            )
                        }
                    }
                }
            case .background, .inactive:
                Task {
                    await viewModel.stopLivePriceUpdates()
                }
            @unknown default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.refresh(
                        showReload: false
                    )
                }
                
                if currentPage == 2 {
                    group.addTask {
                        await portfolioViewModel.load(coinId: viewModel.cryptoInfo?.id)
                    }
                }
                
                if currentPage == 4 {
                    group.addTask {
                        await newsViewModel.getNews(coinId: viewModel.cryptoInfo?.id)
                    }
                }
            }
        }
        .task(id: "\(currentPage ?? -1)-\(viewModel.cryptoInfo?.id ?? "")") {
            guard viewModel.cryptoInfo?.id != nil else {
                return
            }

            if currentPage == 2 {
                await portfolioViewModel.load(coinId: viewModel.cryptoInfo?.id)
            } else if currentPage == 4 {
                await newsViewModel.getNews(coinId: viewModel.cryptoInfo?.id)
            }
        }
        .onDisappear {
            Task {
                await viewModel.stopLivePriceUpdates()
            }
        }
        .onChange(of: currentPage) { _, page in
            AnalyticsManager.shared.log(
                TabChanged(fromScreen: .cryptoDetail, selectedTabName: page.cryptoDetailPageTabName)
            )
        }
        .sheet(isPresented: $showCompareCoinSelector) {
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .cryptoDetail,
                highlightId: viewModel.cryptoInfo?.id,
                hideId: nil,
                close: { id, _, name in
                    showCompareCoinSelector = false
                    
                    guard let id else {
                        return
                    }
                    
                    if isSelectingMainCoin {
                        Task {
                            AnalyticsManager.shared.log(
                                ChangeCompareCoin(
                                    fromScreen: .cryptoDetail,
                                    selection: .main,
                                    coinName: name ?? ""
                                )
                            )
                            portfolioViewModel.reset()
                            await viewModel.newMainCoin(id: id)
                            await withTaskGroup(of: Void.self) { group in
                                group.addTask { await alertsViewModel.load(coinId: id) }
                                group.addTask { await portfolioViewModel.load(coinId: id) }
                            }
                        }
                    } else {
                        AnalyticsManager.shared.log(
                            Navigate(fromScreen: .cryptoDetail, toScreen: .compareCoins, coinName: name)
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.CompareCoins(
                                cryptoInfo: viewModel.cryptoInfo,
                                priceVolumeModel: viewModel.priceVolumeModel,
                                compareId: id
                            )
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.cryptoDetailOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .cryptoDetail, option: option)
                    )
                    Task {
                        await viewModel.setNewSortOption(newSortOption: option)
                    }
                }
            )
        }
        .sheet(isPresented: $isSelectingCurrency) {
            CurrencyOptionsSheet(
                selectedSortOption: selectedCurrency,
                newOptionSelected: {
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .cryptoDetail, currency: $0.currency)
                    )
                    selectedCurrency = $0
                }
            )
        }
        .sheet(isPresented: $showAddAlert) {
            CreatePriceAlertSheet(
                currencyDataModel: viewModel.cryptoInfo,
                selectedCurrency: selectedAlertCurrencyModel,
                isLoading: isAddingAlert,
                showError: showAlertError,
                isAlertByPriceSelected: $isAlertByPriceSelected,
                priceInput: $priceInput,
                percentInput: $percentInput,
                isRecurringAlertOn: $isRecurringAlertOn,
                selectedDirection: $selectedDirection,
                selectNewCurrency: {
                    showAddAlert = false
                    isSelectingAlertCurrency = true
                },
                addNewAlert: { alert in
                    isAddingAlert = true
                    let inputType: PriceAlertInputType = isAlertByPriceSelected ? .price : .percent
                    
                    Task {
                        switch await alertsViewModel.addPriceAlert(alertCoin: alert) {
                        case .success:
                            showSnackBar(
                                message: Localization.string("Price alert added."),
                                type: .success
                            )

                            AnalyticsManager.shared.log(
                                PriceAlertAdded(
                                    fromScreen: .cryptoDetail,
                                    coinName: viewModel.cryptoInfo?.name ?? "",
                                    isRecurring: alert.resetThreshold != nil,
                                    inputType: inputType
                                )
                            )
                            showAddAlert = false
                        case .fcmTokenUnavailable:
                            showSnackBar(
                                message: Localization.string("Something went wrong. Restart the app and try again."),
                                type: .failure
                            )
                        case .failure:
                            showAlertError.toggle()
                        }

                        isAddingAlert = false
                    }
                }
            )
        }
        .sheet(
            isPresented: $isSelectingAlertCurrency,
            onDismiss: {
                isSelectingAlertCurrency = false
                showAddAlert = true
            }
        ) {
            CurrencyOptionsSheet(
                selectedSortOption: selectedAlertCurrencyModel,
                newOptionSelected: {
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .cryptoDetail, currency: $0.currency)
                    )
                    selectedAlertCurrencyModel = $0
                }
            )
        }
        .sheet(isPresented: $showCommunitySentimentHelp) {
            CommunitySentimentHelpSheet()
        }
        .sheet(isPresented: $showAddTransactionSheet) {
            SelectTransactionTypeSheet(
                transactionSelected: { type in
                    if type == .swap {
                        AnalyticsManager.shared.log(
                            Navigate(fromScreen: .cryptoDetail, toScreen: .newSwapTransaction, coinName: viewModel.cryptoInfo?.name)
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.PortfolioSwapTransaction(
                                transactionType: type,
                                currencyDataModel: viewModel.cryptoInfo,
                                transaction: nil
                            )
                        )
                    } else {
                        AnalyticsManager.shared.log(
                            Navigate(fromScreen: .cryptoDetail, toScreen: .newPortfolioTransaction, coinName: viewModel.cryptoInfo?.name)
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.AddPortfolioTransaction(
                                transactionType: type,
                                currencyDataModel: viewModel.cryptoInfo,
                                transaction: nil
                            )
                        )
                    }
                }
            )
        }
        .sheet(item: $selectedEvent) { event in
            switch event {
            case .transaction(let transaction):
                let coin = portfolioViewModel.portfolio?.pie(containing: transaction)?.data
                
                TransactionDetailSheet(
                    coin: coin,
                    transaction: transaction,
                    hideData: portfolioViewModel.hidePortfolioData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .cryptoDetail,
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
                                fromScreen: .cryptoDetail,
                                coinName: coin?.name ?? "",
                                kind: .transaction
                            )
                        )
                        Task {
                            await portfolioViewModel.deleteTransaction(transaction)
                        }
                    }
                )
                
            case .swap(let swap):
                let coin = portfolioViewModel.portfolio?.pie(containing: swap)?.data

                SwapDetailSheet(
                    coin: coin,
                    transaction: swap,
                    portfolio: portfolioViewModel.portfolio,
                    hideData: portfolioViewModel.hidePortfolioData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .cryptoDetail,
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
                                fromScreen: .cryptoDetail,
                                coinName: coin?.name ?? "",
                                kind: .swap
                            )
                        )
                        Task {
                            await portfolioViewModel.deleteTransaction(transaction)
                        }
                    }
                )
                
            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private var toolbarFavoriteButton: some View {
        let isFavorited = viewModel.inFavoritesList
        let name = viewModel.cryptoInfo?.name ?? "coin"
        
        Button(action: {
            Task {
                await viewModel.handleFavoriteButtonPressed()
            }
        }) {
            (isFavorited ? Image.favoriteFilled : Image.favoriteOutline)
                .resizable()
                .frame(width: 24 * min(scale, 1.25), height: 24 * min(scale, 1.25), alignment: .center)
                .foregroundStyle(isFavorited ? Color.primary : Color.onSurface)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Localization.format(isFavorited ? "Remove %@ from favorites" : "Add %@ to favorites", name))
    }
    
    private var toolbarMenuButton: some View {
        Menu {
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .cryptoDetail, sheet: .coinSearch)
                )
                isSelectingMainCoin = false
                showCompareCoinSelector = true
            }, label: {
                HStack(spacing: 8) {
                    Image.converter
                    Text(Localization.string("Compare"))
                }
                .foregroundStyle(Color.onSurface)
            })
            
            Button(action: {
                Task {
                    await openNewPriceAlertIfAllowed()
                }
            }, label: {
                HStack(spacing: 8) {
                    Image.alert
                    Text(Localization.string("Add Alert"))
                }
                .foregroundStyle(Color.onSurface)
                .accessibilityLabel(Localization.format("Add new %@ price alert", viewModel.cryptoInfo?.name ?? ""))
            })
            
            Button(action: {
                viewModel.shareDetails()
            }, label: {
                HStack(spacing: 8) {
                    Image.share
                    Text(Localization.string("Share"))
                }
                .foregroundStyle(Color.onSurface)
            })
        } label: {
            Button(action: {
                
            }, label: {
                Image.more
                    .resizable()
                    .frame(width: 24 * min(scale, 1.25), height: 24 * min(scale, 1.25), alignment: .center)
                    .foregroundStyle(Color.onSurface)
            })
        }
        .accessibilityLabel(Localization.string("More options"))
    }
    
    @ViewBuilder
    private var hoverTexts: some View {
        if viewModel.hoverHelper.hoverPrices.count == 2 {
            MultiHoverTextView(
                hoverTimes: viewModel.hoverHelper.hoverTimes,
                differenceValue: viewModel.differenceValue,
                differencePercent: viewModel.differencePercent,
                color: viewModel.graphColor,
                xPosition: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize)
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging && !viewModel.candleChartEnabled ? 1 : 0
            )
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: .onSurface,
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging && !viewModel.candleChartEnabled ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        }
    }
    
    @ViewBuilder
    private func mainGraph(
        halfBiggestChartValueHeight: CGFloat,
    ) -> some View {
        PriceLineChartView(
            prices: viewModel.getPrices(),
            color: viewModel.graphColor,
            lineWidth: 2,
            dragPositions: viewModel.dragPositions,
            size: viewModel.chartSize,
            isDragging: viewModel.isDragging,
            showLivePriceIndicator: viewModel.isWebSocketEnabled
        )
        .padding(.leading, (viewModel.timeStamps.normalized.first ?? 0) * viewModel.chartSize.width)
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
        
        ChartHoverView(
            positions: viewModel.dragPositions,
            size: viewModel.chartSize,
            color: viewModel.graphColor,
            topPadding: halfBiggestChartValueHeight
        )
        .opacity(viewModel.isDragging ? 1 : 0)
        .frame(height: viewModel.chartSize.height + halfBiggestChartValueHeight * 2)
    }
    
    @ViewBuilder
    private func candleGraph(
        halfBiggestChartValueHeight: CGFloat,
    ) -> some View {
        ZStack {
            CandleStickView(
                candles: viewModel.candleSticks,
                viewWidth: viewModel.chartSize.width
            )
        }
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
        
        if viewModel.isDragging {
            CandleHoverLines(
                chartSize: viewModel.chartSize,
                xPosition: viewModel.hoverHelper.offset.first?.x ?? 0,
                yPosition: viewModel.pointCandle.y,
                isDragging: viewModel.isDragging,
                topPadding: halfBiggestChartValueHeight
            )
            .padding(.bottom, halfBiggestChartValueHeight)
        }
    }
    
    @ViewBuilder
    private var pageSelector: some View {
        let categories = ["Overview", "About", "Portfolio", "Markets", "News"]
        
        VStack(spacing: 0) {
            PageSelectorView(currentPage: $currentPage, titles: categories, pageSelected: { page in
                scrollToTop.toggle()
                
                withAnimation {
                    currentPage = page
                }
            })
            
            Separator()
        }
        .background(Color.surface)
        .id(id)
    }
    
    private func openNewPriceAlertIfAllowed() async {
        let alerts = await alertsViewModel.allAlertsCount()
        let success = await alertsViewModel.checkIfUserEnabledPush()
        let hasBoughtPro = await alertsViewModel.hasBoughtPro()
        
        if !success {
            AnalyticsManager.shared.log(
                Navigate(fromScreen: .cryptoDetail, toScreen: .priceAlerts, coinName: viewModel.cryptoInfo?.name)
            )
            navigationViewModel.deepLink(to: .PriceAlerts)
        } else if !hasBoughtPro && alerts >= 2 {
            AnalyticsManager.shared.log(
                BuyProOpened(fromScreen: .cryptoDetail, action: .PriceAlert)
            )
            showBuyPro()
        } else {
            AnalyticsManager.shared.log(
                SheetOpened(fromScreen: .cryptoDetail, sheet: .newPriceAlert)
            )
            isAlertByPriceSelected = true
            priceInput = 0.0
            percentInput = 10.0
            isRecurringAlertOn = false
            selectedDirection = .up
            showAddAlert = true
        }
    }
}
