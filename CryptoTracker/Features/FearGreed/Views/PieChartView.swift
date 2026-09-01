//
//  PieChartView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-31.
//

import SwiftUI

struct PiePiece: Hashable {
    let from: Double
    let to: Double
    let color: Color
}

struct PieChartView: View {
    let piePieces: [PiePiece]
    var thickness: Double = 3
    var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            ForEach(piePieces, id: \.self) { piece in
                let color = isLoading ? .shimmeringBackground.opacity(0.15) : piece.color
                
                PieChartPiece(from: piece.from, to: piece.to, thickness: thickness)
                    .rotation(Angle(degrees: -90))
                    .fill(color)
                
                if isLoading {
                    PieChartPiece(from: piece.from, to: piece.to, thickness: thickness)
                        .rotation(Angle(degrees: -90))
                        .fill(Color.onSurface.opacity(0.25))
                        .shimmer()
                }
            }
        }
    }
}

