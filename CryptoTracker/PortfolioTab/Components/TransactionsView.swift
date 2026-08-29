//
//  TransactionsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/29/25.
//

import SwiftUI

struct TransactionsView: View {
    let portfolio: [Pie]?
    let groupedTransactions: [Date: [any PortfolioEvent]]
    let prices: [Cryptocurrency]
    let hideData: Bool
    let typeFilters: [NewTransactionType]
    let dateFilter: DateOption
    let coinFilters: [Toplist]
    let typeFilterPressed: () -> Void
    let dateFilterPressed: () -> Void
    let coinFilterPressed: () -> Void
    let clearFilters: () -> Void
    let showTransactionDetails: (any PortfolioEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let portfolio, portfolio.isEmpty {
                EmptyContent(
                    title: "No assets yet",
                    subTitle: "Tap the + button to begin building your portfolio."
                )
                .frame(maxWidth: .infinity)
                .padding(
                    EdgeInsets(
                        top: 72,
                        leading: 32,
                        bottom: 0,
                        trailing: 32
                    )
                )
            } else {
                filtersView
                
                LazyVStack(alignment: .leading, spacing: 16) {
                    transactionsView
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: 82,
                trailing: 0
            )
        )
    }
    
    var filtersView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    FilterButtonView(
                        title: typeFilters.isEmpty ? "Type" : "Type (\(typeFilters.count))",
                        accessibilityLabel: typeFilterAccessibilityLabel,
                        isActive: !typeFilters.isEmpty,
                        action: {
                            typeFilterPressed()
                        }
                    )
                    
                    FilterButtonView(
                        title: dateFilter.rangeTitle,
                        accessibilityLabel: dateFilterAccessibilityLabel,
                        isActive: dateFilter != .all,
                        action: {
                            dateFilterPressed()
                        }
                    )
                    
                    FilterButtonView(
                        title: coinFilters.isEmpty ? "Coin" : "Coin (\(coinFilters.count))",
                        accessibilityLabel: coinFilterAccessibilityLabel,
                        isActive: !coinFilters.isEmpty,
                        action: {
                            coinFilterPressed()
                        }
                    )
                }
                .padding(
                    EdgeInsets(
                        top: 32,
                        leading: 16,
                        bottom: 12,
                        trailing: 16
                    )
                )
            }
            
            if !typeFilters.isEmpty || dateFilter != .all || !coinFilters.isEmpty {
                Button(action: {
                    clearFilters()
                }, label: {
                    Text("Clear filters")
                        .underline()
                        .font(.satoshiMedium(16))
                        .foregroundStyle(Color.onSurfaceDim)
                        .padding(
                            EdgeInsets(
                                top: 10,
                                leading: 16,
                                bottom: 10,
                                trailing: 16
                            )
                        )
                })
                .accessibilityLabel("Clear filters")
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, !typeFilters.isEmpty || dateFilter != .all || !coinFilters.isEmpty ? 16 : 6)
    }
    
    private var typeFilterAccessibilityLabel: String {
        filterAccessibilityLabel(
            name: "Type filter",
            selectedValues: typeFilters.isEmpty
                ? nil
                : typeFilters.map(\.rawValue).joined(separator: ", ")
        )
    }
    
    private var dateFilterAccessibilityLabel: String {
        filterAccessibilityLabel(
            name: "Date filter",
            selectedValues: dateFilter == .all ? nil : dateFilterAccessibilityValue
        )
    }
    
    private var dateFilterAccessibilityValue: String {
        switch dateFilter {
        case .custom(let startDate, let endDate):
            let start = formattedAccessibilityDate(startDate)
            let end = formattedAccessibilityDate(endDate)
            
            if start.isEmpty || end.isEmpty {
                return "Custom"
            }
            
            return "\(start) to \(end)"
        default:
            return dateFilter.title
        }
    }
    
    private var coinFilterAccessibilityLabel: String {
        filterAccessibilityLabel(
            name: "Coin filter",
            selectedValues: coinFilters.isEmpty
                ? nil
                : coinFilters.map { $0.name ?? $0.symbol ?? "" }.joined(separator: ", ")
        )
    }
    
    private func filterAccessibilityLabel(name: String, selectedValues: String?) -> String {
        guard let selectedValues, !selectedValues.isEmpty else {
            return name
        }
        
        return "\(name), currently selected: \(selectedValues)"
    }
    
    private func formattedAccessibilityDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }
    
    private var transactionsView: some View {
        ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurfaceDim)
                .padding(.top, 16)
            
            ForEach(Array((groupedTransactions[date] ?? []).enumerated()), id: \.element.id) { index, event in
                let coin = portfolio?.pie(containing: event)?.data
                let coinPrices = prices.first(where: { price in price.id == coin?.id })?.prices
                let events = groupedTransactions[date] ?? []
                
                if let transaction = event as? NewTransaction {
                    PortfolioTransactionView(
                        coin: coin,
                        transaction: transaction,
                        prices: coinPrices,
                        hideData: hideData,
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
                        portfolio: portfolio,
                        hideData: hideData,
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
                        prices: prices,
                        hideData: hideData,
                        index: index,
                        totalCount: events.count,
                        showTransactionDetails: {
                            showTransactionDetails(walletImport)
                        }
                    )
                }
            }
        }
    }
}
