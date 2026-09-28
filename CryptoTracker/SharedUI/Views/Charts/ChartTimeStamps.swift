//
//  ChartTimeStamps.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-09.
//

import SwiftUI

struct ChartTimeStamps: View {
    let currentTimeChart: TimeCharts
    let timeStamps: [Double]
    var accessibilityTexts: [String] = []
    
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        #if IS_WATCH
        let numberOfSteps = 3
        #else
        let numberOfSteps = !Date.uses24HourClock && currentTimeChart <= .aDay ? 4 : 5
        #endif
        
        HStack(alignment: .center, spacing: 4) {
            ForEach(1..<numberOfSteps + 1, id: \.self) { index in
                ShimmeringText(
                    text: getTimeInChart(
                        at: index,
                        numberOfSteps: numberOfSteps
                    ),
                    isDownloading: timeStamps.allSatisfy({ $0 == 0 })
                )
                .foregroundStyle(Color.onSurfaceDimmest)
                .font(.satoshiBold(12))
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(minWidth: 40)
                .accessibilityLabel(accessibilityLabel(at: index, numberOfSteps: numberOfSteps))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .accessibilityHidden(true)
    }
    
    private func accessibilityLabel(at index: Int, numberOfSteps: Int) -> String {
        let valueText = accessibilityTexts[safely: index - 1] ?? ""
        let dateText = getTimeInChartAccessible(at: index, numberOfSteps: numberOfSteps)
        
        return [valueText, dateText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    private func getTimeInChart(
        at index: Int,
        numberOfSteps: Int
    ) -> String {
        guard !timeStamps.isEmpty else { return "00000" }

        let currentIndex = chartAxisTimestampIndex(
            labelIndex: index,
            labelCount: numberOfSteps,
            dataCount: timeStamps.count
        )
        let currentTimeStamp = timeStamps[safely: currentIndex] ?? 0
        
        let date = Date(timeIntervalSince1970: currentTimeStamp / 1000)
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = currentTimeChart.dateFormat
        
        return dateFormatter.string(from: date)
    }
    
    private func getTimeInChartAccessible(
        at index: Int,
        numberOfSteps: Int
    ) -> String {
        guard !timeStamps.isEmpty else { return "" }

        let stampIndex = chartAxisTimestampIndex(
            labelIndex: index,
            labelCount: numberOfSteps,
            dataCount: timeStamps.count
        )
        let currentTimeStamp = timeStamps[safely: stampIndex] ?? 0
        let date = Date(timeIntervalSince1970: currentTimeStamp / 1000)
        
        return date.formatted(date: .abbreviated, time: currentTimeChart <= .aDay ? .standard : .omitted)
    }
}
