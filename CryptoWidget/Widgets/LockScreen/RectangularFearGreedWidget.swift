//
//  RectangularFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-12.
//

import SwiftUI
import WidgetKit

struct RectangularFearGreedWidget: View {
    @Environment(\.colorScheme) var scheme

    let fearGreedModel: FearGreed?
    let hasBoughtPro: Bool
    
    var body: some View {
        if let url = URL(string: hasBoughtPro ? "fearGreed" : "buyPro") {
            ZStack {
                
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("Day")
                            .fixedSize()
                            .font(.system(size: 10, weight: .semibold))
                        
                        Spacer(minLength: 2)
                        
                        Gauge(value: Double(fearGreedModel?.data?.first?.value ?? "0") ?? 0.0, in: 0...100) {
                            Text(fearGreedModel?.data?.first?.value ?? "0")
                        } currentValueLabel: {
                            Text(getIndexStringLockScreen(indexValue: Int(fearGreedModel?.data?.first?.value ?? "") ?? 0))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .gaugeStyle(.accessoryCircular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack(spacing: 0) {
                        Text("Week")
                            .fixedSize()
                            .font(.system(size: 10, weight: .semibold))
                        
                        Spacer(minLength: 2)
                        
                        let weekValue = fearGreedModel?.data?[safely: 7]
                        
                        Gauge(value: Double(weekValue?.value ?? "0") ?? 0.0, in: 0...100) {
                            Text(weekValue?.value ?? "0")
                        } currentValueLabel: {
                            Text(getIndexStringLockScreen(indexValue: Int(weekValue?.value ?? "") ?? 0))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .gaugeStyle(.accessoryCircular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack(spacing: 0) {
                        Text("Month")
                            .fixedSize()
                            .font(.system(size: 10, weight: .semibold))
                        
                        Spacer(minLength: 2)
                        
                        let monthValue = fearGreedModel?.data?[safely: 30]
                        
                        Gauge(value: Double(monthValue?.value ?? "0") ?? 0.0, in: 0...100) {
                            Text(monthValue?.value ?? "0")
                        } currentValueLabel: {
                            Text(getIndexStringLockScreen(indexValue: Int(monthValue?.value ?? "") ?? 0))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .gaugeStyle(.accessoryCircular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(2)
            }
            .frame(maxHeight: .infinity)
            .widgetURL(url)
            .multilineTextAlignment(.center)
            /*.overlay (
                WidgetBuyProOverlay(
                    hasBoughtPro: hasBoughtPro,
                    fromLockScreen: true
                )
            )*/
        }
    }
}
