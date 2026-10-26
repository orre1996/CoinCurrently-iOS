//
//  ExchangeDetailSCreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-26.
//

import SwiftUI

struct ExchangeDetailScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State var viewModel: ExchangeDetailViewModelImp
    @State private var appLanguage = AppLanguagePreference.stored
    
    @State private var currentPage: Int? = 0
    
    @State private var biggestChartValue: CGSize = .zero
    
    private let listSubject = "exchange"
    
    @State private var showScrollToTopButton = false
    @State private var previousScrollOffset: CGFloat = 0
    
    @State private var isSortShowing = false
    @State private var scrollToTop = false
    @State private var id = UUID()
    
    var binding: Binding<String?> {
        Binding(
            get: { navigationViewModel.webUrl },
            set: { navigationViewModel.webUrl = $0 }
        )
    }
    
    init(exchangeModel: Exchange) {
        _viewModel = State(wrappedValue: ExchangeDetailViewModelImp(exchangeDetail: exchangeModel))
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            CryptoDetailSummaryView(
                                name: viewModel.exchangeInfo.name,
                                currentPrice: (viewModel.exchangeInfo.trade_volume_24h_btc ?? 0) * (viewModel.bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0),
                                imageUrl: viewModel.exchangeInfo.image,
                                prices: viewModel.prices,
                                isSharing: false,
                                image: nil,
                                selectedTimeframe: viewModel.selectedTimeFrame,
                                shortPrice: false,
                                shortChange: true,
                                valueAccessibilityLabel: "24 hour volume",
                                changeMetricLabel: "volume",
                                changeCoin: { }
                            )
                            .padding(
                                EdgeInsets(
                                    top: 0,
                                    leading: 16,
                                    bottom: 24,
                                    trailing: 16
                                )
                            )
                            
                            ExchangeDetailSummaryView(
                                exchangeDetail: viewModel.exchangeInfo,
                            )
                            .padding([.horizontal, .bottom], 16)
                            
                            VStack(spacing: 0) {
                                hoverTexts
                                
                                ZStack {
                                    ChartBackground(
                                        biggestValue: $biggestChartValue,
                                        values: viewModel.mainGraphStats
                                    )
                                    
                                    if viewModel.reloading {
                                        ActivityIndicator()
                                            .padding(.trailing, biggestChartValue.width)
                                            .accessibilityHidden(true)
                                    } else {
                                        mainGraph(
                                            halfBiggestChartValueHeight: halfBiggestChartValueHeight,
                                            geometryReader: reader
                                        )
                                        .opacity(viewModel.showMainPriceError ? 0 : 1)
                                        .frame(height: max(1, reader.size.height * 0.35))
                                        
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
                                    timeStamps: viewModel.getTimestamps(),
                                    prices: viewModel.getPrices(),
                                    timeChart: viewModel.selectedTimeFrame,
                                    trailingPadding: biggestChartValue.width,
                                    chartTitle: "24h Volume",
                                    yAxisTitle: "24h Volume"
                                )
                                .padding(.horizontal, 16)
                                
                                ChartTimeStamps(
                                    currentTimeChart: viewModel.selectedTimeFrame,
                                    timeStamps: viewModel.getTimestamps()
                                )
                                .accessibilityHidden(true)
                                .padding(
                                    EdgeInsets(
                                        top:  -biggestChartValue.height / 2,
                                        leading: 16,
                                        bottom: biggestChartValue.height / 2,
                                        trailing: 16 + biggestChartValue.width
                                    )
                                )
                                
                                ChartTimeframeButtonsView(
                                    fromScreen: .exchangeDetail,
                                    chartButtons: ChartButton.getButtons(from: .aDay, to: .aYear),
                                    selectedNumber: viewModel.selectedTimeFrame.rawValue,
                                    reader: reader,
                                    action: { button in
                                        if !viewModel.isDragging {
                                            await viewModel.refresh(newDays: button.days, newTimeChart: button.timeChart)
                                        }
                                    }
                                )
                                .padding(.bottom, 16)
                            }
                            
                            Section(header: pageSelector) {
                                if currentPage == 0 {
                                    CryptoDetailExchangesView(
                                        items: viewModel.exchangeMarketItems,
                                        headerLabel: "Pair",
                                        showVolumeOverride: true,
                                        useExchangeStyle: true,
                                        fromScreen: .exchangeDetail,
                                        selectedSortOption: viewModel.selectedSortOption,
                                        errorMessage: listSubject,
                                        isSortShowing: $isSortShowing
                                    )
                                } else if currentPage == 1 {
                                    ExchangeDetailAboutView(
                                        exchange: viewModel.exchangeInfo,
                                        webUrl: binding
                                    )
                                }
                            }
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
                                            fromScreen: .exchangeDetail,
                                            selectedTabName: currentPage.exchangeDetailPageTabName
                                        )
                                    )
                                    scrollToTop.toggle()
                                },
                                isVisible: showScrollToTopButton && currentPage == 0
                            )
                        }
                    }
                    .onChange(of: scrollToTop) {
                        withAnimation {
                            scrollViewReader.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }
            
            EdgeSwipe(isDragging: viewModel.isDragging)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitle(viewModel.exchangeInfo.name ?? "", displayMode: .inline)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .navigationPopGestureDisabled(viewModel.isDragging)
        .task {
            await viewModel.setStartData()
            await viewModel.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.refresh()
                }
            default:
                break
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onChange(of: currentPage) { _, page in
            AnalyticsManager.shared.log(
                TabChanged(fromScreen: .exchangeDetail, selectedTabName: page.exchangeDetailPageTabName)
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.exchangeDetailOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .exchangeDetail, option: option)
                    )
                    Task {
                        await viewModel.setNewSortOption(newSortOption: option)
                    }
                }
            )
        }
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
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: .onSurface,
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        }
    }
    
    @ViewBuilder
    private func mainGraph(
        halfBiggestChartValueHeight: CGFloat,
        geometryReader: GeometryProxy
    ) -> some View {
        PriceLineChartView(
            prices: viewModel.getPrices(),
            color: viewModel.graphColor,
            lineWidth: 2,
            dragPositions: viewModel.dragPositions,
            size: viewModel.chartSize,
            isDragging: viewModel.isDragging
        )
        .readSize {
            viewModel.chartSize = $0
        }
        .onChange(of: geometryReader.size) { _, newSize in
            viewModel.chartSize = CGSize(width: newSize.width, height: newSize.height * 0.35 - 16)
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
    private var pageSelector: some View {
        let categories = ["Markets", "About"]
        
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
}
