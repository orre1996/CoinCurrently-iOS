//
//  CurrencyDetailScreen.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-25.
//

import SwiftUI

@MainActor
struct CurrencyDetailScreen: View {
    @Environment(NavigationViewModel.self) var navigationViewModel
    
    @State var viewModel: CryptoDetailViewModelImp

    @State private var twoLines = false
    
    private let selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    @ScaledMetric private var scale: CGFloat = 1
    
    init(cryptoInfo: CurrencyDataModel) {
        _viewModel = State(wrappedValue: CryptoDetailViewModelImp(cryptoInfo: cryptoInfo))
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                 overview
                
                Text("\(viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: .none, currency: selectedCurrency) ?? "$0.00")")
                    .font(.satoshiBold(20))
                
                VStack(spacing: 0) {
                    highsAndLows
                        .padding(.vertical, 8)
                    
                    priceChart
                    
                    Separator()
                    
                    chartTimes
                }
                .padding(.bottom, 8)
                
                dailyChangeView
                
                weeklyChangeView
                
                monthlyChangeView
            }
            .foregroundColor(.onSurface)
            .cornerRadius(8)
        }
        .navigationBarTitle(viewModel.cryptoInfo?.name ?? "Market")
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.refresh(
                        showReload: true,
                        newDays: nil,
                        newTimeChart: nil,
                        forceId: nil
                    )
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var overview: some View {
        HStack(spacing: 8) {
            ShimmeringImage(
                imageUrl: viewModel.cryptoInfo?.image?.small,
                downloading: viewModel.cryptoInfo == nil,
                size: 24 * min(scale, 1.5)
            )

            Text("\(viewModel.cryptoInfo?.name ?? "")")
                .font(.satoshiBold(16))
        }
    }
    
    private var chartTimes: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)
            
            ForEach((1...3), id: \.self) {
                ShimmeringText(
                    text: getTimeInChart(at: $0),
                    isDownloading: viewModel.timeStamps.isEmpty
                )
                .font(.satoshiMedium(12))
                .foregroundColor(.onSurface)
                
                Spacer(minLength: 0)
            }
        }
    }
    
    private func getTimeInChart(at index: Int) -> String {
        guard !viewModel.getTimestamps().isEmpty else { return "00000" }

        let steps: Double = 1 / 6
        let currentIndex = Int(Double(viewModel.getTimestamps().count) * steps * Double(index))
        let currentTimeStamp = viewModel.getTimestamps()[safely: currentIndex] ?? 0
        
        let date = Date(timeIntervalSince1970: currentTimeStamp / 1000)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM dd"
        
        return dateFormatter.string(from: date)
    }
    
    private var priceChart: some View {
        ZStack {
            WatchChartBackgroundPathVertical()
                .stroke(Color.outlineVariant)
            
            if !viewModel.mainReloading {
                PriceLineChartView(
                    prices: viewModel.prices,
                    color: viewModel.graphColor,
                    lineWidth: 1
                )
            } else {
                ActivityIndicator(size: 24)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 75)
    }
    
    @ViewBuilder
    private var highsAndLows: some View {
        HStack(spacing: 0) {
            Image.trendDown
                .resizable()
                .frame(width: 10, height: 10)

            ShimmeringText(
                text: viewModel.prices.min()?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000",
                isDownloading: viewModel.prices.isEmpty
            )
            .padding(.horizontal, 4)
            
            Spacer(minLength: 0)
            
            Image.trendUp
                .resizable()
                .frame(width: 10, height: 10)
                .padding(.horizontal, 4)
            
            ShimmeringText(
                text: viewModel.prices.max()?.formatCurrency(threshold: FormattingThreshold.none) ?? "00000",
                isDownloading: viewModel.prices.isEmpty
            )
        }
        .foregroundColor(.onSurface)
        .font(.satoshiRegular(12))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
    
    private var dailyChangeView: some View {
        HStack(spacing: 4) {
            Text("24h: ")
                .font(.satoshiBold(14))
            
            PriceChangePercentView(
                change: viewModel.cryptoInfo?.market_data?.price_change_percentage_24h,
                size: .small,
                accessibleTimeframe: "24 hour",
                directionPosition: .right,
                isDownloading: viewModel.cryptoInfo == nil
            )
        }
    }
    
    private var weeklyChangeView: some View {
        HStack(spacing: 4) {
            Text("7d: ")
                .font(.satoshiBold(14))
            
            PriceChangePercentView(
                change: viewModel.cryptoInfo?.market_data?.price_change_percentage_7d,
                size: .small,
                accessibleTimeframe: "7 days",
                directionPosition: .right,
                isDownloading: viewModel.cryptoInfo == nil
            )
        }
    }
    
    private var monthlyChangeView: some View {
        HStack(spacing: 4) {
            Text("30d: ")
                .font(.satoshiBold(14))
            
            PriceChangePercentView(
                change: viewModel.cryptoInfo?.market_data?.price_change_percentage_30d,
                size: .small,
                accessibleTimeframe: "30 days",
                directionPosition: .right,
                isDownloading: viewModel.cryptoInfo == nil
            )
        }
    }
}
