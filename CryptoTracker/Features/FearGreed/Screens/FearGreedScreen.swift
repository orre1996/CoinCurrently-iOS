//
//  FearGreedScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-21.
//

import SwiftUI

@MainActor
struct FearGreedScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @State private var viewModel = FearGreedViewModelImp()
    
    @State private var showInfoSheet = false
    @State private var fearMeterWidth: CGFloat = 1
    @State private var biggestChartValue: CGSize = .zero
    @State private var appLanguage = AppLanguagePreference.stored
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        historicalView(geometryProxy: reader)
                        
                        fearGreedMeter
                        
                        hoverTexts
                        
                        ZStack {
                            ChartBackground(
                                biggestValue: $biggestChartValue,
                                values: (0..<6).map({ "\($0 * 20)" })
                            )
                            
#if DEBUG
                            BannerLogoView()
                                .padding(.trailing, biggestChartValue.width)
#endif
                            
                            if viewModel.fearGreed == nil {
                                ActivityIndicator()
                                    .padding(.trailing, biggestChartValue.width)
                            } else {
                                PriceLineChartView(
                                    prices: viewModel.prices.normalized,
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
                            prices: Array(viewModel.prices.dropLast(2)),
                            timeChart: viewModel.timeChart,
                            dontShowTime: true,
                            priceFormatter: { $0.numberAccessible(maxPlaces: 0) },
                            trailingPadding: biggestChartValue.width
                        )
                        .padding(.horizontal, 16)
                        
                        ChartTimeStamps(
                            currentTimeChart: viewModel.timeChart,
                            timeStamps: viewModel.timeStamps
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
                            fromScreen: .fearGreed,
                            chartButtons: ChartButton.getButtons(from: .aWeek, to: .max),
                            selectedNumber: viewModel.timeChart.rawValue,
                            reader: reader,
                            action: { button in
                                if !viewModel.isDragging {
                                    viewModel.setTimeChart(button.timeChart)
                                }
                            }
                        )
                    }
                    .padding(.vertical, 16)
                }
                .scrollDisabled(viewModel.isDragging)
                .refreshable {
                    await viewModel.getFearGreed()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            EdgeSwipe(isDragging: viewModel.isDragging)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await viewModel.setStartData()
            await viewModel.getFearGreed()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.getFearGreed()
                }
            default:
                break
            }
        }
        .navigationBarTitle(Localization.string("Fear & Greed"), displayMode: .inline)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .navigationPopGestureDisabled(viewModel.isDragging)
        .toolbar {
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .fearGreed, sheet: .fearGreedHelp)
                )
                showInfoSheet = true
            }, label: {
                Image.info
            })
            .accessibilityLabel(Localization.string("Help understand the fear and greed index"))
        }
        .sheet(isPresented: $showInfoSheet) {
            FearGreedHelpSheet()
        }
    }
    
    @ViewBuilder
    private func historicalView(geometryProxy: GeometryProxy) -> some View {
        let isAccessibilityEnabled = category.isAccessibilityCategory
        
        AdaptiveScroll(
            isScrollable: isAccessibilityEnabled,
            direction: .horizontal,
            showsIndicator: false
        ) {
            HStack(spacing: 12) {
                let longestStatus = (0..<viewModel.historicTimeframes.count).map({
                    let currentStep = viewModel.historicTimeframes[$0].0
                    let currentValue = viewModel.fearGreed?.data?[safely: currentStep]?.value
                    
                    return getIndexString(indexValue: currentValue ?? "0")
                }).min() ?? ""
                
                ForEach(0..<viewModel.historicTimeframes.count, id: \.self) { index in
                    let currentStep = viewModel.historicTimeframes[index].0
                    let currentTimeframe = viewModel.historicTimeframes[index].1
                    let currentValue = viewModel.fearGreed?.data?[safely: currentStep]?.value
                    let currentValueAccessible = viewModel.getHistoricTextAccessible(at: index, value: currentValue ?? "0")
                    let currentStatus = getIndexString(indexValue: currentValue ?? "0")
                    
                    FearGreedHistoricView(
                        timeframe: currentTimeframe,
                        indexValue: currentValue,
                        longestStatus: longestStatus,
                        status: currentStatus
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Localization.format(
                        "%@. %@",
                        currentValueAccessible,
                        Localization.string(currentStatus)
                    ))
                }
            }
            .padding(
                EdgeInsets(
                    top: 16,
                    leading: 16,
                    bottom: 12,
                    trailing: 16,
                )
            )
            .frame(width: geometryProxy.size.width)
            .scrollDisabled(true)
        }
    }
    
    @ViewBuilder
    private var fearGreedMeter: some View {
        let value = viewModel.fearGreed?.data?.first?.value
        let percent: CGFloat = CGFloat((Double(value ?? "0") ?? 0) / 100)
        let circleSize: CGFloat = 32
        let circleOutlinePadding: CGFloat = 2
        let meterHorizontalPadding: CGFloat = 16
        let indicatorSize = FearGreedMeter.indicatorSize(
            circleSize: circleSize,
            outlinePadding: circleOutlinePadding
        )
        let indicatorOffset = FearGreedMeter.indicatorOffset(
            containerWidth: fearMeterWidth,
            indicatorSize: indicatorSize,
            percent: percent,
            horizontalPadding: meterHorizontalPadding
        )
        
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                FearGreedMeter(height: 24)
                    .frame(height: circleSize)
                    .padding(.horizontal, meterHorizontalPadding)
                    .readSize {
                        fearMeterWidth = $0.width
                    }
                
                Circle()
                    .foregroundStyle(Color.surfaceContainerHighest)
                    .frame(width: circleSize, height: circleSize)
                    .padding(circleOutlinePadding)
                    .background(
                        Circle()
                            .foregroundStyle(Color.outline)
                    )
                    .offset(x: indicatorOffset)
                    .animation(.default, value: value)
            }
            
            fearGreedMeterHeader
                .accessibilityHidden(true)
        }
        .padding(.vertical, 16)
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
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        } else {
            SingleHoverStats(
                hoverPrice: viewModel.hoverPrice,
                priceColor: getIndexColor(indexValue: viewModel.hoverPrice),
                hoverTime: viewModel.hoverTime,
                xPositionTime: viewModel.hoverTimePosition,
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
            .opacity(viewModel.isDragging ? 1 : 0)
            .animation(.default, value: viewModel.isDragging)
        }
    }
    
    private var fearGreedMeterHeader: some View {
        HStack {
            Text(Localization.string("Fear"))
            
            Spacer()
            
            Text(Localization.string("Greed"))
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDimmer)
        .padding(.horizontal, 16)
    }
}
