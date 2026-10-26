//
//  NFTDetailScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-08.
//

import SwiftUI

@MainActor
struct NFTDetailScreen: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.sizeCategory) private var category
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @State var viewModel: NFTDetailViewModelImp
    @State private var appLanguage = AppLanguagePreference.stored
    
    @State var currentPage: Int? = 0
    
    @State private var scrollOffset: CGFloat = 0
    @State private var chartID = UUID()
    @State private var hasUpdatedChartID = false
    @State private var hoverPriceWidthSize: CGFloat = 0
    @State private var hoverComparePriceWidthSize: CGFloat = 0
    @State private var hoverTimeWidthSize: CGFloat = 0
    @State private var showTwoRows = false
    @State private var isGraphLinear: Bool = SettingsManager.shared.get(key: AppSettingKey.isGraphLinear) ?? true
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var isSelectingCurrency = false
    
    @State private var biggestChartValue: CGSize = .zero
    
    @State private var showScrollToTopButton = false
    @State private var previousScrollOffset: CGFloat = 0
    
    @State private var isSortShowing = false
    @State private var scrollToTop = false
    @State private var id = UUID()
    
    private let listSubject = "NFT collection"
    private let fixedSelectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

    
    var binding: Binding<String?> {
        Binding(
            get: { navigationViewModel.webUrl },
            set: { navigationViewModel.webUrl = $0 }
        )
    }
    
    init(nftToplist: NFTToplist) {
        _viewModel = State(wrappedValue: NFTDetailViewModelImp(nftToplist: nftToplist))
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            CryptoDetailSummaryView(
                                name: viewModel.nftDetailInfo.name,
                                currentPrice: viewModel.onlyPrices.last,
                                imageUrl: viewModel.nftDetailInfo.image?.small,
                                prices: viewModel.onlyPrices,
                                isSharing: false,
                                image: nil,
                                selectedTimeframe: viewModel.selectedTimeFrame,
                                shortPrice: false,
                                shortChange: false,
                                currency: viewModel.selectedCurrency,
                                changeCoin: { }
                            )
                            .padding(.horizontal, 16)
                            
                            ChartTypeButtonsView(
                                fromScreen: .nftDetail,
                                selectedGraphType: viewModel.currentChartType,
                                isCandleChartEnabled: !viewModel.isChartFiat,
                                inCompareScreen: false,
                                isAlwaysSelectable: true,
                                imageCase: viewModel.isChartFiat ? .image(viewModel.currentCurrency?.image?.small) :  .text(fixedSelectedCurrency.symbol),
                                chartTypeAction: { type in
                                    viewModel.setChartType(type: type)
                                }, toggleCandleChart: {
                                    Task {
                                        await viewModel.toggleCurrencyType()
                                    }
                                }
                            )
                            
                            hoverTexts
                            
                            ZStack {
                                ChartBackground(
                                    biggestValue: $biggestChartValue,
                                    values: viewModel.mainGraphStats
                                )
                                
                                if viewModel.mainReloading {
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
                                currency: viewModel.selectedCurrency,
                                trailingPadding: biggestChartValue.width,
                                chartTitle: "Floor Price",
                                yAxisTitle: "Floor Price"
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
                                fromScreen: .nftDetail,
                                chartButtons: ChartButton.getButtons(from: .anHour, to: .aYear),
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
                            .padding(.bottom, 8)
                            
                            Section(header: pageSelector) {
                                if currentPage == 0 {
                                    NFTDetailOverviewView(
                                        nftDetailModel: viewModel.nftDetailInfo,
                                        currentCurrency: viewModel.currentCurrency,
                                        prices: viewModel.onlyPrices,
                                        timeChart: viewModel.selectedTimeFrame,
                                        fromScreen: .nftDetail,
                                        chartCurrency: viewModel.selectedCurrency,
                                        isFiatSelected: viewModel.isChartFiat,
                                        multiplier: viewModel.multiplier,
                                        isSelectingCurrency: $isSelectingCurrency,
                                        selectedCurrency: $selectedCurrency
                                    )
                                } else if currentPage == 1 {
                                    NFTDetailAboutView(
                                        nftDetail: viewModel.nftDetailInfo,
                                        webUrl: binding
                                    )
                                } else if currentPage == 2 {
                                    CryptoDetailExchangesView(
                                        items: viewModel.exchangeMarketItems,
                                        headerLabel: "Market",
                                        showVolumeOverride: false,
                                        useExchangeStyle: true,
                                        fromScreen: .nftDetail,
                                        selectedSortOption: viewModel.selectedSortOption,
                                        errorMessage: listSubject,
                                        isSortShowing: $isSortShowing
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
                                            fromScreen: .nftDetail,
                                            selectedTabName: currentPage.nftDetailPageTabName
                                        )
                                    )
                                    scrollToTop.toggle()
                                },
                                isVisible: showScrollToTopButton && currentPage == 2
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
        .navigationBarTitle(viewModel.nftDetailInfo.name ?? "", displayMode: .inline)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbar {
            toolbarMenuButton
        }
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
            await viewModel.refresh(
                getTickers: currentPage == 2
            )
        }
        .task(id: currentPage) {
            if currentPage == 2 {
               await viewModel.getTickers()
            }
        }
        .onChange(of: currentPage) { _, page in
            AnalyticsManager.shared.log(
                TabChanged(fromScreen: .nftDetail, selectedTabName: page.nftDetailPageTabName)
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.nftDetailOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .nftDetail, option: option)
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
                        CurrencySelected(fromScreen: .nftDetail, currency: $0.currency)
                    )
                    selectedCurrency = $0
                }
            )
        }
    }
    
    private var toolbarMenuButton: some View {
        Menu {
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
        let categories = ["Overview", "About", "Markets"]
        
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
