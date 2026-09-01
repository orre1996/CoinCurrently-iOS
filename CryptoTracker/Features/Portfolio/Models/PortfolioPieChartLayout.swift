//
//  PortfolioPieChartLayout.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-28.
//

import CoreGraphics

enum PortfolioPieChartLayout {
    static let innerRadiusRatio: CGFloat = 0.65
    /// Gap width in degrees measured on the outer ring. Inner gap is scaled so arc length matches.
    static let outerGapDegrees: Double = 2.5
    static let minimumSlicePercentage = 0.05
    static let otherSliceId = "portfolio-pie-other"

    static var innerGapDegrees: Double {
        outerGapDegrees / Double(innerRadiusRatio)
    }
}
