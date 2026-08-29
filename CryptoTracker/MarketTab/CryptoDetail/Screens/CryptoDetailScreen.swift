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
    
    @State private var currentPage: Int? = 0
    
    @State private var isAddToWidgetShowing = false
    @State private var isEditWidgetShowing = false
    
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
                            
                            ChartButtonsView(
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
                                    hoverCandleTimeWidthSize: $viewModel.hoverCandleTimeWidthSize
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
                            
                            ChartButtonsViewNew(
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
                                        alerts: viewModel.alerts,
                                        fromScreen: .cryptoDetail,
                                        isSelectingCurrency: $isSelectingCurrency,
                                        selectedCurrency: $selectedCurrency,
                                        showCommunitySentimentHelp: $showCommunitySentimentHelp,
                                        addNewAlert: {
                                            Task {
                                                let alerts = await viewModel.getAllpriceAlertsCount()
                                                let success = await viewModel.checkIfUserEnabledPush()
                                                let hasBoughtPro = await viewModel.hasBoughtPro()
                                                
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
                                        },
                                        deleteAlert: { alert in
                                            Task {
                                                showSnackBar(
                                                    message: "Price alert deleted.",
                                                    type: .success
                                                )
                                                await viewModel.deleteAlert(alert: alert)
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
                                        viewModel: viewModel,
                                        showAddTransactionSheet: $showAddTransactionSheet,
                                        showTransactionDetails: { event in
                                            if let transaction = event as? NewTransaction {
                                                AnalyticsManager.shared.log(
                                                    SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
                                                )
                                                selectedEvent = PortfolioEventWrapper.transaction(transaction)
                                            } else if let swap = event as? NewSwapTransaction {
                                                AnalyticsManager.shared.log(
                                                    SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
                                                )
                                                selectedEvent = PortfolioEventWrapper.swap(swap)
                                            } else if event is AddressImport {
                                                guard
                                                    let wallet = event as? AddressImport,
                                                    let coin = viewModel.pie?.data
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
                                        news: viewModel.news,
                                        showError: viewModel.showNewsError,
                                        errorMessage: newsErrorString,
                                        refresh: {
                                            await viewModel.refresh(
                                                getNews: true
                                            )
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
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbar {
            toolbarFavoriteButton
            
            toolbarMenuButton
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeAllOverlays, object: nil)) { notification in
            closeAllOverlays()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTransaction, object: nil)) { notification in
            Task {
                let previousTransactionCount = notification.userInfo?["previousTransactionCount"] as? Int

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
                                SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioTransactionDetails)
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
                        message: "\(wallet.address.uppercased().prefix(5))...\(wallet.address.uppercased().suffix(5)) (\(coin.symbol?.uppercased() ?? "Coin")) imported to your portfolio!",
                        buttonTitle: "View Details",
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
                group.addTask { await viewModel.getPriceAlerts() }
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
                        group.addTask { await viewModel.getPriceAlerts() }
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
                        showReload: false,
                        getNews: currentPage == 4
                    )
                }
                
                if currentPage == 2 {
                    group.addTask {
                        await viewModel.getPortfolio()
                    }
                }
            }
        }
        .task(id: currentPage) {
            if currentPage == 2 {
                await viewModel.getPortfolio()
            } else if currentPage == 4 {
                await viewModel.getNews()
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
        /*.sheet(isPresented: $isAddToWidgetShowing) {
            AddToWidgetSheet(
                widgetsCount: viewModel.widgetCurrencies.count,
                deepLinkToWidget: {
                    navigationViewModel.deepLink(to: .Widgets)
                }
            )
        }*/
        .sheet(isPresented: $isEditWidgetShowing) {
            EditWidgetsSheet(
                widgetCoins: viewModel.widgetCurrencies,
                currentCoinName: viewModel.cryptoInfo?.name ?? "coin",
                replaceCoin: { toplist in
                    let mainSymbol = viewModel.cryptoInfo?.symbol?.uppercased() ?? ""
                    let replacedSymbol = toplist.symbol?.uppercased() ?? ""

                    AnalyticsManager.shared.log(
                        WidgetReplaced(
                            fromScreen: .cryptoDetail,
                            fromSymbol: mainSymbol,
                            toSymbol: replacedSymbol
                        )
                    )

                    Task {
                        await viewModel.replaceWidgetCurrency(coin: toplist)
                    }
                    
                    navigationViewModel.showSnackbar(
                        message: "Replaced \(mainSymbol) with \(replacedSymbol) in widgets.",
                        buttonTitle: "Undo",
                        snackBarType: .success,
                        buttonCallback: {
                            guard let toplistItem = viewModel.cryptoInfo?.toToplist() else { return }

                            AnalyticsManager.shared.log(
                                WidgetReplaceUndone(
                                    fromScreen: .cryptoDetail,
                                    fromSymbol: replacedSymbol,
                                    toSymbol: mainSymbol
                                )
                            )

                            Task {
                                await viewModel.replaceWidgetCurrency(coin: toplistItem, with: toplist)
                            }
                        }
                    )
                }
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
                            await viewModel.newMainCoin(id: id)
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
            NewPriceAlertSheet(
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
                        switch await viewModel.addPriceAlert(alertCoin: alert) {
                        case .success:
                            showSnackBar(
                                message: "Price alert added.",
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
                                message: "Something went wrong. Restart the app and try again.",
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
                            NavigationScreens.NewSwapTransaction(
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
                            NavigationScreens.NewPortfolioTransaction(
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
                let coin = viewModel.portfolio?.pie(containing: transaction)?.data
                
                TransactionDetailSheet(
                    coin: coin,
                    transaction: transaction,
                    hideData: viewModel.hidePortfolioData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .cryptoDetail,
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
                                fromScreen: .cryptoDetail,
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
                    hideData: viewModel.hidePortfolioData,
                    editTransaction: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .cryptoDetail,
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
                                fromScreen: .cryptoDetail,
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
        .accessibilityLabel(isFavorited ? "Remove \(name) from favorites" : "Add \(name) to favorites")
    }
    
    private var toolbarMenuButton: some View {
        Menu {
            let containsCurrency = viewModel.widgetCurrencies.contains(where: { $0.id == viewModel.cryptoInfo?.id })
            
            Button(action: {
                if containsCurrency {
                    AnalyticsManager.shared.log(
                        Navigate(fromScreen: .cryptoDetail, toScreen: .widgets, coinName: viewModel.cryptoInfo?.name)
                    )
                    navigationViewModel.deepLink(to: .Widgets)
                } else if viewModel.widgetCurrencies.count < 8 {
                    let addedSymbol = viewModel.cryptoInfo?.symbol?.uppercased() ?? ""
                    AnalyticsManager.shared.log(
                        WidgetAdded(fromScreen: .cryptoDetail, coinSymbol: addedSymbol)
                    )

                    Task {
                        await viewModel.addCurrencyToWidgets()
                        
                        navigationViewModel.showSnackbar(
                            message: "\(viewModel.cryptoInfo?.symbol?.uppercased() ?? "Coin") added to widgets.",
                            buttonTitle: "Manage",
                            snackBarType: .success,
                            buttonCallback: {
                                AnalyticsManager.shared.log(
                                    Navigate(fromScreen: .cryptoDetail, toScreen: .widgets, coinName: viewModel.cryptoInfo?.name)
                                )
                                navigationViewModel.deepLink(to: .Widgets)
                            }
                        )
                    }
                } else {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .cryptoDetail, sheet: .editWidgets)
                    )
                    isEditWidgetShowing = true
                }
            }, label: {
                HStack(spacing: 8) {
                    (containsCurrency ? Image.edit : Image.add)
                    Text(containsCurrency ? "Manage Widgets" : "Add to widgets")
                }
                .foregroundStyle(Color.onSurface)
            })

            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .cryptoDetail, sheet: .coinSearch)
                )
                isSelectingMainCoin = false
                showCompareCoinSelector = true
            }, label: {
                HStack(spacing: 8) {
                    Image.converter
                    Text("Compare")
                }
                .foregroundStyle(Color.onSurface)
            })
            
            Button(action: {
                Task {
                    let alerts = await viewModel.getAllpriceAlertsCount()
                    let success = await viewModel.checkIfUserEnabledPush()
                    let hasBoughtPro = await viewModel.hasBoughtPro()
                    
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
            }, label: {
                HStack(spacing: 8) {
                    Image.alert
                    Text("Add Alert")
                }
                .foregroundStyle(Color.onSurface)
                .accessibilityLabel("Add new \(viewModel.cryptoInfo?.name ?? "") price alert")
            })
            
            Button(action: {
                viewModel.shareDetails()
            }, label: {
                HStack(spacing: 8) {
                    Image.share
                    Text("Share")
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
        .accessibilityLabel("More options")
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
                hoverTimeWidthSize: $viewModel.hoverTimeWidthSize)
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging && !viewModel.candleChartEnabled ? 1 : 0
            )
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: .onSurface,
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hoverTimeWidthSize
            )
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging && !viewModel.candleChartEnabled ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        }
    }
    
    @ViewBuilder
    private func mainGraph(
        halfBiggestChartValueHeight: CGFloat,
    ) -> some View {
        NewChartView(
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
    
    private func closeAllOverlays() {
        isEditWidgetShowing = false
    }
}
