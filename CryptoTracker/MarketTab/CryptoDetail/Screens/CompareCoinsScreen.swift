//
//  CompareCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/20/25.
//

import SwiftUI

struct CompareCoinsScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var viewModel: CompareCoinsViewModelImp

    @State private var biggestChartValue: CGSize = .zero

    @State private var compareWrapper: CompareWrapper?
    
    @State private var showCommunitySentimentHelp = false
    
    init(
        cryptoInfo: CurrencyDataModel?,
        priceVolumeModel: PriceVolumeModel?,
        compareId: String
    ) {
        _viewModel = State(
            wrappedValue: CompareCoinsViewModelImp(
                cryptoInfo: cryptoInfo,
                priceVolumeModel: priceVolumeModel,
                compareId: compareId
            )
        )
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollViewReader { scrollViewReader  in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
                            
                            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                                CryptoDetailSummaryView(
                                    name: viewModel.cryptoInfo?.name,
                                    currentPrice: viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency(),
                                    imageUrl: viewModel.cryptoInfo?.image?.small,
                                    prices: viewModel.onlyPrices,
                                    isSharing: false,
                                    image: nil,
                                    selectedTimeframe: viewModel.selectedTimeFrame,
                                    shortPrice: true,
                                    shortChange: true,
                                    changeCoinAccessibilityHint: "Double tap to change the coin",
                                    isWebSocketEnabled: viewModel.isWebSocketEnabled,
                                    changeCoin: {
                                        if viewModel.cryptoInfo?.id != nil {
                                            AnalyticsManager.shared.log(
                                                ChangeCompareCoin(
                                                    fromScreen: .compareCoins,
                                                    selection: .main,
                                                    coinName: viewModel.cryptoInfo?.name ?? ""
                                                )
                                            )
                                            AnalyticsManager.shared.log(
                                                SheetOpened(fromScreen: .compareCoins, sheet: .coinSearch)
                                            )
                                            compareWrapper = CompareWrapper(isSelectingMainCoin: true)
                                        }
                                    }
                                )
                                
                                CryptoDetailSummaryView(
                                    name: viewModel.comparedCryptoInfo?.name,
                                    currentPrice: viewModel.comparedCryptoInfo?.market_data?.current_price?.getConvertedCurrency(),
                                    imageUrl: viewModel.comparedCryptoInfo?.image?.small,
                                    prices: viewModel.onlyComparePrices,
                                    isSharing: false,
                                    image: nil,
                                    selectedTimeframe: viewModel.selectedTimeFrame,
                                    shortPrice: true,
                                    shortChange: true,
                                    changeCoinAccessibilityHint: "Double tap to change the coin",
                                    isWebSocketEnabled: viewModel.isWebSocketEnabled,
                                    changeCoin: {
                                        if viewModel.comparedCryptoInfo?.id != nil {
                                            AnalyticsManager.shared.log(
                                                ChangeCompareCoin(
                                                    fromScreen: .compareCoins,
                                                    selection: .compare,
                                                    coinName: viewModel.comparedCryptoInfo?.name ?? ""
                                                )
                                            )
                                            AnalyticsManager.shared.log(
                                                SheetOpened(fromScreen: .compareCoins, sheet: .coinSearch)
                                            )
                                            compareWrapper = CompareWrapper(isSelectingMainCoin: false)
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal, 16)
                            
                            ChartButtonsView(
                                fromScreen: .compareCoins,
                                selectedGraphType: viewModel.currentChartType,
                                isCandleChartEnabled: false,
                                inCompareScreen: true,
                                imageCase: .fixed(.candlestick),
                                chartTypeAction: { type in
                                    viewModel.setChartType(type: type)
                                }, toggleCandleChart: { }
                            )
                            
                            ZStack {
                                hoverTexts
                            }
                            .accessibilityHidden(!viewModel.isDragging || viewModel.showMainPriceError)
                            
                            ZStack {
                                ChartBackground(
                                    biggestValue: $biggestChartValue,
                                    values: viewModel.graphStats
                                )
                                
                                if viewModel.mainReloading {
                                    ActivityIndicator()
                                        .padding(.trailing, biggestChartValue.width)
                                        .accessibilityHidden(true)
                                } else {
                                    mainGraph(
                                        halfBiggestChartValueHeight: halfBiggestChartValueHeight
                                    )
                                    .opacity(viewModel.showMainPriceError ? 0 : 1)
                                    .frame(height: max(1, reader.size.height * 0.35))
                                    
                                    compareGraph(
                                        halfBiggestChartValueHeight: halfBiggestChartValueHeight
                                    )
                                    .opacity(viewModel.showComparePriceError ? 0 : 1)
                                    .frame(height: max(1, reader.size.height * 0.35))
                                    
                                    CompareChartHoverView(
                                        mainDragPosition: viewModel.dragPositions,
                                        hideMainMark: (viewModel.getPrices(dropLastTwo: true)[safely: viewModel.dragIndex] ?? -1) == -1,
                                        compareDragPosition: viewModel.compareDragPositions,
                                        hideCompareMark: (viewModel.getComparePrices(dropLastTwo: true)[safely: viewModel.dragIndex] ?? -1) == -1,
                                        size: viewModel.chartSize,
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
                            .frame(height: max(1, reader.size.height * 0.35))
                            .chartAccessibilityOverlay(
                                timeStamps: viewModel.getTimestamps(),
                                prices: viewModel.getPrices(),
                                timeChart: viewModel.selectedTimeFrame,
                                comparePrices: viewModel.getComparePrices(),
                                mainSeriesName: viewModel.cryptoInfo?.name,
                                compareSeriesName: viewModel.comparedCryptoInfo?.name,
                                showPercentChangeFromStart: true,
                                trailingPadding: biggestChartValue.width
                            )
                            .padding(.horizontal, 16)
                            
                            ChartTimeStamps(
                                currentTimeChart: viewModel.selectedTimeFrame,
                                timeStamps: viewModel.getTimestamps(),
                                accessibilityTexts: viewModel.chartValues
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
                                fromScreen: .compareCoins,
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
                            
                            coinSymbolsView
                                .padding(.bottom, 32)
                            
                            Separator()
                                .padding(.bottom, 32)
                            
                            CompareStatisticsView(
                                mainCryptoInfo: viewModel.cryptoInfo,
                                compareCryptoInfo: viewModel.comparedCryptoInfo,
                                mainPrices: viewModel.getPrices(dropLastTwo: true).filter { $0 != -1 },
                                comparePrices: viewModel.getComparePrices(dropLastTwo: true).filter { $0 != -1 },
                                selectedTimeframe: viewModel.selectedTimeFrame
                            )
                            .padding(.bottom, 32)
                            .accessibilitySortPriority(-2)
                            
                            CompareHistoricDataView(
                                mainCryptoInfo: viewModel.cryptoInfo,
                                compareCryptoInfo: viewModel.comparedCryptoInfo
                            )
                            .padding(.bottom, 32)
                            .accessibilitySortPriority(-2)
                            
                            CompareSentimentView(
                                mainCryptoInfo: viewModel.cryptoInfo,
                                compareCryptoInfo: viewModel.comparedCryptoInfo,
                                fromScreen: .compareCoins,
                                showCommunitySentimentHelp: $showCommunitySentimentHelp
                            )
                            .accessibilitySortPriority(-2)
                        }
                        .padding(
                            EdgeInsets(
                                top: 16,
                                leading: 0,
                                bottom: 32,
                                trailing: 0
                            )
                        )
                    }
                    .scrollDisabled(viewModel.isDragging)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            EdgeSwipe(isDragging: viewModel.isDragging)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .navigationBarTitle("Compare", displayMode: .inline)
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbar {
            Button(action: {
                AnalyticsManager.shared.log(
                    ChangeCompareCoin(
                        fromScreen: .compareCoins,
                        selection: .compare,
                        coinName: viewModel.comparedCryptoInfo?.name ?? ""
                    )
                )
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .compareCoins, sheet: .coinSearch)
                )
                compareWrapper = CompareWrapper(isSelectingMainCoin: false)
            }, label: {
                Image.changeCoin
                    .resizable()
                    .frame(width: 24 * min(scale, 1.25), height: 24 * min(scale, 1.25), alignment: .center)
                    .foregroundStyle(Color.onSurface)
            })
            .accessibilityLabel("Change compare coin")
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            AchievementManager.shared.increment(.compareSessions)
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.refresh() }
                group.addTask { await viewModel.getToplist() }
            }
            // Yield so coin detail's onDisappear can disconnect before we reconnect.
            await Task.yield()
            await viewModel.syncLivePriceUpdates()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.refresh() }
                        group.addTask { await viewModel.getToplist() }
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
        .onDisappear {
            Task {
                await viewModel.stopLivePriceUpdates()
            }
        }
        .sheet(item: $compareWrapper) { wrapper in
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .compareCoins,
                highlightId: wrapper.isSelectingMainCoin ? viewModel.cryptoInfo?.id : viewModel.comparedCryptoInfo?.id,
                hideId: wrapper.isSelectingMainCoin ? viewModel.comparedCryptoInfo?.id : viewModel.cryptoInfo?.id,
                close: { id, _, _ in
                    compareWrapper = nil
                    
                    guard let id else {
                        return
                    }
                    
                    Task {
                        await viewModel.refresh(
                            forceMainId: wrapper.isSelectingMainCoin ? id : nil,
                            forceCompareId: wrapper.isSelectingMainCoin ? nil : id
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showCommunitySentimentHelp) {
            CommunitySentimentHelpSheet()
        }
    }
    
    @ViewBuilder
    private var hoverTexts: some View {
        CompareHoverStats(
            mainHoverPrice: viewModel.hoverPrice,
            mainSymbol: viewModel.cryptoInfo?.symbol,
            mainPercentChange: viewModel.mainDifferencePercent,
            compareHoverPrice: viewModel.compareHoverPrice,
            compareSymbol: viewModel.comparedCryptoInfo?.symbol,
            comparePercentChange: viewModel.compareDifferencePercent,
            hoverTime: viewModel.hoverTime,
            accessibleTimeframe: viewModel.selectedTimeFrame.accessibilityTimeframe,
            xPositionTime: viewModel.hoverTimePosition,
            hoverTimeWidthSize: $viewModel.hoverTimeWidthSize
        )
        .opacity(!viewModel.showMainPriceError && viewModel.isDragging ? 1 : 0)
        .animation(.default, value: viewModel.isDragging)
    }
    
    @ViewBuilder
    private func mainGraph(halfBiggestChartValueHeight: CGFloat) -> some View {
        NewChartView(
            prices: viewModel.getPrices(),
            color: Color.primary50,
            isGraphFilled: false,
            lineWidth: 2,
            dragPositions: [],
            size: viewModel.chartSize,
            isDragging: viewModel.isDragging,
            dropCount: 2,
            showLivePriceIndicator: viewModel.isWebSocketEnabled && viewModel.currentChartType == .price
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
    }
    
    @ViewBuilder
    private func compareGraph(halfBiggestChartValueHeight: CGFloat) -> some View {
        NewChartView(
            prices: viewModel.getComparePrices(),
            color: Color.blue50,
            isGraphFilled: false,
            lineWidth: 2,
            dragPositions: [],
            size: viewModel.chartSize,
            isDragging: viewModel.isDragging,
            dropCount: 2,
            showLivePriceIndicator: viewModel.isWebSocketEnabled && viewModel.currentChartType == .price
        )
        .padding(
            EdgeInsets(
                top: halfBiggestChartValueHeight,
                leading: 0,
                bottom: halfBiggestChartValueHeight,
                trailing: biggestChartValue.width
            )
        )
    }
    
    private var coinSymbolsView: some View {
        HStack(spacing: 8) {
            CompareRectangleView(
                color: Color.primary50
            )
            
            NewShimmeringText(
                text: viewModel.cryptoInfo?.symbol?.uppercased() ?? "0000",
                isDownloading: viewModel.cryptoInfo == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(16))
            .padding(.trailing, 24)
            
            CompareRectangleView(
                color: Color.blue50
            )
    
            NewShimmeringText(
                text: viewModel.comparedCryptoInfo?.symbol?.uppercased() ?? "0000",
                isDownloading: viewModel.comparedCryptoInfo == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
        .accessibilityHidden(true)
    }
}
