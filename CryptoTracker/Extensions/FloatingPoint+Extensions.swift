//
//  FloatingPoint+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-19.
//

import Foundation

extension FloatingPoint {
    var whole: Self { modf(self).0 }
    var fraction: Self { modf(self).1 }
}
