//
//  CompareGraphView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-11.
//

import SwiftUI
import Charts

struct CompareGraphView: View {
    let mainPrices: [Double]
    let mainTimestamps: [Double]
    let mainColor: Color
    let showMainGraph: Bool
    let comparePrices: [Double]
    let compareTimestamps: [Double]
    let compareColor: Color
    let showCompareGraph: Bool

    var body: some View {
        ZStack {
            if showMainGraph {
                Chart {
                    ForEach(mainPrices.indices, id: \.self) { index in
                        if let x = mainTimestamps[safely: index], let y = mainPrices[safely: index] {
                            LineMark(x: .value("", x), y: .value("", y))
                                .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(mainColor)
                        }
                    }
                }
            }
            
            if showCompareGraph {
                Chart {
                    ForEach(comparePrices.indices, id: \.self) { index in
                        if let x = compareTimestamps[safely: index], let y = comparePrices[safely: index] {
                            LineMark(x: .value("", x), y: .value("", y))
                             .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(compareColor)
                        }
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartYScale(domain: 0...1)
        .chartXScale(domain: 0...1)
    }
}
