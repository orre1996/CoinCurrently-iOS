//
//  PortfolioPerformanceChart.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import SwiftUI

struct PortfolioPerformanceChart: View {
    @Bindable var viewModel: PortfolioViewModelImp
    let isPieChartShowing: Bool
    @Binding var selectedPieSliceId: String?
    @Binding var biggestChartValue: CGSize
    @Binding var lineChartHeight: CGFloat
    let chartHeight: CGFloat

    private var halfBiggestChartValueHeight: CGFloat {
        biggestChartValue.height / 2
    }

    var body: some View {
        Group {
            if isPieChartShowing {
                PortfolioPieChartView(
                    slices: viewModel.holdings.portfolioPieSlices,
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
                lineChart
                    .readSize {
                        lineChartHeight = $0.height
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
    }

    private var lineChart: some View {
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
                    .frame(height: max(1, chartHeight))

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
                        .frame(height: max(1, chartHeight))
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
            .frame(height: max(1, chartHeight))
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
                hoverTimeWidthSize: $viewModel.hover.hoverTimeWidthSize
            )
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
}
