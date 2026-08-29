//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI

struct WidgetsHelpSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var headerHeight: CGFloat = 0
    @State private var bodyHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Widgets Info")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("·")
                        
                        Text("Coin order on the widget follows this list.")
                            .padding(.top, 8)
                    }
                    .accessibilityHidden(true)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("·")
                            .accessibilityHidden(true)
                        
                        Text("Up to 8 coins can be displayed.")
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("·")
                            .accessibilityHidden(true)
                        
                        Text("Tap and hold an empty area on your home screen, tap the edit button on the top left, then select a CoinCurrently widget to add to the screen.")
                    }
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { column in
                            HStack(spacing: 0) {
                                ForEach(1..<3, id: \.self) { row in
                                    Text("\(column * 2 + row)")
                                        .font(.satoshiBold(22))
                                        .foregroundStyle(Color.onSurfaceDim)
                                        .frame(width: 120, height: 60)
                                    
                                    if row == 1 {
                                        VerticalSeparator()
                                    }
                                }
                            }
                            
                            if column != 3 {
                                Separator()
                            }
                        }
                    }
                    .frame(width: 241)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.outlineVariant, lineWidth: 3)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Coin order on the widget follows this grid. Numbers 1 to 8, two numbers per row across four rows. Row 1: 1 and 2. Row 2: 3 and 4. Row 3: 5 and 6. Row 4: 7 and 8."
                    )
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .lineSpacing(4)
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiRegular(16))
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

