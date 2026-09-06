//
//  SmallFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-03-01.
//

import SwiftUI

struct SmallFearGreedWidget: View {
    @Environment(\.colorScheme) var scheme
    
    let fearGreedModel: FearGreed?
    
    private let circleSize: CGFloat = 12
    private let circleOutlinePadding: CGFloat = 2
    private let contentPadding: CGFloat = 16
    
    private var indicatorSize: CGFloat {
        circleSize + (circleOutlinePadding * 2)
    }
    
    var body: some View {
        if let url = URL(string: "fearGreed") {
            VStack(alignment: .leading, spacing: 12) {
                let indexValue = fearGreedModel?.data?.first?.value
                let percent = CGFloat((Double(indexValue ?? "0") ?? 0) / 100)
                
                ShimmeringText(
                    text: indexValue ?? "0",
                    isDownloading: fearGreedModel == nil
                )
                .foregroundStyle(Color.onSurface(for: scheme))
                .font(.satoshiBold(56))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                ShimmeringText(
                    text: fearGreedModel?.data?.first?.value_classification ?? "0",
                    isDownloading: fearGreedModel == nil
                )
                .foregroundStyle(getIndexColor(indexValue: indexValue ?? "0", for: scheme))
                .font(.satoshiBold(12))
                
                GeometryReader { reader in
                    let indicatorOffset = FearGreedMeter.indicatorOffset(
                        containerWidth: reader.size.width,
                        indicatorSize: indicatorSize,
                        percent: percent
                    )
                    
                    ZStack(alignment: .leading) {
                        FearGreedMeter(height: 8)
                            .frame(height: circleSize)
                        
                        Circle()
                            .foregroundStyle(Color.surfaceContainerHighest(for: scheme))
                            .frame(width: circleSize, height: circleSize)
                            .padding(circleOutlinePadding)
                            .background(
                                Circle()
                                    .foregroundStyle(Color.outline(for: scheme))
                            )
                            .offset(x: indicatorOffset)
                    }
                }
                .frame(height: circleSize)
            }
            .padding(contentPadding)
            .widgetURL(url)
        }
    }
}
