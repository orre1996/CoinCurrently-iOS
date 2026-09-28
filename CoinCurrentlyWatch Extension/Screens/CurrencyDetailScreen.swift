//
//  CurrencyDetailScreen.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-25.
//

import SwiftUI

@MainActor
struct CurrencyDetailScreen: View {
    @State var viewModel: CryptoDetailViewModelImp
    @State private var globalMarketViewModel = GlobalMarketViewModelImp()
    @State private var biggestChartValue: CGSize = .zero
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var isSelectingCurrency = false
    @State private var showCommunitySentimentHelp = false

    init(cryptoInfo: CurrencyDataModel) {
        _viewModel = State(wrappedValue: CryptoDetailViewModelImp(cryptoInfo: cryptoInfo))
    }

    var body: some View {
        let halfBiggestChartValueHeight = biggestChartValue.height / 2

        ZStack {
            Color.surface
                .ignoresSafeArea()

            GeometryReader { reader in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
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
                            currency: selectedCurrency,
                            isWebSocketEnabled: false,
                            changeCoin: {}
                        )
                        .padding(.bottom, 16)

                        ZStack {
                            ChartBackground(
                                biggestValue: $biggestChartValue,
                                values: viewModel.mainGraphStats
                            )

                            if viewModel.mainReloading {
                                ActivityIndicator(
                                    size: 24,
                                    color: .onSurface
                                )
                                .padding(.trailing, biggestChartValue.width)
                                .frame(maxWidth: .infinity)
                                .accessibilityHidden(true)
                            } else {
                                mainGraph(halfBiggestChartValueHeight: halfBiggestChartValueHeight)
                                    .opacity(viewModel.showMainPriceError ? 0 : 1)
                                    .frame(height: chartHeight(in: reader))
                            }
                        }
                        .frame(height: chartHeight(in: reader))

                        ChartTimeStamps(
                            currentTimeChart: viewModel.selectedTimeFrame,
                            timeStamps: viewModel.getTimestamps()
                        )
                        .padding(
                            EdgeInsets(
                                top: -halfBiggestChartValueHeight,
                                leading: 0,
                                bottom: 0,
                                trailing: biggestChartValue.width
                            )
                        )

                        CryptoDetailOverviewView(
                            cryptoDetailModel: viewModel.cryptoInfo,
                            timeChart: viewModel.selectedTimeFrame,
                            prices: viewModel.onlyPrices,
                            totalMarketCap: globalMarketViewModel.globalMarket?.data?.total_market_cap?.getConvertedCurrency(),
                            alerts: nil,
                            fromScreen: .cryptoDetail,
                            isSelectingCurrency: $isSelectingCurrency,
                            selectedCurrency: $selectedCurrency,
                            showCommunitySentimentHelp: $showCommunitySentimentHelp,
                            addNewAlert: {},
                            deleteAlert: { _ in },
                            showsCurrencyConverter: false,
                            showsPriceAlerts: false,
                            horizontalPadding: 0
                        )
                    }
                }
            }
        }
        .navigationBarTitle(viewModel.cryptoInfo?.name ?? "Market")
        .task {
            async let globalMarket: Void = loadGlobalMarket()
            await viewModel.setStartData()
            await viewModel.refresh(
                showReload: true,
                newDays: nil,
                newTimeChart: nil,
                forceId: nil
            )
            await globalMarket
        }
    }

    private func loadGlobalMarket() async {
        await globalMarketViewModel.setStartData()
        await globalMarketViewModel.getGlobalMarket()
    }

    private func chartHeight(in reader: GeometryProxy) -> CGFloat {
        max(72, reader.size.height * 0.32)
    }

    private func mainGraph(halfBiggestChartValueHeight: CGFloat) -> some View {
        PriceLineChartView(
            prices: viewModel.getPrices(),
            color: viewModel.graphColor,
            lineWidth: 2
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
}
