//
//  CircularFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-09.
//

import SwiftUI
import WidgetKit

struct CircularFearGreedWidget: View {
    let fearGreedModel: FearGreed?
    
    var body: some View {
        if let url = URL(string: "fearGreed") {
    
            ZStack {
                
                AccessoryWidgetBackground()

                Gauge(value: Double(fearGreedModel?.data?.first?.value ?? "0") ?? 0.0, in: 0...100) {
                    Text(fearGreedModel?.data?.first?.value ?? "0")
                } currentValueLabel: {
                    Text(getIndexStringLockScreen(indexValue: Int(fearGreedModel?.data?.first?.value ?? "") ?? 0))
                }
                .gaugeStyle(.accessoryCircular)
                .padding(4)
            }
            .widgetURL(url)
        }
    }
}

func getIndexStringLockScreen(indexValue: Int) -> String {
    let stringValue: String
    
    if (indexValue <= 40)  { stringValue = "Fear" }
    else if (indexValue <= 60)  { stringValue = "Neutral" }
    else { stringValue = "Greed" }
    
    return stringValue
}
