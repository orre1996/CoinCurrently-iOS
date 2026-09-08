//
//  MediumFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-28.
//

import SwiftUI

struct MediumFearGreedWidget: View {
    @Environment(\.colorScheme) var scheme

    let fearGreedModel: FearGreed?
    let hasBoughtPro: Bool
    
    var body: some View {
        if let url = URL(string: hasBoughtPro ? "fearGreed" : "buyPro") {
            
            Link(destination: url) {
                
                HStack(spacing: 0) {
                    
                    ZStack {
                        
                        let thickness: CGFloat = 2.75
                        
                        PieChartPiece(from: 0, to: 55.5, thickness: thickness)
                            .rotation(Angle.init(degrees: 130))
                            .fill(
                                getIndexColor(
                                    indexValue: "0",
                                    for: scheme
                                )
                            )
                        
                        PieChartPiece(from: 56.5, to: 111.5, thickness: thickness)
                            .rotation(Angle.init(degrees: 130))
                            .fill(
                                getIndexColor(
                                    indexValue: "21",
                                    for: scheme
                                )
                            )
                        
                        PieChartPiece(from: 112.5, to: 167.5, thickness: thickness)
                            .rotation(Angle.init(degrees: 130))
                            .fill(
                                getIndexColor(
                                    indexValue: "41",
                                    for: scheme
                                )
                            )
                        
                        PieChartPiece(from: 168.5, to: 223.5, thickness: thickness)
                            .rotation(Angle.init(degrees: 130))
                            .fill(
                                getIndexColor(
                                    indexValue: "61",
                                    for: scheme
                                )
                            )
                        
                        PieChartPiece(from: 224.5, to: 280, thickness: thickness)
                            .rotation(Angle.init(degrees: 130))
                            .fill(
                                getIndexColor(
                                    indexValue: "81",
                                    for: scheme
                                )
                            )
                        
                        FearGreedArrowHomeView()
                            .fill(Color.onSurface(for: scheme))
                            .frame(maxWidth: .infinity, maxHeight: 24)
                            .rotationEffect(Angle.init(degrees: (-49) + (Double(Int(fearGreedModel?.data?.first?.value ?? "0") ?? 0) * 2.8)))
                            .padding(.horizontal, 8)
                        
                        Text(fearGreedModel?.data?.first?.value ?? "0")
                            .font(.system(size: 18))
                            .foregroundColor(Color.onSurface(for: scheme))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        
                    }
                    .padding(16)
                    .offset(y: 2)
                    
                    Rectangle()
                        .frame(minWidth: 1, maxWidth: 1, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        .foregroundStyle(.tertiary)
                    
                    VStack(spacing: 0) {
                        
                        FearSquare(indexValue: fearGreedModel?.data?.first?.value,
                                   timeFrame: "Now",
                                   status: fearGreedModel?.data?.first?.value_classification)
                        .frame(maxHeight: .infinity)
                        
                        Separator()
                        
                        FearSquare(indexValue: fearGreedModel?.data?[safely: 1]?.value,
                                   timeFrame: "Yesterday",
                                   status: fearGreedModel?.data?[safely: 1]?.value_classification)
                        .frame(maxHeight: .infinity)
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                }
                .overlay {
                    if !hasBoughtPro {
                        WidgetBuyProOverlay()
                    }
                }
            }
        }
    }
}

struct FearSquare: View {
    @Environment(\.colorScheme) var scheme
    
    var indexValue: String?
    var timeFrame: String
    var status: String?
    var withPadding = true
    
    @State private var show = false
    
    var body: some View {
        
        HStack(spacing: 2) {
            
            VStack(alignment: .leading, spacing: 7) {
                
                Text(timeFrame + ":")
                    .font(.regular16)
                
                Text(getIndexString(indexValue: indexValue ?? "0") )
                    .font(.regular14)
                
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundColor(Color.onSurface(for: scheme))
            
            Spacer()
            
            ZStack {
                
                Circle()
                    .frame(width: 34, height: 34)
                    .foregroundColor(
                        getIndexColor(
                            indexValue: indexValue ?? "0",
                            for: scheme
                        ).opacity(0.65)
                    )
                
                Text(indexValue ?? "0")
                    .foregroundStyle(Color.onSurface(for: scheme))
                    .font(.regular16)
                    .frame(width: 34, height: 34)
            }
        }
        .padding(withPadding ? 12 : 0)
        .minimumScaleFactor(0.7)
    }
}
