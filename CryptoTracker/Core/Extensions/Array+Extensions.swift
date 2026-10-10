//
//  Array+Extensions.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-12-08.
//

import Foundation
import SwiftUI

infix operator +?: AdditionPrecedence

func +? <T>(lhs: [T]?, rhs: [T]?) -> [T]? {
    guard let lhs = lhs, let rhs = rhs else { return nil }
    return lhs + rhs
}

extension Array {
    subscript(safely index: Int) -> Element? {
        if index < count && index >= 0 {
            return self[index]
        }
        
        return nil
    }
}

extension Array where Element == String {
    var stringSeparatedByComma: String {
        if self.isEmpty {  return "" }
        return String(self.map({ $0 + "," }).joined().dropLast())
    }
}

extension Array where Element == Double {
    var normalized: [Double] {
        guard !self.allSatisfy({ $0 == self.first }) else {
            return self.compactMap({ _ in 0.5 })
        }

        guard let min = self.min(), let max = self.max() else {
            return []
        }

        return self.map({ ($0 - min) / (max - min) })
    }

    var defaultTimeStamps: [Double] {
        guard !self.isEmpty else { return [] }

        let steps: Double = 1.0 / Double(self.count)
        return self.indices.map { Double($0) * steps }.normalized
    }

    var getTrimmedVolume: [Double] {
        var firstNumber = 1

        if self.count >= 100 {
            let count = Double(self.count).roundToHundreds
            let temp = String("\(count)")

            firstNumber = temp.digits.first ?? 0

            if self.count >= 1000 {
                firstNumber *= 10
                firstNumber += temp.digits[1]
            }
        }

        return self.enumerated().compactMap { tuple in
            tuple.offset.isMultiple(of: firstNumber) ? tuple.element : nil
        }
    }

    func normalizedCustom(max: CGFloat, min: CGFloat) -> [Double] {
        return self.map {
            let a = $0 - min
            let b = max - min
            return b == 0 ? 0 : a / b
        }
    }

    func point(at index: Int, rect: CGSize, dropCount: Int = 0) -> CGPoint {
        let normalizedPrices = Array(self.normalized.dropLast(dropCount))
        let point = normalizedPrices[safely: index] ?? 0
        let x = rect.width * CGFloat(index) / CGFloat(normalizedPrices.count - 1)
        let y = (1 - point) * rect.height
        return CGPoint(x: x, y: y.isNaN ? 0.5 * rect.height : y)
    }
}

extension Array where Element == CGFloat {
    var normalized: [CGFloat] {
        if let min = self.min(), let max = self.max() {
            return self.map({ ($0 - min) / (max - min) })
        }
        
        return []
    }
    
    func normalizedCustom(max: CGFloat, min: CGFloat) -> [CGFloat] {
        return self.map({ ($0 - min) / (max - min) })
    }
}

extension Array where Element: Equatable {
    func contains(array: [Element]) -> Bool {
        for item in array {
            if !self.contains(item) { return false }
        }
        return true
    }
}

extension Array where Element == [Double] {
    func highest() -> Double {
        let highest = self.min(by: {$0.last ?? 0.0 > $1.last ?? 0.0})
        return Double(highest?.last ?? 0.0)
    }
    
    func lowest() -> Double {
        let lowest = self.min(by: {$0.last ?? 0.0 < $1.last ?? 0.0})
        return Double(lowest?.last ?? 0.0)
    }
}
