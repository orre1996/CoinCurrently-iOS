//
//  ExploreCardView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-27.
//

import SwiftUI

struct ExploreCardView: View {
    let coin: Toplist
    let isTop: Bool
    
    @State private var biggestChartValue: CGSize = .zero
    @State private var chartSize: CGSize = .zero
    
    private let selectedTimeframe: TimeCharts = .aWeek
    
    private var chartPrices: [Double] {
        if let prices = coin.sparkline_in_7d?.price.filter({ $0 > 0 }), !prices.isEmpty {
            return prices
        }
        
        if let current = coin.current_price,
           let changePct = coin.price_change_percentage_7d_in_currency,
           current > 0 {
            let start = current / (1 + changePct / 100)
            return [start, current]
        }
        
        return []
    }
    
    private var graphColor: Color {
        Double.getDifferenceInPercent(between: chartPrices.last, and: chartPrices.first)?.changeColor
            ?? coin.price_change_percentage_7d_in_currency?.changeColor
            ?? .onSurfaceDim
    }
    
    private var chartTimestamps: [Double] {
        let count = chartPrices.count
        guard count > 1 else { return [] }
        
        let now = Date().timeIntervalSince1970 * 1000
        let sevenDaysMs = 7.0 * 24 * 60 * 60 * 1000
        let step = sevenDaysMs / Double(count - 1)
        
        return (0..<count).map { index in
            now - sevenDaysMs + (step * Double(index))
        }
    }
    
    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2
        
        VStack(spacing: 0) {
            CryptoDetailSummaryView(
                name: coin.name,
                currentPrice: coin.current_price,
                imageUrl: coin.image,
                prices: chartPrices.isEmpty ? nil : chartPrices,
                isSharing: false,
                image: nil,
                selectedTimeframe: selectedTimeframe,
                shortPrice: false,
                shortChange: false,
                changeCoin: {}
            )
            .padding(.horizontal, 16)
            
            ZStack {
                ChartBackground(
                    biggestValue: $biggestChartValue,
                    values: (0..<6).map { chartValue(at: $0) }
                )
                
                if chartPrices.count >= 2 {
                    NewChartView(
                        prices: chartPrices,
                        color: graphColor,
                        lineWidth: 2,
                        dragPositions: [],
                        size: chartSize,
                        isDragging: false
                    )
                    .readSize { chartSize = $0 }
                    .padding(
                        EdgeInsets(
                            top: halfBiggestChartValueHeight,
                            leading: 0,
                            bottom: halfBiggestChartValueHeight,
                            trailing: biggestChartValue.width
                        )
                    )
                } else {
                    ActivityIndicator()
                        .padding(.trailing, biggestChartValue.width)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
            .accessibilityHidden(true)
            
            ChartTimeStamps(
                currentTimeChart: selectedTimeframe,
                timeStamps: chartTimestamps
            )
            .padding(
                EdgeInsets(
                    top: -biggestChartValue.height / 2,
                    leading: 16,
                    bottom: 8 + biggestChartValue.height / 2,
                    trailing: 16 + biggestChartValue.width
                )
            )
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isTop ? 0.12 : 0.06), radius: isTop ? 16 : 8, y: isTop ? 8 : 4)
        .accessibilityElement(children: .contain)
    }
    
    private func chartValue(at index: Int) -> String? {
        guard chartPrices.count >= 2,
              let minPrice = chartPrices.min(),
              let maxPrice = chartPrices.max(),
              maxPrice > minPrice else {
            return chartPrices.first?.formatCurrency(threshold: .none)
        }
        
        let step = (maxPrice - minPrice) / 5
        let value = minPrice + (step * Double(index))
        return value.formatCurrency(threshold: .none)
    }
}

private enum ExploreSwipeDirection {
    case left
    case right
}

struct ExploreSwipeDeckView: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    
    @Bindable var viewModel: ExploreViewModelImp
    
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false
    
    private let swipeThreshold: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if let nextCoin = viewModel.nextCoin {
                    ExploreCardView(coin: nextCoin, isTop: false)
                        .scaleEffect(0.95)
                        .offset(y: 12)
                        .allowsHitTesting(false)
                        .id(nextCoin.id)
                }
                
                if let currentCoin = viewModel.currentCoin {
                    ExploreCardView(coin: currentCoin, isTop: true)
                        .offset(x: dragOffset.width, y: dragOffset.height * 0.08)
                        .rotationEffect(.degrees(Double(dragOffset.width / 24)))
                        .opacity(isAnimatingOut ? 0 : 1)
                        .gesture(swipeGesture)
                        .id(currentCoin.id)
                        .overlay(alignment: .topLeading) {
                            swipeHint(
                                text: "Skip",
                                opacity: skipHintOpacity
                            )
                            .padding(24)
                        }
                        .overlay(alignment: .topTrailing) {
                            swipeHint(
                                text: "Open",
                                opacity: openHintOpacity
                            )
                            .padding(24)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            
            actionButtons
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            SecondaryButton(
                text: "Skip",
                accessibilityLabel: "Skip this coin",
                icon: .arrowLeft,
                fullWidth: true,
                action: {
                    commitSwipe(direction: .left)
                }
            )
            .disabled(viewModel.currentCoin == nil || isAnimatingOut)
            
            PrimaryButton(
                text: "Open",
                accessibilityLabel: "Open coin details",
                fullWidth: true,
                action: {
                    commitSwipe(direction: .right)
                }
            )
            .disabled(viewModel.currentCoin == nil || isAnimatingOut)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard !isAnimatingOut else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimatingOut else { return }
                
                if value.translation.width <= -swipeThreshold {
                    commitSwipe(direction: .left)
                } else if value.translation.width >= swipeThreshold {
                    commitSwipe(direction: .right)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    private var skipHintOpacity: Double {
        min(max(-Double(dragOffset.width) / 80, 0), 1)
    }
    
    private var openHintOpacity: Double {
        min(max(Double(dragOffset.width) / 80, 0), 1)
    }
    
    @ViewBuilder
    private func swipeHint(text: String, opacity: Double) -> some View {
        Text(text)
            .font(.satoshiBold(14))
            .foregroundStyle(Color.onSurface)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .optionalGlassEffect(
                color: Color.surfaceContainerHigh,
                radius: 1000,
                isInteractive: false
            )
            .opacity(opacity)
            .accessibilityHidden(true)
    }
    
    private func commitSwipe(direction: ExploreSwipeDirection) {
        guard !isAnimatingOut, let coin = viewModel.currentCoin else { return }
        
        isAnimatingOut = true
        
        let finishSwipe = {
            dragOffset = .zero
            isAnimatingOut = false
            
            switch direction {
            case .left:
                viewModel.skip()
            case .right:
                AnalyticsManager.shared.log(
                    Navigate(
                        fromScreen: .explore,
                        toScreen: .cryptoDetail,
                        coinName: coin.name ?? ""
                    )
                )
                
                navigationViewModel.navPath.append(
                    NavigationScreens.CryptoDetail(
                        currencyDataModel: coin.toCryptoDetail
                    )
                )
                viewModel.skip()
            }
        }
        
        if accessibilityReduceMotion {
            finishSwipe()
            return
        }
        
        let exitX: CGFloat = direction == .left ? -500 : 500
        
        withAnimation(.easeInOut(duration: 0.25)) {
            dragOffset = CGSize(width: exitX, height: dragOffset.height)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            finishSwipe()
        }
    }
}
