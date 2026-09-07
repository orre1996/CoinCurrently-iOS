//
//  PortfolioPieChartLayout.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-28.
//

import CoreGraphics
import Foundation

enum PortfolioPieChartLayout {
    static let innerRadiusRatio: CGFloat = 0.65
    /// Gap width in degrees measured on the outer ring. Inner gap is scaled so arc length matches.
    static let outerGapDegrees: Double = 2.5
    static let minimumSlicePercentage = 0.05
    static let otherSliceId = "portfolio-pie-other"

    static var innerGapDegrees: Double {
        outerGapDegrees / Double(innerRadiusRatio)
    }

    static func slices(
        portfolio: [Pie]?,
        totalValue: Double?,
        pricesById: [String: [String: Double]],
        amountsById: [String: Double],
        currencyCode: String
    ) -> [PortfolioPieSlice] {
        guard let portfolio, let totalValue, totalValue > 0 else {
            return []
        }

        let holdings: [(id: String, symbol: String, name: String, value: Double, color: String?)] = portfolio.compactMap { pie in
            guard pie.shouldShow, let id = pie.data?.id else { return nil }
            guard !portfolio.getAllTransactions(of: id).isEmpty else { return nil }

            let lastPrice = pie.data?.holdingPrice(
                vsCurrencyPrices: pricesById[id],
                currencyCode: currencyCode
            ) ?? 0
            let amount = amountsById[id] ?? 0
            let value = lastPrice * amount
            guard value > 0 else { return nil }

            let symbol = pie.data?.symbol?.uppercased() ?? ""
            return (
                id: id,
                symbol: symbol,
                name: pie.data?.name ?? symbol,
                value: value,
                color: pie.color
            )
        }.sorted { $0.value > $1.value }

        return slices(from: holdings, totalValue: totalValue)
    }

    static func slices(
        from holdings: [(id: String, symbol: String, name: String, value: Double, color: String?)],
        totalValue: Double
    ) -> [PortfolioPieSlice] {
        guard totalValue > 0, !holdings.isEmpty else {
            return []
        }

        let sliceInputs = collapsedSliceInputs(from: holdings, totalValue: totalValue)
        if sliceInputs.count == 1, let slice = sliceInputs.first {
            return [
                PortfolioPieSlice(
                    id: slice.id,
                    symbol: slice.symbol,
                    name: slice.name,
                    percentage: 1,
                    color: slice.color,
                    outerStartAngle: -90,
                    outerEndAngle: 270,
                    innerStartAngle: -90,
                    innerEndAngle: 270
                )
            ]
        }

        let sliceCount = sliceInputs.count
        let effectiveOuterGap = sliceCount > 1 ? outerGapDegrees : 0
        let effectiveInnerGap = sliceCount > 1 ? innerGapDegrees : 0

        let outerAvailable = 360.0 - effectiveOuterGap * Double(sliceCount)
        let innerAvailable = 360.0 - effectiveInnerGap * Double(sliceCount)
        var outerCurrent = -90.0 + effectiveOuterGap / 2
        var innerCurrent = -90.0 + effectiveInnerGap / 2

        let percentages = sliceInputs.map { $0.value / totalValue }
        let visualWeights = visualWeights(from: percentages)

        return zip(sliceInputs, visualWeights).map { slice, visualWeight in
            let percentage = slice.value / totalValue
            let outerStart = outerCurrent
            let outerEnd = outerStart + visualWeight * outerAvailable
            let innerStart = innerCurrent
            let innerEnd = innerStart + visualWeight * innerAvailable
            outerCurrent = outerEnd + effectiveOuterGap
            innerCurrent = innerEnd + effectiveInnerGap

            return PortfolioPieSlice(
                id: slice.id,
                symbol: slice.symbol,
                name: slice.name,
                percentage: percentage,
                color: slice.color,
                outerStartAngle: outerStart,
                outerEndAngle: outerEnd,
                innerStartAngle: innerStart,
                innerEndAngle: innerEnd
            )
        }
    }

    /// With two or fewer coins, always show each holding — never collapse into Other.
    private static func collapsedSliceInputs(
        from holdings: [(id: String, symbol: String, name: String, value: Double, color: String?)],
        totalValue: Double
    ) -> [(id: String, symbol: String, name: String, value: Double, color: String?)] {
        guard holdings.count > 2 else {
            return holdings
        }

        let mainHoldings = holdings.filter { $0.value / totalValue >= minimumSlicePercentage }
        let otherHoldings = holdings.filter { $0.value / totalValue < minimumSlicePercentage }

        var sliceInputs = mainHoldings

        if !otherHoldings.isEmpty {
            let otherValue = otherHoldings.reduce(0) { $0 + $1.value }
            sliceInputs.append((
                id: otherSliceId,
                symbol: "OTHER",
                name: "Other",
                value: otherValue,
                color: nil
            ))
        }

        return sliceInputs
    }

    /// Guarantees each slice is at least `minimumSlicePercentage` of the chart; leftover angle is shared by true weight.
    static func visualWeights(from percentages: [Double]) -> [Double] {
        let minimum = minimumSlicePercentage
        let count = percentages.count
        guard count > 0 else { return [] }

        let reserved = Double(count) * minimum
        guard reserved < 1 else {
            return Array(repeating: 1.0 / Double(count), count: count)
        }

        let remaining = 1 - reserved
        return percentages.map { minimum + $0 * remaining }
    }
}
