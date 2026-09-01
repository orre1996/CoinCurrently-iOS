//
//  PortfolioTransactionCell.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-21.
//

import SwiftUI

struct PortfolioTransactionCell: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1
    
    let transaction: Transaction
    let cryptoInfo: CurrencyDataModel?
    let transactionType: TransactionType
    let transferType: TransferType
    let currentPrice: Double
    let showInPercent: Bool
    let selectedCurrency: CurrencyModel
    let isRefreshingAddress: Bool
    
    @Binding var expandedTransaction: Transaction
    
    var editTransaction: () -> Void
    var deleteTransaction: () -> Void
    var refreshAddress: () async -> Void

    @AccessibilityFocusState private var focusPricePerCoin

    var body: some View {
        /*let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        let isExpanded = expandedTransaction.id.uuidString == transaction.id.uuidString
        let spacing: CGFloat = isHorizontal ? 16 : 12

        VStack(spacing: 12) {
            let verticalAlignment: VerticalAlignment = transactionType == .transfer || isExpanded ? .center : .top

            AdaptiveStack(isHorizontal: isHorizontal || !isExpanded, spacing: spacing, horizontalAlignment: .leading, verticalAlignment: verticalAlignment) {
                headerView
                
                if isExpanded {
                    expandedView
                } else {
                    notExpandedView
                }
            }
            .frame(minHeight: 44)
            
            if isExpanded {
                VStack(spacing: 12) {
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: spacing, horizontalAlignment: .leading, verticalAlignment: .top) {
                        valueView

                        amountView
                    }

                    if transactionType == .buy || transactionType == .sell {
                        AdaptiveStack(isHorizontal: isHorizontal, spacing: spacing, horizontalAlignment: .leading, verticalAlignment: .top) {
                            pricePerCoinView
                            
                            profitLossView
                        }
                    }
                    
                    if !(transactionType == .transfer && transferType == .inType) && transactionType != .importAddress {
                        AdaptiveStack(isHorizontal: isHorizontal, spacing: spacing, horizontalAlignment: .leading, verticalAlignment: .top) {
                            spentView
                            
                            feesView
                        }
                    }
                    
                    noteView
                }
                .accessibilitySortPriority(2)
            } else {
                expandView
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(CardBackground())
        .multilineTextAlignment(.center)
        .animation(.default, value: UUID())
        .onTapGesture {
            expandedTransaction = transaction
            
            asyncMain(delay: 0.5) {
                focusPricePerCoin = true
            }
        }*/
    }
    
    /*private var headerView: some View {
        HStack(spacing: 16) {
            transaction.getTransactionImage(transactionType: transactionType, transferType: transferType)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                .foregroundColor(transaction.getTransactionTypeTextColor(transactionType: transactionType, transferType: transferType))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                let transactionTypeText = transaction.getTransactionTypeText(transactionType: transactionType, transferType: transferType)

                Text(transactionTypeText)
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Type: \(transactionTypeText)")
                    .accessibilitySortPriority(13)

                let address = transaction.address ?? ""
                let date = transaction.date.formatted(date: .abbreviated, time: .omitted)
                let isImport = transactionType == .importAddress
                let title = isImport ? address : date
                let accessibleText = isImport ? "Address: \(address.symbolAccessible)" : "Date: \(date)"

                Text(title)
                    .foregroundColor(.primarySubtitleColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(accessibleText)
                    .accessibilitySortPriority(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .font(.poppinsRegular(14))
        }
        .accessibilitySortPriority(3)
    }
    
    @ViewBuilder
    private var expandedView: some View {
        let size: CGFloat = 20 * min(scale, 1.5)

        HStack(spacing: 16) {
            if transactionType == .importAddress {
                if isRefreshingAddress {
                    ActivityIndicator(size:size)
                        .padding(4)
                        .accessibilityLabel("Syncing address")
                        .accessibilitySortPriority(3)
                } else {
                    Button(action: {
                        Task {
                            await refreshAddress()
                        }
                    }, label: {
                        Image.refresh
                            .resizable()
                            .frame(width: size, height: size)
                            .scaledToFit()
                            .padding(4)
                    })
                    .accessibilityLabel("Sync address")
                    .accessibilitySortPriority(3)
                }
            }
            
            Button(action: {
                editTransaction()
            }, label: {
                Image.pencil
                    .resizable()
                    .frame(width: size, height: size)
                    .scaledToFit()
                    .padding(4)
            })
            .accessibilityLabel("Edit transaction")
            .accessibilitySortPriority(2)
            
            Button(action: {
                deleteTransaction()
            }, label: {
                Image.trashFill
                    .resizable()
                    .frame(width: size, height: size)
                    .scaledToFit()
                    .padding(4)
            })
            .accessibilityLabel("Delete transaction")
            .accessibilitySortPriority(1)
        }
        .foregroundColor(.onSurface)
        .accessibilitySortPriority(1)
    }
    
    @ViewBuilder
    private var notExpandedView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            let currentPrice = currentPrice
            let amount = transaction.amount
            let formattedTotalValue = (currentPrice * amount).getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency)
            let accessibleTotalValue = (currentPrice * amount).formatCurrency(accessible: true, currency: selectedCurrency)
            
            if transactionType != .transfer {
                Text(formattedTotalValue)
                    .font(.poppinsSemibold(14))
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Value: \(accessibleTotalValue)")
                    .accessibilitySortPriority(11)
            }

            let prefixSign = transaction.getTransactionPrefixSign(transactionType: transactionType, transferType: transferType)
            let formattedAmount = amount.getFormattedStringNoCurrencyPortfolioAmount()
            let accessibleAmount = amount.numberAccessible()
            let symbol = cryptoInfo?.symbol?.uppercased() ?? ""
            let transactionColor = transaction.getTransactionTypeTextColor(transactionType: transactionType, transferType: transferType)
            
            Text("\(prefixSign)\(formattedAmount) \(symbol)")
                .font(.poppinsSemibold(14))
                .foregroundColor(transactionColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Amount: \(accessibleAmount) \(symbol.symbolAccessible)")
                .accessibilitySortPriority(10)
        }
        .multilineTextAlignment(.trailing)
        .accessibilitySortPriority(2)
    }
    
    @ViewBuilder
    private var valueView: some View {
        let totalValue = currentPrice * transaction.amount
        let formattedTotalValue = totalValue.getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency)
        let accessibleTotalValue = totalValue.formatCurrency(accessible: true, currency: selectedCurrency)

        VStack(alignment: .leading, spacing: 2) {
            Text("Value")
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)
    
            ShimmeringText(text: formattedTotalValue,
                           font: .poppinsSemibold(14),
                           color: .onSurface,
                           downloading: cryptoInfo?.market_data?.current_price == nil)
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilitySortPriority(9)
        .accessibilityLabel("Value: \(accessibleTotalValue)")
    }
    
    @ViewBuilder
    private var amountView: some View {
        let amount = transaction.amount
        let formattedAmount = amount.getFormattedStringNoCurrencyPortfolioAmount()
        let accessibleAmount = amount.numberAccessible()
        let amountPrefix = transaction.getTransactionPrefixSign(transactionType: transactionType, transferType: transferType)
        let amountColor = transaction.getTransactionTypeTextColor(transactionType: transactionType, transferType: transferType)
        let symbol = cryptoInfo?.symbol?.uppercased() ?? ""

        VStack(alignment: .leading, spacing: 2) {
            Text("Amount")
                .font(.poppinsRegular(12))
                .foregroundColor(Color.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(amountPrefix)\(formattedAmount) \(symbol)")
                .font(.poppinsSemibold(14))
                .foregroundColor(amountColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilitySortPriority(8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amount: \(accessibleAmount) \(symbol.symbolAccessible)")
    }
    
    @ViewBuilder
    private var pricePerCoinView: some View {
        let pricePerCoin = transaction.pricePerCoin
        let formattedPricePerCoin = pricePerCoin?.getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency) ?? "N/A"
        let accessiblePricePerCoin = pricePerCoin?.formatCurrency(accessible: true, currency: selectedCurrency) ?? ""
    
        VStack(alignment: .leading, spacing: 2) {
            Text("Price per coin")
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(formattedPricePerCoin)
                .font(.poppinsSemibold(14))
                .foregroundColor(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilitySortPriority(7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Price per coin: \(accessiblePricePerCoin)")
        .accessibilityFocused($focusPricePerCoin)
    }
    
    @ViewBuilder
    private var profitLossView: some View {
        let percentChange = transactionType == .sell ? nil : transaction.getProfitPercent(currentPrice: currentPrice)
        let changeColor = percentChange?.getPriceChangeColor(currentPrice: currentPrice, forceShowPercent: showInPercent) ?? .onSurface
        let formattedPercent = percentChange?.getPriceWithSymbol(forceShowPercent: showInPercent) ?? "N/A"
        let accessiblePercent = "\(percentChange ?? 0 < 0 ? "down" : "up") \(percentChange?.numberAccessible() ?? "") percent"
        
        let profitValue = transaction.getProfitValue(currentPrice: currentPrice) ?? 0
        let valueColor = profitValue.getPriceChangeColorInPortfolio()
        let formattedValue = profitValue.getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency, fromPriceChange: true)
        let accessibleValue = "\(profitValue.roundTo(places: abs(profitValue) < 1 ? 7 : 4) < 0 ? "down" : "up") \(profitValue.formatCurrency(accessible: true, currency: selectedCurrency))"

        VStack(alignment: .leading, spacing: 2) {
            Text("Profit/Loss")
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 4) {
                if transactionType != .transfer {
                    ShimmeringText(text: percentChange == nil ? "N/A" : showInPercent ? "\(formattedPercent)%" : formattedValue,
                                   font: .poppinsSemibold(14),
                                   color: percentChange == nil ? .onSurfaceDim : showInPercent ? changeColor : valueColor,
                                   downloading: cryptoInfo?.market_data?.current_price == nil)
                    
                    if let percentChange, transactionType != .sell {
                        if cryptoInfo?.market_data?.current_price == nil {
                            ShimmeringBezierPath(priceChange: showInPercent ? percentChange : profitValue,
                                                 currentPrice: currentPrice,
                                                 forceShowPercent: showInPercent,
                                                 fontSize: 14,
                                                 downloading: true)
                            .animation(.none, value: showInPercent)
                        } else {
                            ScaledBezier(bezierPath:
                                showInPercent ? percentChange.getPriceDirectionShape(currentPrice: currentPrice) : profitValue.getPriceDirectionShapePortfolio(currentPrice: currentPrice)
                            )
                            .fill(showInPercent ? changeColor : valueColor)
                            .frame(width: 14 * min(scale, 1.5), height: 10 * min(scale, 1.5))
                            .animation(.none, value: showInPercent)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilitySortPriority(6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Profit loss: \(percentChange == nil ? "Not applicable" : showInPercent ? accessiblePercent : accessibleValue)")
    }
    
    @ViewBuilder
    private var spentView: some View {
        let transactionText = transaction.getTransactionText(transactionType: transactionType, transferType: transferType)
        let totalSpent = transaction.getTotalSpent(transactionType: transactionType)
        let formattedTotalSpent = totalSpent.getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency)
        let accessibleTotalSpent = totalSpent.formatCurrency(accessible: true, currency: selectedCurrency)

        VStack(alignment: .leading, spacing: 2) {
            Text(transactionText)
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(formattedTotalSpent)")
                .font(.poppinsSemibold(14))
                .foregroundColor(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilitySortPriority(5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(transactionText): \(accessibleTotalSpent)")
    }
    
    @ViewBuilder
    private var feesView: some View {
        let fee = transaction.fee ?? 0
        let formattedFee = fee.getFormattedString(fromMillion: true, selectedCurrency: selectedCurrency)
        let accessibleFee = fee.formatCurrency(accessible: true, currency: selectedCurrency)

        VStack(alignment: .leading, spacing: 2) {
            Text("Fee")
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .fixedSize(horizontal: false, vertical: true)

            if !(transactionType == .transfer && transferType == .inType) {
                Text(formattedFee)
                    .font(.poppinsSemibold(14))
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .accessibilitySortPriority(4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fee: \(accessibleFee)")
    }

    private var noteView: some View {
        VStack(spacing: 2) {
            Text("Note")
                .font(.poppinsRegular(12))
                .foregroundColor(.primarySubtitleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let note = transaction.note, !note.isEmpty {
                Text(note)
                    .font(.poppinsSemibold(14))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilitySortPriority(3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Note: \(transaction.note ?? "")")
    }
    
    private var expandView: some View {
        Image.chevronUp
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.onSurface)
            .scaledToFill()
            .frame(width: 16 * min(scale, 1.5), height: 8 * min(scale, 1.5))
            .rotationEffect(.init(degrees: 180))
            .accessibilityLabel("Expand transaction for more information")
            .accessibility(addTraits: .isButton)
            .accessibilitySortPriority(1)
    }*/
}
