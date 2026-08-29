//
//  VolumeLineChart.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-26.
//

import SwiftUI
import WidgetKit

struct VolumeLineChart: View {
    @Environment(\.colorScheme) var scheme

    var volumes: [Double]
    var tempVolumes: Bool = false
    var fromCandleChart: Bool = false
    
    @State private var randomPoints = [Double]()
    
    var body: some View {
        HStack(alignment: .center, spacing: 1, content: {
            if !volumes.isEmpty {
                ForEach(0..<volumes.count, id: \.self) { number in
                    GeometryReader { proxy in
                        Rectangle()
                            .frame(width: max(0, proxy.size.width), height: max(0, volumes[number] * proxy.size.height + 1), alignment: .center)
                    }
                    .foregroundColor(tempVolumes ? Color.onSurfaceDim(for: scheme) : getCandleColor(a: volumes[safely: number - 1], b: volumes[safely: number], scheme: scheme))
                    .rotationEffect(.radians(.pi))
                }
            } else {
                ForEach(0..<randomPoints.count, id: \.self) { number in
                    GeometryReader { proxy in
                        Rectangle()
                            .frame(width: proxy.size.width, height: randomPoints[number] * proxy.size.height + 1, alignment: .center)
                    }
                    .foregroundColor(Color.onSurfaceDim(for: scheme))
                    .rotationEffect(.radians(.pi))
                }
            }
        })
        .onAppear {
            randomPoints = getRandomPoints()
        }
    }
    
    func getRandomPoints() -> [Double] {
        var pointsArray: [Double] = []
        var previousValue = Double.random(in: 0.1...0.9)
        
        for _ in (0..<80) {
            previousValue = Double.random(in: max(0.1, (previousValue - 0.01))...min((previousValue + 0.01), 0.9))
            pointsArray.append(previousValue)
        }
        
        return pointsArray.normalized
    }
    
    func getCandleColor(a: Double?, b: Double?, scheme: ColorScheme) -> Color {
        if b ?? 0 < a ?? 0 {
            return Color.trendDown(for: scheme)
        } else {
            return Color.trendUp(for: scheme)
        }
    }
}
