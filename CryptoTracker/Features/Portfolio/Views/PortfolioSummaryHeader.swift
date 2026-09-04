//
//  PortfolioSummaryHeader.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import SwiftUI

struct PortfolioSummaryHeader: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    @Bindable var viewModel: PortfolioViewModelImp
    @Binding var isPieChartShowing: Bool
    @Binding var selectedPieSliceId: String?

    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            totalValueView

            HStack(spacing: 16) {
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                    valueChangeView
                    profitLossView
                }
            }
            .padding(
                EdgeInsets(
                    top: 12,
                    leading: 16,
                    bottom: 16,
                    trailing: 16
                )
            )
        }
    }

    @ViewBuilder
    private var totalValueView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Value")
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)

            HStack(alignment: .center, spacing: 8) {
                let totalValue = viewModel.holdings.totalValue?.formatCurrency(
                    threshold: isHorizontal ? FormattingThreshold.billion : FormattingThreshold.thousand
                ) ?? "000000000"

                NewShimmeringText(
                    text: viewModel.hideData ? String.stars : totalValue,
                    isDownloading: viewModel.holdings.totalValue == nil
                )
                .font(.satoshiBold(36))
                .foregroundStyle(Color.onSurface)
                .accessibilityLabel("Portfolio value: \(viewModel.hideData ? String.stars : totalValue)")

                (viewModel.hideData ? Image.unhide : Image.hide)
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(12)
                    .onTapGesture {
                        viewModel.toggleHideData()
                        if viewModel.hideData {
                            AnalyticsManager.shared.log(PortfolioDataHide(fromScreen: .portfolio))
                        } else {
                            AnalyticsManager.shared.log(PortfolioDataShow(fromScreen: .portfolio))
                        }
                    }
                    .accessibilityLabel("\(viewModel.hideData ? "show" : "hide") portfolio data")

                Spacer(minLength: 0)

                pieChartToggleButton
            }
        }
        .animation(.none, value: viewModel.hideData)
        .padding(.horizontal, 16)
    }

    private var pieChartToggleButton: some View {
        Button(action: {
            selectedPieSliceId = nil
            isPieChartShowing.toggle()
            SettingsManager.shared.set(data: isPieChartShowing, key: AppSettingKey.isPortfolioPieChartShowing)
        }, label: {
            (isPieChartShowing ? Image.lineChart : Image.portfolio)
                .resizable()
                .frame(width: 24 * min(1.5, scale), height: 24 * min(1.5, scale))
                .foregroundStyle(Color.onSurface)
                .padding(12)
                .optionalGlassEffect(
                    color: Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                .accessibilityLabel("Switch to \(isPieChartShowing ? "line chart" : "pie chart")")
                .accessibilityAddTraits(.isToggle)
        })
    }

    @ViewBuilder
    private var valueChangeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Value Change (7d)")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)

            OverflowLayout(spacing: 4) {
                if viewModel.hideData {
                    HStack(spacing: 4) {
                        NewShimmerImageDirection(
                            change: 0,
                            size: .medium,
                            isDownloading: viewModel.changePercent == nil
                        )

                        Text(String.stars)
                            .font(.satoshiBold(14))
                            .foregroundStyle(Color.onSurfaceDim)
                    }
                } else {
                    NewPriceChangeValueView(
                        change: viewModel.changeValue,
                        size: .small,
                        accessibleTimeframe: "7 days",
                        isDownloading: viewModel.changeValue == nil
                    )
                }

                let formattedChange = (viewModel.changePercent ?? 0).formatted(
                    isHorizontal
                    ? .number.notation(.compactName).precision(.fractionLength(2))
                    : .number.precision(.fractionLength(2))
                ).changeWithSymbol

                NewShimmeringText(
                    text: "(\(((viewModel.changePercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? "-" : (formattedChange + "%")))",
                    isDownloading: viewModel.changePercent == nil
                )
                .foregroundStyle((viewModel.changePercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true) ? Color.onSurfaceDim : viewModel.hideData ? Color.onSurfaceDim : viewModel.changePercent?.changeColor ?? .onSurfaceDim)
                .font(.satoshiBold(14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            portfolioChangeAccessibilityLabel(
                title: "7 days value change",
                value: viewModel.changeValue,
                percent: viewModel.changePercent
            )
        )
    }

    @ViewBuilder
    private var profitLossView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profit/Loss")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)

            OverflowLayout(spacing: 4) {
                if viewModel.hideData {
                    HStack(spacing: 4) {
                        NewShimmerImageDirection(
                            change: 0,
                            size: .medium,
                            isDownloading: viewModel.holdings.profitLossValue == nil
                        )

                        Text(String.stars)
                            .font(.satoshiBold(14))
                            .foregroundStyle(Color.onSurfaceDim)
                    }
                } else {
                    NewPriceChangeValueView(
                        change: viewModel.holdings.profitLossValue,
                        size: .small,
                        hideData: viewModel.hideData,
                        accessibleTimeframe: "",
                        isDownloading: viewModel.holdings.profitLossValue == nil
                    )
                }

                let formattedChange = (viewModel.holdings.profitLossPercent ?? 0).formatted(
                    isHorizontal
                    ? .number.notation(.compactName).precision(.fractionLength(2))
                    : .number.precision(.fractionLength(2))
                ).changeWithSymbol

                NewShimmeringText(
                    text: "(\(((viewModel.holdings.profitLossPercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? "-" : (formattedChange + "%")))",
                    isDownloading: viewModel.holdings.profitLossPercent == nil
                )
                .foregroundStyle(((viewModel.holdings.profitLossPercent?.isInfinite ?? true) || (viewModel.portfolio?.isEmpty ?? true)) ? Color.onSurfaceDim : viewModel.holdings.profitLossPercent?.changeColor ?? .onSurfaceDim)
                .font(.satoshiBold(14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            portfolioChangeAccessibilityLabel(
                title: "Profit/Loss",
                value: viewModel.holdings.profitLossValue,
                percent: viewModel.holdings.profitLossPercent
            )
        )
    }

    private func portfolioChangeAccessibilityLabel(
        title: String,
        value: Double?,
        percent: Double?
    ) -> String {
        let isEmpty = viewModel.portfolio?.isEmpty ?? true
        let changePercent = isEmpty ? 0 : (percent ?? 0)
        let safeChange = changePercent.isInfinite ? 0 : changePercent
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        let percentText = "\(direction) \(accessiblePercent) percent"

        if viewModel.hideData {
            return "\(title), \(percentText)"
        }

        let changeValue = isEmpty ? 0 : (value ?? 0)
        let valueDirection = changeValue.directionAccessible.lowercased()
        let valueText = abs(changeValue).formatAccessibleCurrency()

        return "\(title), \(valueDirection) \(valueText), \(percentText)"
    }
}
