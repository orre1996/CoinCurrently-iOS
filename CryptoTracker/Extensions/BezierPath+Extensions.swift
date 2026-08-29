//
//  BezierPath+Extensions.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-24.
//

import Foundation
import SwiftUI

extension UIBezierPath {
    static var priceDownTriangle: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(to: CGPoint(x: 1, y: 0), controlPoint1: CGPoint(x: 1, y: 0), controlPoint2: CGPoint(x: 1, y: 0))
        path.addCurve(to: CGPoint(x: 0.5, y: 1), controlPoint1: CGPoint(x: 0.5, y: 1), controlPoint2: CGPoint(x: 0.5, y: 1))
        path.close()
        return path
    }
    
    static var priceUpTriangle: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 1))
        path.addCurve(to: CGPoint(x: 1, y: 1), controlPoint1: CGPoint(x: 1, y: 1), controlPoint2: CGPoint(x: 1, y: 1))
        path.addCurve(to: CGPoint(x: 0.5, y: 0), controlPoint1: CGPoint(x: 0.5, y: 0), controlPoint2: CGPoint(x: 0.5, y: 0))
        path.close()
        return path
    }
    
    static var priceStillTriangle: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0.25))
        path.addCurve(to: CGPoint(x: 1, y: 0.25), controlPoint1: CGPoint(x: 1, y: 0.25), controlPoint2: CGPoint(x: 1, y: 0.25))
        path.addCurve(to: CGPoint(x: 1, y: 0.75), controlPoint1: CGPoint(x: 1, y: 0.75), controlPoint2: CGPoint(x: 1, y: 0.75))
        path.addCurve(to: CGPoint(x: 0, y: 0.75), controlPoint1: CGPoint(x: 0, y: 0.75), controlPoint2: CGPoint(x: 0, y: 0.75))
        path.close()
        return path
    }
}

