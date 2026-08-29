//
//  Collection+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/24/25.
//

import Foundation

extension Collection where Element == CGFloat, Index == Int {

    /// Calculates a moving average.
    /// - Parameter period: the period to calculate averages for.
    /// - Warning: the supplied `period` must be larger than 1.
    /// - Warning: the supplied `period` should not exceed the collection's `count`.
    /// - Returns: a dictionary of indexes and averages.
    func movingAverage(period: Int) -> [Int: Double] {
        if period < 1 || count < period { return [:] }

        let result = (0..<self.count).compactMap { index -> (Int, Double)? in
            if (0..<period).contains(index) { return nil }
            let range = index - period..<index
            let sum = self[range].reduce(0, +)
            let result = Double(sum) / Double(period)

            return (index, result)
        }
        return Dictionary(uniqueKeysWithValues: result)
    }
}
