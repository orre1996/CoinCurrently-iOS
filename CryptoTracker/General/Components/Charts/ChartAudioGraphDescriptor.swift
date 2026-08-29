//
//  ChartAudioGraphDescriptor.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-05-24.
//

import Accessibility
import SwiftUI

struct ChartAudioGraphDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let summary: String?
    let timeStamps: [Double]
    let prices: [Double]
    let comparePrices: [Double]?
    let mainSeriesName: String?
    let compareSeriesName: String?
    let timeChart: TimeCharts
    let dontShowTime: Bool
    let useExchangeDateFormat: Bool
    let yAxisTitle: String
    let valueDescriptionProvider: (Double) -> String
    
    private struct ChartDataPoint {
        let x: Double
        let y: Double
    }
    
    var hasData: Bool {
        !makeChartData(from: prices).isEmpty
    }
    
    func makeChartDescriptor() -> AXChartDescriptor {
        let primaryData = makeChartData(from: prices)
        let yValues = primaryData.map(\.y)
        let minY = yValues.min() ?? 0
        let maxY = yValues.max() ?? 1
        let xValues = primaryData.map(\.x)
        let minX = xValues.min() ?? 0
        let maxX = xValues.max() ?? 1
        
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Time",
            range: minX...maxX,
            gridlinePositions: [],
            valueDescriptionProvider: formattedX
        )
        
        let yAxis = AXNumericDataAxisDescriptor(
            title: yAxisTitle,
            range: minY...max(maxY, minY + 1),
            gridlinePositions: [],
            valueDescriptionProvider: valueDescriptionProvider
        )
        
        var series = [
            AXDataSeriesDescriptor(
                name: mainSeriesName ?? yAxisTitle,
                isContinuous: true,
                dataPoints: makeAXDataPoints(from: primaryData)
            )
        ]
        
        if let comparePrices {
            let compareData = makeChartData(from: comparePrices)
            if !compareData.isEmpty {
                series.append(
                    AXDataSeriesDescriptor(
                        name: compareSeriesName ?? "Compare",
                        isContinuous: true,
                        dataPoints: makeAXDataPoints(from: compareData)
                    )
                )
            }
        }
        
        return AXChartDescriptor(
            title: title,
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: series
        )
    }
    
    private func makeChartData(from values: [Double]) -> [ChartDataPoint] {
        let count = min(timeStamps.count, values.count)
        
        return (0..<count).compactMap { index in
            let value = values[index]
            guard value != -1 else { return nil }
            return ChartDataPoint(x: timeStamps[index], y: value)
        }
    }
    
    private func makeAXDataPoints(from data: [ChartDataPoint]) -> [AXDataPoint] {
        data.map { AXDataPoint(x: $0.x, y: $0.y) }
    }
    
    private func formattedX(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        return date.accessibleChartHoverDate(
            timeChart: timeChart,
            dontShowTime: dontShowTime,
            useExchangeFormat: useExchangeDateFormat
        )
    }
}
