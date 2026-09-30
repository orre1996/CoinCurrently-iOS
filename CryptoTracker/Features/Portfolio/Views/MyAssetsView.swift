//
//  MyAssetsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/18/25.
//

import SwiftUI

struct MyAssetsView: View {
    let portfolio: [Pie]?
    let allPrices: [Cryptocurrency]
    let hideData: Bool
    let navigateToCoin: (Toplist) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if let portfolio, portfolio.isEmpty {
                EmptyContent(
                    title: Localization.string("No assets yet"),
                    subTitle: Localization.string("Tap the + button to begin building your portfolio.")
                )
                .frame(maxWidth: .infinity)
                .padding(
                    EdgeInsets(
                        top: 40,
                        leading: 16,
                        bottom: 40,
                        trailing: 16
                    )
                )
            } else {
                PortfolioHeaderView()
                
                if let portfolio, !portfolio.isEmpty {
                    realList(
                        portfolio: portfolio
                    )
                } else {
                    tempList
                }
            }
        }
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 82,
                trailing: 16
            )
        )
    }
    
    var tempList: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<(isPad ? 20 : 10), id: \.self) { index in
                PortfolioCoinView(
                    pie: nil,
                    transactions: nil,
                    prices: [:],
                    hideData: hideData,
                    index: index,
                    totalCount: isPad ? 20 : 10,
                    navigateToCoin: { }
                )
            }
        }
    }
    
    func realList(
        portfolio: [Pie]
    ) -> some View {
        LazyVStack(spacing: 16) {
            let filteredPortfolio = portfolio.filter { pie in
                guard pie.shouldShow, let id = pie.data?.id else { return false }
                return !portfolio.getAllTransactions(of: id).isEmpty
            }
            
            ForEach(filteredPortfolio.indices, id: \.self) { index in
                let pie = filteredPortfolio[index]
                
                PortfolioCoinView(
                    pie: pie,
                    transactions: portfolio.getAllTransactions(of: pie.data?.id),
                    prices: allPrices.first(where: { $0.id == pie.data?.id })?.prices ?? [:],
                    hideData: hideData,
                    index: index,
                    totalCount: filteredPortfolio.count,
                    navigateToCoin: {
                        guard let coin = pie.data else {
                            return
                        }
                        
                        navigateToCoin(coin)
                    }
                )
            }
        }
    }
}
