//
//  CryptoDetailPortfolioView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-18.
//

import SwiftUI

struct CryptoDetailPortfolioView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let viewModel: CryptoDetailViewModelImp
    
    @Binding var showAddTransactionSheet: Bool
    let showTransactionDetails: (any PortfolioEvent) -> Void
        
    private let selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: 32) {
            if let groupedTransactions = viewModel.groupedTransactions, groupedTransactions.isEmpty {
                EmptyContent(
                    title: "No transactions yet",
                    subTitle: "Add your \(viewModel.cryptoInfo?.name ?? "") transactions to start tracking your portfolio holdings here.",
                    buttonTitle: "Add Transaction",
                    buttonAction: {
                        Task {
                            let hasPro = await viewModel.hasPro()
                            if (viewModel.portfolio?.allTransactionsCount ?? 0) >= 3 && !hasPro {
                                AnalyticsManager.shared.log(
                                    BuyProOpened(fromScreen: .cryptoDetail, action: .AddTransaction)
                                )
                                showBuyPro()
                            } else {
                                AnalyticsManager.shared.log(
                                    SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioAddTransactionType)
                                )
                                showAddTransactionSheet = true
                            }
                        }
                    }
                )
                .padding(
                    EdgeInsets(
                        top: 40,
                        leading: 16,
                        bottom: 72,
                        trailing: 16
                    )
                )
            } else if let groupedTransactions = viewModel.groupedTransactions {
                overviewView
                
                transactionsView(
                    groupedTransactions: groupedTransactions
                )
            } else {
                overviewView
                
                tempList
            }
        }
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
    }
    
    private var overviewHeaderView: some View {
        HStack(spacing: 0) {
            Text("Statistics")
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityAddTraits(.isHeader)
            
            Spacer(minLength: 16)
            
            (viewModel.hidePortfolioData ? Image.unhide : Image.hide)
                .resizable()
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .foregroundStyle(Color.onSurfaceDimmer)
                .padding(12)
                .onTapGesture {
                    viewModel.toggleHideData()
                    if viewModel.hidePortfolioData {
                        AnalyticsManager.shared.log(PortfolioDataHide(fromScreen: .cryptoDetail))
                    } else {
                        AnalyticsManager.shared.log(PortfolioDataShow(fromScreen: .cryptoDetail))
                    }
                }
                .accessibilityLabel("\(viewModel.hidePortfolioData ? "Show" : "Hide") portfolio data")
        }
        .animation(.none, value: viewModel.hidePortfolioData)
        .accessibilityElement(children: .contain)
    }

    private var overviewView: some View {
        VStack(alignment: .leading, spacing: 4) {
            overviewHeaderView
            
            VStack(spacing: 16) {
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                    holdingsView
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    currentValueView
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Separator()
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                    purchaseCostView
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    profitLossView
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .cardBackground()
        }
    }
    
    private var holdingsView: some View {
        let amount = viewModel.portfolio?.getAllTransactions(of: viewModel.cryptoInfo?.id).getAmount()
        let symbol = viewModel.cryptoInfo?.symbol?.uppercased() ?? ""
        let coinName = viewModel.cryptoInfo?.name ?? symbol
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("Total Holdings")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            NewShimmeringText(
                text: "\(amount?.formatCurrency(currency: CurrencyModel.empty) ?? "00000") \(symbol)",
                isDownloading: viewModel.groupedTransactions == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Total Holdings, \((amount ?? 0).formatCurrency(currency: CurrencyModel.empty, accessible: true)) \(coinName)"
        )
    }
    
    @ViewBuilder
    private var currentValueView: some View {
        let amount = viewModel.portfolio?.getAllTransactions(of: viewModel.cryptoInfo?.id).getAmount() ?? 0
        let currentPrice = viewModel.pie?.data?.sparkline_in_7d?.price.last ?? viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Current Value")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            NewShimmeringText(
                text: (amount * currentPrice).formatCurrency(threshold: FormattingThreshold.million),
                isDownloading: viewModel.groupedTransactions == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            currencyStatAccessibilityLabel(
                title: "Current Value",
                value: amount * currentPrice
            )
        )
    }
    
    @ViewBuilder
    private var purchaseCostView: some View {
        let currentPrice = viewModel.pie?.data?.sparkline_in_7d?.price.last ?? viewModel.cryptoInfo?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
        let cost = viewModel.portfolio?.getAllTransactions(of: viewModel.cryptoInfo?.id).getTotalCost(
            prices: [selectedCurrency.code.lowercased() : currentPrice],
            showCurrency: selectedCurrency.code
        )
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Purchase Cost")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            NewShimmeringText(
                text: cost?.formatCurrency(threshold: FormattingThreshold.million) ?? "0000000",
                isDownloading: viewModel.groupedTransactions == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            currencyStatAccessibilityLabel(
                title: "Purchase Cost",
                value: cost
            )
        )
    }
    
    @ViewBuilder
    private var profitLossView: some View {
        let transactions = viewModel.portfolio?.getAllTransactions(of: viewModel.cryptoInfo?.id)
        let prices = viewModel.cryptoInfo?.market_data?.current_price
        let profitValue = transactions?.getProfitValue(prices: prices, showCurrency: selectedCurrency.code)
        let profitPercent = transactions?.getProfitPercent(prices: prices, showCurrency: selectedCurrency.code)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Profit/Loss")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            VStack(alignment: .leading, spacing: 0) {
                NewPriceChangeValueView(
                    change: profitValue,
                    hideData: viewModel.hidePortfolioData,
                    accessibleTimeframe: "",
                    showDirection: false,
                    isDownloading: prices?.isEmpty ?? true
                )
                
                NewPriceChangePercentView(
                    change: profitPercent,
                    size: .extraSmall,
                    accessibleTimeframe: "",
                    isDownloading: prices?.isEmpty ?? true
                )
                .opacity(0.75)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            profitLossAccessibilityLabel(
                value: profitValue,
                percent: profitPercent
            )
        )
    }
    
    private func currencyStatAccessibilityLabel(title: String, value: Double?) -> String {
        "\(title), \(value?.formatAccessibleCurrency() ?? "")"
    }
    
    private func profitLossAccessibilityLabel(value: Double?, percent: Double?) -> String {
        let safeChange = (percent ?? 0).isInfinite ? 0 : (percent ?? 0)
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        let percentText = "\(direction) \(accessiblePercent) percent"
        
        if viewModel.hidePortfolioData {
            return "Profit/Loss, \(percentText)"
        }
        
        let changeValue = value ?? 0
        let valueDirection = changeValue.directionAccessible.lowercased()
        let valueText = abs(changeValue).formatAccessibleCurrency()
        return "Profit/Loss, \(valueDirection) \(valueText), \(percentText)"
    }
    
    private var headerView: some View {
        HStack(spacing: 0) {
            Text("Transactions")
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityAddTraits(.isHeader)
            
            Spacer(minLength: 16)
            
            Button(action: {
                Task {
                    let hasPro = await viewModel.hasPro()
                    if (viewModel.portfolio?.allTransactionsCount ?? 0) >= 3 && !hasPro {
                        AnalyticsManager.shared.log(
                            BuyProOpened(fromScreen: .cryptoDetail, action: .AddTransaction)
                        )
                        showBuyPro()
                    } else {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .cryptoDetail, sheet: .portfolioAddTransactionType)
                        )
                        showAddTransactionSheet = true
                    }
                }
            }, label: {
                Image.add
                    .resizable()
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .padding(12)
            })
            .accessibilityLabel("Add new transaction")
            .opacity((viewModel.groupedTransactions?.isEmpty ?? true) ? 0 : 1)
        }
    }
    
    @ViewBuilder
    private func transactionsView(
        groupedTransactions: [Date: [any PortfolioEvent]]
    ) -> some View {
        let prices = viewModel.cryptoInfo?.market_data?.current_price
        
        VStack(alignment: .leading, spacing: 4) {
            headerView
            
            VStack(alignment: .leading, spacing: 16) {
                let sortedTransactions = groupedTransactions.keys.sorted(by: >)
                
                ForEach(sortedTransactions, id: \.self) { date in
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.satoshiMedium(14))
                        .foregroundStyle(Color.onSurfaceDim)
                    
                    ForEach(Array((groupedTransactions[date] ?? []).enumerated()), id: \.element.id) { index, event in
                        let coin = viewModel.portfolio?.pie(containing: event)?.data
                        let events = groupedTransactions[date] ?? []
                        
                        if let transaction = event as? NewTransaction {
                            PortfolioTransactionView(
                                coin: coin,
                                transaction: transaction,
                                prices: prices,
                                hideData: viewModel.hidePortfolioData,
                                index: index,
                                totalCount: events.count,
                                showTransactionDetails: {
                                    showTransactionDetails(transaction)
                                }
                            )
                        } else if let swap = event as? NewSwapTransaction {
                            PortfolioSwapView(
                                coin: coin,
                                transaction: swap,
                                portfolio: viewModel.portfolio,
                                hideData: viewModel.hidePortfolioData,
                                index: index,
                                totalCount: events.count,
                                showTransactionDetails: {
                                    showTransactionDetails(swap)
                                }
                            )
                        } else if let walletImport = event as? AddressImport {
                            PortfolioImportTransaction(
                                coin: coin,
                                walletImport: walletImport,
                                prices: viewModel.allPrices,
                                hideData: viewModel.hidePortfolioData,
                                index: index,
                                totalCount: events.count,
                                showTransactionDetails: {
                                    showTransactionDetails(walletImport)
                                }
                            )
                        }
                    }
                    
                    if date != sortedTransactions.last {
                        Separator()
                    }
                }
            }
            .cardBackground()
        }
    }
    
    private var tempList: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerView
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<(isPad ? 4 : 2), id: \.self) { sectionIndex in
                    NewShimmeringText(
                        text: "Apr 7, 2025",
                        isDownloading: true
                    )
                    .font(.satoshiMedium(14))
                    .foregroundStyle(Color.onSurfaceDim)
                    
                    ForEach(0..<(isPad ? 6 : 3), id: \.self) { index in
                        PortfolioTransactionView(
                            coin: nil,
                            transaction: nil,
                            prices: [:],
                            hideData: viewModel.hidePortfolioData,
                            index: index,
                            totalCount: isPad ? 6 : 3,
                            showTransactionDetails: { }
                        )
                    }
                    
                    if sectionIndex != (isPad ? 3 : 1) {
                        Separator()
                    }
                }
            }
            .cardBackground()
        }
    }
}
