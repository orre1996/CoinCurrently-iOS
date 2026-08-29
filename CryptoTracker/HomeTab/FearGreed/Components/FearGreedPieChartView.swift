//
//  FearGreedPieChartView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-02.
//

import SwiftUI

struct FearGreedPieChartView: View {
    var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                let from: Double = Double(index) * (55.2 + 1)
                let to: Double = from + 55.2
                let color = isLoading ? .shimmeringBackground.opacity(0.15) : getIndexColor(indexValue: "\((index * 20) + 1)")

                PieChartPiece(from: from, to: to, thickness: 3)
                    .rotation(Angle.init(degrees: 130))
                    .fill(color)

                if isLoading {
                    PieChartPiece(from: from, to: to, thickness: 3)
                        .rotation(Angle.init(degrees: 130))
                        .fill(Color.onSurface.opacity(0.25))
                        .shimmer()
                }
            }
        }
    }
}
