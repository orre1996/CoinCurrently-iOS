//
//  PieChartPiece.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-09.
//

import SwiftUI

struct PieChartPiece: Shape {
    var from: Double
    var to: Double
    var thickness: Double = 2.45
    
    func path(in rect: CGRect) -> Path {
        if from > to { return Path() }
        
        var p = Path()
        let a0 = Angle(degrees: from)
        let a1 = Angle(degrees: to)
        let cen =  CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        let r0 = rect.size.width / thickness // Inner
        let r1 = rect.size.width / 2 // Outer
        
        p.addArc(center: cen, radius: r0, startAngle: a0, endAngle: a1, clockwise: false)
        p.addArc(center: cen, radius: r1, startAngle: a1, endAngle: a0, clockwise: true)
        p.closeSubpath()
        
        return p
    }
}
