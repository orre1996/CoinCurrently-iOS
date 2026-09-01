//
//  TreasuryDetailScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/22/26.
//

import SwiftUI

@MainActor
struct TreasuryDetailScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled

    @ScaledMetric private var scale: CGFloat = 1

    @State private var viewModel: TreasuryDetailViewModelImp
    @State private var biggestChartValue: CGSize = .zero
    @State private var isHoldingFilterShowing = false
    @State private var showScrollToTopButton = false
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollToTop = false
    @State private var id = UUID()

    init(treasuryId: String, treasuryDetail: TreasuryDetailEntity, coinId: String) {
        _viewModel = State(
            wrappedValue: TreasuryDetailViewModelImp(
                treasuryId: treasuryId,
                treasuryDetail: treasuryDetail,
                coinId: coinId
            )
        )
    }

    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2

        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()

            GeometryReader { reader in
                ScrollViewReader { scrollViewReader in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            CryptoDetailSummaryView(
                                name: viewModel.treasuryDetail?.name,
                                currentPrice: viewModel.onlyPrices.last,
                                imageUrl: nil,
                                countryCode: viewModel.treasuryDetail?.country,
                                prices: viewModel.onlyPrices,
                                isSharing: false,
                                image: nil,
                                selectedTimeframe: viewModel.selectedTimeFrame,
                                shortPrice: false,
                                shortChange: false,
                                currency: viewModel.selectedCurrency,
                                changeCoin: { }
                            )
                            .padding(
                                EdgeInsets(
                                    top: 0,
                                    leading: 16,
                                    bottom: 16,
                                    trailing: 16
                                )
                            )
                            .id(id)

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
                                    top: -biggestChartValue.height / 2,
                                    leading: 16,
                                    bottom: biggestChartValue.height / 2,
                                    trailing: 16 + biggestChartValue.width
                                )
                            )

                            ChartButtonsViewNew(
                                fromScreen: .treasuryDetail,
                                chartButtons: ChartButton.treasuryDetailButtons(),
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
                            .padding(.bottom, 16)

                            TreasuryTransactionHistoryView(
                                holdings: viewModel.availableHoldingCoins,
                                selectedHoldingCoinId: viewModel.selectedTransactionHoldingCoinId,
                                transactions: viewModel.transactionHistory?.transactions,
                                showHoldingFilter: {
                                    isHoldingFilterShowing = true
                                }
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 22)
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
                                        ScrollToTopPressed(fromScreen: .treasuryDetail)
                                    )
                                    scrollToTop.toggle()
                                },
                                isVisible: showScrollToTopButton
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
        .navigationBarTitle(viewModel.treasuryDetail?.name ?? "", displayMode: .inline)
        .navigationPopGestureDisabled(viewModel.isDragging)
        .task {
            AchievementManager.shared.increment(.treasuryVisits)
            await viewModel.setStartData()
            await viewModel.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await viewModel.refresh()
                }
            }
        }
        .sheet(isPresented: $isHoldingFilterShowing) {
            TreasuryHoldingFilterSheet(
                holdings: viewModel.availableHoldingCoins,
                selectedCoinId: viewModel.selectedTransactionHoldingCoinId,
                newHoldingSelected: { coin in
                    Task {
                        await viewModel.setTransactionHoldingFilter(coin)
                    }
                }
            )
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
}
