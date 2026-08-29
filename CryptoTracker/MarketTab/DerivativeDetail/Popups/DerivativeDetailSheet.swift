//
//  EditWidgetsSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/26/25.
//

import SwiftUI

struct DerivativeDetailSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    let derivativeDetail: DerivativeDetail
    let multiplier: Double?
    let imageUrl: String?
    let hasToplist: Bool
    let exchangeName: String
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandler()
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 0,
                        bottom: 24,
                        trailing: 0
                    )
                )
            
            HStack(spacing: 0) {
                headerView
                
                Spacer(minLength: 16)

                CloseButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        priceView
                        
                        if !isHorizontal {
                            Separator()
                        }
                        
                        changeView
                    }
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        openInterestView
                        
                        if !isHorizontal {
                            Separator()
                        }
                        
                        volumeView
                    }
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        fundingRateView
                        
                        if !isHorizontal {
                            Separator()
                        }
                        
                        indexPriceView
                    }
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        indexBasisView
                        
                        if !isHorizontal {
                            Separator()
                        }
                        
                        bidSpreadView
                    }
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        contractTypeView
                        
                        if !isHorizontal {
                            Separator()
                        }
                        
                        exchangeView
                    }
                    
                    if !isHorizontal {
                        Separator()
                    }
                    
                    AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                        lastTradedView
                        
                        if !isHorizontal && derivativeDetail.contract_type == "Future" {
                            Separator()
                        }
                        
                        if derivativeDetail.contract_type == "Future" {
                            expiryView
                        }
                    }
                }
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0) {
                Separator()
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 16,
                            bottom: 0,
                            trailing: 16
                        )
                    )

                actionButtons
            }
            .readSize {
                buttonsHeight = $0.height
            }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight + 40 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            if hasToplist && imageUrl == nil {
                Circle()
                    .strokeBorder(Color.outlineVariant, lineWidth: 1)
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .accessibilityHidden(true)
            } else {
                ShimmeringImage(
                    imageUrl: imageUrl,
                    downloading: imageUrl == nil,
                    size: 24 * min(scale, 1.5)
                )
                .accessibilityHidden(true)
            }
            
            Text(derivativeDetail.symbol ?? "")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(22))
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(derivativeDetail.symbol?.map({ "\($0)" }).joined(separator: " ") ?? "")
        }
    }
    
    @ViewBuilder
    private func statView(
        title: String,
        titleAccessible: String? = nil,
        value: String,
        valueAccessible: String? = nil
    ) -> some View {
        let accessibleTitle = titleAccessible ?? title
        
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(valueAccessible != nil)
            
            Text(value)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityHidden(valueAccessible != nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .if(valueAccessible != nil) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(accessibleTitle): \(valueAccessible ?? "")")
        }
        .if(valueAccessible == nil) { view in
            view.accessibilityElement(children: .combine)
        }
    }
    
    private var priceView: some View {
        let lastPrice = (Double(derivativeDetail.converted_last?.usd ?? "0") ?? 0) * (multiplier ?? 0)
        
        return statView(
            title: "Price",
            value: lastPrice.formatCurrency(threshold: FormattingThreshold.none),
            valueAccessible: lastPrice.currencyAccessible()
        )
    }
    
    private var changeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("24h Price Change")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            NewPriceChangePercentView(
                change: derivativeDetail.h24_percentage_change,
                accessibleTimeframe: "24 hour",
                isDownloading: false
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var openInterestView: some View {
        let openInterest = (derivativeDetail.open_interest_usd ?? 0) * (multiplier ?? 0)
        
        return statView(
            title: "Open Interest",
            value: openInterest.formatCurrency(),
            valueAccessible: openInterest.formatCurrency(accessible: true)
        )
    }
    
    private var volumeView: some View {
        let volume = (Double(derivativeDetail.converted_volume?.usd ?? "0") ?? 0) * (multiplier ?? 0)
        
        return statView(
            title: "24h Volume",
            titleAccessible: "24 hour volume",
            value: volume.formatCurrency(),
            valueAccessible: volume.formatCurrency(accessible: true)
        )
    }
    
    private var fundingRateView: some View {
        let rate = derivativeDetail.funding_rate ?? 0
        let formattedRate = rate.formatted(.number.precision(.fractionLength(2...7)))
        
        return statView(
            title: "Funding Rate",
            value: "\(formattedRate)%",
            valueAccessible: "\(rate.numberAccessible(maxPlaces: 7)) percent"
        )
    }
    
    private var indexPriceView: some View {
        let currency = CurrencyModel(
            currency: " \(derivativeDetail.target ?? "")",
            code: " \(derivativeDetail.target ?? "")",
            symbol: " \(derivativeDetail.target ?? "")",
            suffix: true
        )
        let index = derivativeDetail.index ?? 0
        
        return statView(
            title: "Index Price",
            value: index.formatCurrency(threshold: FormattingThreshold.none, currency: currency),
            valueAccessible: index.currencyAccessible(currency: currency)
        )
    }
    
    private var indexBasisView: some View {
        let basis = derivativeDetail.index_basis_percentage ?? 0
        let formattedBasis = derivativeDetail.index_basis_percentage?.formattedRemovingTrailingZeros() ?? "0"
        
        return statView(
            title: "Index Basis %",
            titleAccessible: "Index basis percent",
            value: "\(formattedBasis)%",
            valueAccessible: "\(basis.numberAccessible()) percent"
        )
    }
    
    private var bidSpreadView: some View {
        let spread = derivativeDetail.bid_ask_spread
        let formattedSpread = spread?.formatted(.number.precision(.fractionLength(2...7))) ?? "-"
        
        return statView(
            title: "Bid Ask Spread",
            value: "\(formattedSpread)%",
            valueAccessible: spread.map { "\($0.numberAccessible(maxPlaces: 7)) percent" } ?? "Not available"
        )
    }
    
    private var contractTypeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Contract Type")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            Text(derivativeDetail.contract_type?.capitalized ?? "")
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private var exchangeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Exchange")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            Text(exchangeName)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private var expiryView: some View {
        let expiresIn = derivativeDetail.expired_at?.timeUntilExpired ?? "-"
        let accessibleExpiry: String = {
            if expiresIn == "Expired" { return "expired" }
            if expiresIn == "-" { return "Not available" }
            return "expires in \(expiresIn)"
        }()
        
        return statView(
            title: "Expires",
            value: expiresIn,
            valueAccessible: accessibleExpiry
        )
    }
    
    private var lastTradedView: some View {
        let lastTraded = derivativeDetail.last_traded.map { Date(timeIntervalSince1970: $0).timeAgoDisplay } ?? "-"
        
        return statView(
            title: "Last Traded",
            value: lastTraded,
            valueAccessible: lastTraded == "-" ? "Not available" : lastTraded
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: "View Exchange",
                icon: .external,
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    if let urlString = derivativeDetail.trade_url, let url = URL(string: urlString) {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .derivativeDetail, url: urlString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
}
