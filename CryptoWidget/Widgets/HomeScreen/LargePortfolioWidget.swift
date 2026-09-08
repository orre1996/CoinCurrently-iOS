//
//  LargePortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-29.
//

import SwiftUI

struct LargePortfolioWidget: View {
    var entry: PortfolioEntry?
    
    var body: some View {
        /*let hasBoughtPro = CachedStorageManagerImp.shared.load(type: LocalStorageKeys.proStatus) ?? false
        
        Link(destination: URL(string: hasBoughtPro ? "portfolio" : "buyPro")!) {
            
            VStack {
                
                portfolioOverview
                    .padding(.horizontal, 5)
                
                dataGraph
                    .padding(.bottom, 5)
            }
            .overlay (
                WidgetBuyProOverlay()
            )
        }*/
    }
    
    /*private var portfolioOverview: some View {
        
        let totalValue = WidgetReloadService.shared.getTotalValue(portfolio: entry?.pieModel)
        
        let totalValueDouble = WidgetReloadService.shared.getTotalValueDouble(portfolio: entry?.pieModel)
        
        let totalProfit = WidgetReloadService.shared.getPortfolioProfitLossValue(of: entry?.pieModel,
                                                                             coinPrices: entry?.allPrices ?? [])
        
        let profitLossPercent = WidgetReloadService.shared.getPortfolioProfitLossPercent(of: entry?.pieModel,
                                                                                     totalValue: totalValueDouble,
                                                                                     coinPrices: entry?.allPrices ?? [])
        
        
        return GeometryReader { reader in
            
            ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
                
                GeometryReader { reader in
                    
                    VStack(spacing: 0) {
                        
                        Text(totalValue)
                            .frame(width: reader.size.width / 2.8)
                            .font(.regularWidget18)
                            .foregroundColor(.onSurface)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            
                            Text("P/L:")
                                .foregroundColor(.onSurface)
                                .font(.regularWidget12)
                            
                            let showInPercent = true
                            let currentPrice = entry?.pieModel.map({( $0.value ?? 0) }).reduce(0, +)
                            
                            Text(((showInPercent ? (profitLossPercent.getPriceWithSymbol(currentPrice: currentPrice)) + "%" : totalProfit?.formatCurrency(threshold: .thousand)) ?? ""))
                                .foregroundColor(showInPercent ? profitLossPercent.getWidgeWidgetPriceChangeColor(currentPrice: currentPrice) : totalProfit?.getWidgeWidgetPriceChangeColor(currentPrice: currentPrice))
                                .font(.regularWidget12)
                            
                            ScaledBezier(bezierPath: showInPercent ? profitLossPercent.getPriceDirectionShape(currentPrice: currentPrice) : totalProfit?.getPriceDirectionShapePortfolio(currentPrice: currentPrice) ?? .priceStillTriangle )
                                .fill((showInPercent ? profitLossPercent.getWidgeWidgetPriceChangeColor(currentPrice: currentPrice) : totalProfit?.getWidgeWidgetPriceChangeColor(currentPrice: currentPrice)) ?? Color.onSurfaceDim)
                                .frame(width: 12, height: 8)
                            
                        }
                        .minimumScaleFactor(0.7)
                        .padding(.top, 2)
                        
                    }
                    .position(x: reader.size.width / 2, y: reader.size.height / 2)
                    .padding(.top, 10)
                    
                }
                
                PieChartPiece
                    .frame(width: reader.size.width / 2, height: reader.size.height / 2)
                    .padding(.top, 8)
                    .rotationEffect(Angle(degrees: -90))
            }
        }
    }
    
    private var PieChartPiece: some View {
        GeometryReader { reader in
            
            let portfolio = getPortfolio()
            
            ZStack {
                
                ForEach(0..<(portfolio?.isEmpty ?? true ? 1 : portfolio?.count ?? 0), id: \.self) { i in
                    
                    let from = portfolio?.isEmpty ?? true ? 0.0 : WidgetReloadService.shared.from(index: i, portfolio: portfolio)
                    let to = portfolio?.isEmpty ?? true ? 360.0 : WidgetReloadService.shared.to(index: i, portfolio: portfolio)
                    
                    ZStack {
                        
                        CryptoWidgetExtension.PieChartPiece(from: from, to: to)
                            .fill(Color(hex: portfolio?[safely: i]?.color ?? Color.onSurfaceDim.hexStringFromColor()))
                        
                    }
                    
                }
            }
        }
    }
    
    private var dataGraph: some View {
        let portfolio = getPortfolio()
        
        return VStack(alignment: .leading, spacing: 5) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .leading,
                spacing:5,
                pinnedViews: [],
                content: {
                    
                    Text("SYMBOL")
                        .fixedSize()
                    
                    Spacer()
                    
                    Text("BALANCE")
                        .fixedSize()
                    
                    Spacer()
                    
                    Text("VALUE")
                        .fixedSize()
                    
                    Spacer()
                    
                    Text("P/L")
                        .fixedSize()
                    
                    Spacer()
                    
                    Text("RATIO %")
                        .fixedSize()
                })
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 25))
            
            Separator()
            
            ForEach (0..<(portfolio?.isEmpty ?? true ? 4 : portfolio?.count ?? 4), id: \.self) { index in
                
                GeometryReader { reader in
                    
                    LazyVGrid(
                        
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        alignment: .leading,
                        spacing: 5,
                        pinnedViews: [],
                        content: {
                            
                            let portfolioItem = portfolio?[safely: index]
                            
                            HStack(alignment: .center, spacing: 5) {
                                
                                Rectangle()
                                    .foregroundColor(Color(hex: portfolioItem?.color ?? Color.onSurfaceDim.hexStringFromColor()))
                                    .frame(minWidth: 2, maxWidth: 2, minHeight: 0, maxHeight: .infinity, alignment: .center)
                                    .opacity(portfolioItem?.data?.symbol == nil ? 0 : 1)
                                
                                Text(portfolioItem?.data?.symbol?.uppercased() ?? "")
                                
                            }
                            .frame(width: reader.size.width / 5, height: reader.size.height, alignment: .leading)
                            
                            Spacer()
                            
                            Text("\(portfolioItem?.data?.name != nil ? ("\((portfolioItem?.getAmount() ?? 0).formatCurrency(threshold: .thousand, currency: CurrencyModel.empty))") : "-")")
                                .foregroundColor(.onSurface)
                                .opacity(portfolioItem?.data?.symbol == nil ? 0 : 1)
                                .frame(width: reader.size.width / 5, height: reader.size.height, alignment: .leading)
                            
                            Spacer()
                            
                            Text(getPieValue(pie: portfolioItem))
                                .opacity(portfolioItem?.data?.symbol == nil ? 0 : 1)
                                .frame(width: reader.size.width / 5, height: reader.size.height, alignment: .leading)
                            
                            Spacer()
                            
                            Text(getChangeValue(pie: portfolioItem))
                                .frame(width: reader.size.width / 5, height: reader.size.height, alignment: .leading)
                                .opacity(portfolioItem?.data?.symbol == nil ? 0 : 1)
                                .foregroundColor(getChangeColor(pie: portfolio?[safely: index]))
                            
                            Spacer()
                            
                            Text("\(String(format: "%.2f", (portfolioItem?.percent ?? 0) * 100))%")
                                .opacity(portfolioItem?.data?.symbol == nil ? 0 : 1)
                                .frame(width: reader.size.width / 5, height: reader.size.height, alignment: .leading)
                            
                        })
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 25))
                        .minimumScaleFactor(0.7)
                }
                
                if index != 3 {
                    Separator()
                }
            }
        }
        .foregroundColor(.onSurface)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .font(.regularWidget10)
    }
    
    func getSign(pie: Pie?) -> String {
        let currentPrice = getCurrentPrice(pie: pie)
        let showCurrency = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
        return (pie?.getProfitValue(prices: currentPrice, showCurrency: showCurrency) ?? 0) > 0 ? "+" :  abs(pie?.getProfitValue(prices: currentPrice, showCurrency: showCurrency) ?? 0) < 0.0000001 ? "" : "-"
    }
    
    func getChangeValue(pie: Pie?) -> String {
        let showInPercent = true
        
        if pie?.data?.symbol == "Other" {
            let array = Array(entry?.pieModel[3..<(entry?.pieModel.count ?? 0)] ?? [])
            
            if showInPercent {
                let showCurrency = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                let value = WidgetReloadService.shared.getPortfolioProfitLossPercent(of: array, totalValue: pie?.value ?? 0, coinPrices: entry?.allPrices ?? [], showCurrency: showCurrency)
                let sign = value > 0 ? "+" :  abs(value) < 0.0000001 ? "" : "-"
                return "\(sign)\(value.getPriceWithSymbol())%"
            } else {
                let value = WidgetReloadService.shared.getPortfolioProfitLossValue(of: array, coinPrices: entry?.allPrices ?? [], showCurrency: (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code)
                let sign = value ?? 0 > 0 ? "+" :  abs(value ?? 0) < 0.0000001 ? "" : "-"
                return "\(sign)\(value?.formatCurrency(threshold: .tenThousand) ?? "")"
            }
        } else {
            let prices = entry?.allPrices.first(where: { $0.id == pie?.data?.id })?.prices
            let sign = getSign(pie: pie)
            
            if showInPercent {
                let showCurrency = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                return "\(sign)\((pie?.getProfitPercent(prices: prices, showCurrency: showCurrency, withTransfers: false) ?? 0.0)?.getPriceWithSymbol() ?? "")%"
            } else {
                let showCurrency = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                return"\(sign)\(pie?.getProfitValue(prices: prices, showCurrency: showCurrency)?.formatCurrency(threshold: .tenThousand) ?? "")"
            }
        }
    }
    
    func getChangeColor(pie: Pie?) -> Color {
        let showInPercent = true
        
        if pie?.data?.symbol == "Other" {
            let array = Array(entry?.pieModel[3..<(entry?.pieModel.count ?? 0)] ?? [])
            
            if showInPercent {
                return WidgetReloadService.shared.getPortfolioProfitLossPercent(of: array, totalValue: pie?.value ?? 0, coinPrices: entry?.allPrices ?? [], showCurrency: (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code).getWidgeWidgetPriceChangeColor(currentPrice: 0)
            } else {
                return WidgetReloadService.shared.getPortfolioProfitLossValue(of: array, coinPrices: entry?.allPrices ?? [], showCurrency: (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code)?.getWidgeWidgetPriceChangeColor(currentPrice: 0) ?? Color.onSurfaceDim
            }
        } else {
            let prices = entry?.allPrices.first(where: { $0.id == pie?.data?.id })?.prices
            let showCurrency = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
            if showInPercent {
                return pie?.getProfitPercent(prices: prices, showCurrency: showCurrency, withTransfers: false)?.getWidgeWidgetPriceChangeColor(currentPrice: 0) ?? .onSurfaceDim
            } else {
                return pie?.getProfitValue(prices: prices, showCurrency: showCurrency)?.getWidgeWidgetPriceChangeColor(currentPrice: 0) ?? .onSurfaceDim
            }
        }
    }
    
    func getCurrentPrice(pie: Pie?) -> [String : Double]? {
        return entry?.allPrices.first(where: { $0.id == pie?.data?.id })?.prices
    }
    
    func getPieNumberValue(pie: Pie?) -> Double {
        let code = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        return (entry?.allPrices.first(where: { $0.id == pie?.data?.id})?.prices[code] ?? 0.0) * (pie?.getAmount() ?? 0.0)
    }
    
    func getPieValue(pie: Pie?) -> String {
        let code = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        
        if pie?.data?.symbol == "Other" {
            return pie?.value?.formatCurrency(threshold: .tenThousand) ?? "0.0"
        }
        
        let price = (entry?.allPrices.first(where: { $0.id == pie?.data?.id})?.prices[code] ?? 0.0) * (pie?.getAmount() ?? 0.0)
        
        return price.formatCurrency(threshold: .tenThousand)
    }
    
    func getPortfolio() -> [Pie]? {
        return WidgetReloadService.shared.getData(of: entry?.pieModel)
    }*/
}
