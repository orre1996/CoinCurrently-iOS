//
//  ScaledBezier.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-02-05.
//

import SwiftUI

struct ScaledBezier: Shape, @unchecked Sendable {
    let bezierPath: UIBezierPath

    func path(in rect: CGRect) -> Path {
        let path = Path(bezierPath.cgPath)

        let transform = CGAffineTransform(scaleX: rect.width, y: rect.height)
        return path.applying(transform)
    }
}
