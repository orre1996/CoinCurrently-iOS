//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI

struct NewAlertSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @ScaledMetric private var scale: CGFloat = 1
    
    
    let selectedCoin: CurrencyDataModel?
    
    @State private var headerHeight: CGFloat = 0
    @State private var bodyHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Set Price Alert")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(spacing: 0) {
                    
                }
                .padding(16)
                .readSize {
                    bodyHeight = $0.height
                }
            }
        }
        .presentationDetents([.height(max(1, headerHeight + bodyHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func levelSection(explanation: FearGreedLevelExplanation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                explanation.color
                    .frame(width: 12 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                    .cornerRadius(4)
                    .accessibilityHidden(true)
                
                (Text(explanation.title)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface))
                
                +
                
                (Text(explanation.percent)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDimmer))
                .accessibilityLabel(explanation.percent
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .replacingOccurrences(of: "~", with: " to ")
                )
            }
            
            Text(explanation.body)
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func helpSection(explanation: FearGreedPercentExplanation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            (Text(explanation.title)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface))
            
            +
            
            (Text(explanation.percent)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurfaceDimmer))
            .accessibilityLabel(explanation.percent
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            )
            
            
            Text(explanation.body)
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
        }
        .accessibilityElement(children: .combine)
    }
}

