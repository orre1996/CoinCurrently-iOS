//
//  Sequence+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/24/25.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

extension Sequence {
    mutating func sorted(
        by firstPredicate: (Element, Element) -> Bool,
        _ secondPredicate: (Element, Element) -> Bool,
        _ otherPredicates: ((Element, Element) -> Bool)...
    ) -> [Element] {
        return sorted(by:) { lhs, rhs in
            if firstPredicate(lhs, rhs) { return true }
            if firstPredicate(rhs, lhs) { return false }
            if secondPredicate(lhs, rhs) { return true }
            if secondPredicate(rhs, lhs) { return false }
            for predicate in otherPredicates {
                if predicate(lhs, rhs) { return true }
                if predicate(rhs, lhs) { return false }
            }
            return false
        }
    }
}
