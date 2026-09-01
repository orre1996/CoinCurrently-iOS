//
//  GasFeesScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/24/25.
//

import SwiftUI

struct GasFeesScreen: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel = GasFeesViewModelImp()
    
    @State private var showInfoSheet = false
    @State private var showCostInfoSheet = false
    
    @State private var fearMeterWidth: CGFloat = 1
    @State private var currentValueXOffset: CGFloat = 0
    @State private var biggestChartValue: CGSize = .zero
    
    @ScaledMetric private var scale: CGFloat = 1
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        currentView(geometryProxy: reader)
                        
                        gasFeeMeter
                        
                        hoverTexts
                            .accessibilityHidden(true)
                        
                        ZStack {
                            ChartBackground(
                                biggestValue: $biggestChartValue,
                                values: viewModel.graphStats
                            )
                            
                            if viewModel.gasFeePrices == nil {
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
                                    dropCount: 2
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
                        .frame(height: max(1, reader.size.height * 0.35))
                        .chartAccessibilityOverlay(
                            timeStamps: viewModel.timeStamps,
                            prices: viewModel.prices,
                            timeChart: .aWeek,
                            priceFormatter: { "\($0.numberAccessible(maxPlaces: 2)) Gwei" },
                            trailingPadding: biggestChartValue.width
                        )
                        .padding(.horizontal, 16)
                        
                        ChartTimeStamps(
                            currentTimeChart: .aWeek, // viewModel.timeChart,
                            timeStamps: viewModel.timeStamps
                        )
                        .accessibilityHidden(true)
                        .padding(
                            EdgeInsets(
                                top:  -biggestChartValue.height / 2,
                                leading: 16,
                                bottom: 8 + biggestChartValue.height / 2,
                                trailing: 16 + biggestChartValue.width
                            )
                        )
                        
                        historyDataView
                            .padding(.top, 16)
                        
                        estimateCostsView
                            .padding(.vertical, 32)
                    }
                    .padding(.top, 16)
                }
                .scrollDisabled(viewModel.isDragging)
                .refreshable {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getGasFees() }
                        group.addTask { await viewModel.getGasFeePrices() }
                    }
                }
                
                EdgeSwipe(isDragging: viewModel.isDragging)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            AchievementManager.shared.increment(.gasFeesVisits)
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.setStartData() }
                group.addTask { await viewModel.getGasFees() }
                group.addTask { await viewModel.getGasFeePrices() }
                group.addTask { await viewModel.getEthereumPrice() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getGasFees() }
                        group.addTask { await viewModel.getGasFeePrices() }
                        group.addTask { await viewModel.getEthereumPrice() }
                    }
                }
            default:
                break
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbar {
            gasFeesToolbar
        }
        .sheet(isPresented: $showInfoSheet) {
            GasFeesHelpSheet()
        }
        .sheet(isPresented: $showCostInfoSheet) {
            GasCostHelpSheet()
        }
    }
    
    @ToolbarContentBuilder
    private var gasFeesToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("ETH Gas Fee")
                .accessibilityLabel("Ethereum gas fee")
                .accessibilityAddTraits(.isHeader)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .gasFees, sheet: .gasFeesHelp)
                )
                showInfoSheet = true
            }, label: {
                Image.info
            })
            .accessibilityLabel("Help understand how ethereum gas fees work")
        }
    }
    
    private func currentView(geometryProxy: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<viewModel.currentTimeFrames.count, id: \.self) { index in
                    let currentValue = viewModel.currentTimeFrames[index].0
                    let currentTimeframe = viewModel.currentTimeFrames[index].1
                    let currentValueAccessible = viewModel.getCurrentTextAccessible(at: index, value: currentValue ?? "0")
                    let currentStatus = getGasIndexString(indexValue: currentValue ?? "0")
                    
                    GasFeesHistoricView(
                        timeframe: currentTimeframe,
                        indexValue: currentValue,
                        status: currentStatus
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(currentValueAccessible). \(currentStatus)")
                }
            }
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 12,
                    trailing: 16,
                )
            )
            .frame(minWidth: geometryProxy.size.width)
        }
    }
    
    @ViewBuilder
    private var gasFeeMeter: some View {
        let value = viewModel.gasFees?.gasFeeData?.first?.proposeGasPrice
        let percent: CGFloat = CGFloat((Double(value ?? "0") ?? 0) / 100)
        let circleSize: CGFloat = 32
        
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                FearGreedMeter(height: 24)
                    .frame(height: circleSize)
                    .readSize {
                        fearMeterWidth = $0.width
                    }
                    .padding(.horizontal, 16)
                    .rotationEffect(Angle(degrees: 180))
                
                Circle()
                    .foregroundStyle(Color.surfaceContainerHighest)
                    .frame(width: circleSize, height: circleSize)
                    .padding(2)
                    .background(
                        Circle()
                            .foregroundStyle(Color.outline)
                    )
                    .offset(x: currentValueXOffset)
            }
            
            gasFeeMeterHeader
        }
        .padding(.vertical, 16)
        .accessibilityHidden(true)
        .onChange(of: percent) {
            withAnimation {
                let normalizedValue = viewModel.normalizedPosition(for: Double(value ?? "0") ?? 0)
                currentValueXOffset = (fearMeterWidth * normalizedValue) - (4 * normalizedValue)
            }
        }
    }
    
    @ViewBuilder
    private var hoverTexts: some View {
        if viewModel.hoverHelper.hoverPrices.count == 2 {
            NewMultiHoverTextView(hoverTimes: viewModel.hoverHelper.hoverTimes,
                                  differenceValue: viewModel.differenceValue,
                                  differencePercent: viewModel.differencePercent,
                                  color: viewModel.graphColor,
                                  xPosition: viewModel.hoverTimePosition,
                                  hoverTimeWidthSize: $viewModel.hoverTimeWidthSize)
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: getGasIndexColor(indexValue: viewModel.hoverPrice),
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hoverTimeWidthSize
            )
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        }
    }
    
    private var gasFeeMeterHeader: some View {
        HStack {
            Text("Low")
            
            Spacer()
            
            Text("High")
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDimmer)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var historyDataView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Data")
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityAddTraits(.isHeader)
            
            GasHistoricalDataView(
                prices: viewModel.allPrices
            )
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var estimateCostsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Text("Estimated Cost")
                    .font(.satoshiBold(22))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer(minLength: 16)
                
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .gasFees, sheet: .gasFeesCost)
                    )
                    showCostInfoSheet = true
                }, label: {
                    Image.info
                        .resizable()
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .padding(8)
                })
                .accessibilityLabel("Estimated Cost info")
            }
            
            EstimateGasFeeCost(
                swapCost: viewModel.getGasPrice(for: .swap, accessible: false),
                accessibleSwapCost: viewModel.getGasPrice(for: .swap, accessible: true),
                nftCost: viewModel.getGasPrice(for: .nft, accessible: false),
                accessibleNftCost: viewModel.getGasPrice(for: .nft, accessible: true),
                bridgingCost: viewModel.getGasPrice(for: .bridging, accessible: false),
                accessibleBridgingCost: viewModel.getGasPrice(for: .swap, accessible: true),
                borrowingCost: viewModel.getGasPrice(for: .borrowing, accessible: false),
                accessibleBorrowingCost: viewModel.getGasPrice(for: .borrowing, accessible: true)
            )
        }
        .padding(.horizontal, 16)
    }
}
