//
//  GlobalMarketScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-01-10.
//

import SwiftUI

@MainActor
struct GlobalMarketScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var viewModel = GlobalMarketViewModelImp()
    @State private var biggestChartValue: CGSize = .zero
    
    private var isHorizontal: Bool {
        return !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            GlobalMarketSummaryView(
                                marketCap: viewModel.latestChartMarketCap,
                                changePercent: viewModel.changePercent,
                                selectedTimeframe: viewModel.selectedTimeFrame
                            )
                            .padding(
                                EdgeInsets(
                                    top: 16,
                                    leading: 16,
                                    bottom: 0,
                                    trailing: 16
                                )
                            )
                            
                            ChartButtonsView(
                                fromScreen: .globalMarket,
                                selectedGraphType: viewModel.selectedChartType,
                                isCandleChartEnabled: false,
                                inCompareScreen: false,
                                imageCase: .nothing,
                                chartTypeAction: { type in
                                    viewModel.setChartType(type: type)
                                },
                                toggleCandleChart: { }
                            )
                            
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
                                    trailingPadding: biggestChartValue.width
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
                                
                                ChartButtonsViewNew(
                                    fromScreen: .globalMarket,
                                    chartButtons: ChartButton.getButtons(from: .aDay, to: .max),
                                    selectedNumber: viewModel.selectedTimeFrame.rawValue,
                                    reader: reader,
                                    action: { button in
                                        if !viewModel.isDragging {
                                            await viewModel.refresh(newDays: button.days, newTimeChart: button.timeChart)
                                        }
                                    }
                                )
                                .padding(.bottom, 32)
                            }
                            
                            if let percentages = viewModel.globalMarket?.data?.percentages {
                                marketShareMeter(
                                    percentages: percentages,
                                    screenWidth: reader.size.width
                                )
                                .padding(.horizontal, 16)
                            } else {
                                tempMarketShareMeter(screenWidth: reader.size.width)
                                    .padding(.horizontal, 16)
                            }
                            
                            if let percentages = viewModel.globalMarket?.data?.percentages {
                                realCoins(percentages: percentages)
                                    .padding(
                                        EdgeInsets(
                                            top: 12,
                                            leading: 16,
                                            bottom: 16,
                                            trailing: 16
                                        )
                                    )
                            } else {
                                tempCoins
                                    .padding(
                                        EdgeInsets(
                                            top: 12,
                                            leading: 16,
                                            bottom: 16,
                                            trailing: 16
                                        )
                                    )
                            }
                            
                            HStack(alignment: .top, spacing: 0) {
                                activeCurrenciesView
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                amountOfMarketsView
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .cardBackground()
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 32)
                    }
                    .scrollDisabled(viewModel.isDragging)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            
            EdgeSwipe(isDragging: viewModel.isDragging)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitle("Market Cap", displayMode: .inline)
        .navigationPopGestureDisabled(viewModel.isDragging)
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getGlobalMarket() }
                group.addTask { await viewModel.refresh(newDays: nil, newTimeChart: nil) }
            }
            await viewModel.getColors()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getGlobalMarket() }
                        group.addTask { await viewModel.refresh(newDays: nil, newTimeChart: nil) }
                    }
                    await viewModel.getColors()
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getGlobalMarket() }
                group.addTask { await viewModel.refresh(newDays: nil, newTimeChart: nil) }
            }
            await viewModel.getColors()
        }
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
                hoverTimeWidthSize: $viewModel.hoverTimeWidthSize
            )
            .opacity(!viewModel.showMainPriceError && viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: .onSurface,
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hoverTimeWidthSize
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
        NewChartView(
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
    
    private func marketShareMeter(percentages: [Percentages], screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(percentages, id: \.self) { coin in
                let width = max(1, coin.percentage * (screenWidth - 32))
                let currentColor: Color = {
                    if coin.symbol.uppercased() == "OTHER" {
                        return Color.primary20
                    }
                    if let hex = coin.color {
                        return Color(hex: hex)
                    }
                    return Color.surfaceContainerLow
                }()
                
                currentColor
                    .frame(width: width)
            }
        }
        .frame(height: 136)
        .cornerRadius(8)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func tempMarketShareMeter(screenWidth: CGFloat) -> some View {
        ZStack {
            Color.shimmeringBackground
                .opacity(0.15)
            
            Color.onSurface
                .opacity(0.25)
                .shimmer()
        }
        .frame(maxWidth: max(1, screenWidth - 32), minHeight: 136, maxHeight: 136)
        .cornerRadius(8)
    }
    
    private var tempCoins: some View {
        OverflowLayout(spacing: 4) {
            ForEach(0..<6, id: \.self) { index in
                MarketShareView(
                    coin: nil,
                    color: Color.onSurfaceDim,
                    listIndex: index,
                    listCount: 6
                )
            }
        }
    }
    
    private func realCoins(percentages: [Percentages]) -> some View {
        OverflowLayout(spacing: 4) {
            ForEach(percentages, id: \.self) { coin in
                let index = percentages.firstIndex(of: coin) ?? -1
                let currentColor: Color = {
                    if coin.symbol.uppercased() == "OTHER" {
                        return Color.primary20
                    }
                    if let hex = coin.color {
                        return Color(hex: hex)
                    }
                    return Color.surfaceContainerLow
                }()
                
                MarketShareView(
                    coin: coin,
                    color: currentColor,
                    listIndex: index,
                    listCount: percentages.count
                )
            }
        }
    }
    
    @ViewBuilder
    private var marketCapView: some View {
        let totalMarketCap = viewModel.latestChartMarketCap
        let formattedTotalMarketCap = totalMarketCap?.formatCurrency(threshold: FormattingThreshold.none)
        
        infoView(
            title: "Market cap",
            value: formattedTotalMarketCap,
            valueAccessible: totalMarketCap?.formatCurrency(accessible: true)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var marketCapChangeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("24h Change")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            NewPriceChangePercentView(
                change: viewModel.globalMarket?.data?.market_cap_change_percentage_24h_usd,
                accessibleTimeframe: "24 hour",
                isDownloading: viewModel.globalMarket?.data == nil
            )
        }
        .frame(minWidth: 112, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var dailyVolumeView: some View {
        let totalVolume = viewModel.latestChartVolume
        let formattedVolume = totalVolume?.formatCurrency(threshold: FormattingThreshold.none)
        
        infoView(
            title: "24h Volume",
            titleAccessible: "24 hour volume",
            value: formattedVolume,
            valueAccessible: totalVolume?.formatCurrency(accessible: true)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var activeCurrenciesView: some View {
        infoView(
            title: "Active Currencies",
            value: viewModel.globalMarket?.data?.active_cryptocurrencies.description
        )
    }
    
    @ViewBuilder
    private var amountOfMarketsView: some View {
        infoView(
            title: "Markets",
            value: viewModel.globalMarket?.data?.markets.description
        )
        .frame(minWidth: 112, alignment: .leading)
    }
    
    @ViewBuilder
    private func infoView(
        title: String,
        titleAccessible: String? = nil,
        value: String?,
        valueAccessible: String? = nil
    ) -> some View {
        let accessibleTitle = titleAccessible ?? title
        
        let content = VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
                .accessibilityLabel(accessibleTitle)
                .accessibilityHidden(valueAccessible != nil)
            
            NewShimmeringText(
                text: value ?? "000000000000",
                isDownloading: value == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            .accessibilityHidden(valueAccessible != nil)
        }
        
        if let valueAccessible {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(accessibleTitle): \(valueAccessible)")
        } else {
            content
                .accessibilityElement(children: .combine)
        }
    }
}
