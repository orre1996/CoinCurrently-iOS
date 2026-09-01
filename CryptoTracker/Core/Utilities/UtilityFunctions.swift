//
//  UtilityFunctions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-03.
//

import UIKit

#if IS_APP
let isPhone: Bool = MainActor.assumeIsolated { UIDevice.current.userInterfaceIdiom == .phone }
let isPad: Bool = MainActor.assumeIsolated { UIDevice.current.userInterfaceIdiom == .pad }
#endif

var randomPrices: [Double] {
    var pointsArray = [Double]()
    var previousValue = Double.random(in: 0.1...0.9)

    for _ in (0..<168) {
        previousValue = Double.random(in: max(0.1, (previousValue - 0.01))...min((previousValue + 0.01), 0.9))
        pointsArray.append(previousValue)
    }

    return pointsArray.normalized
}

func getPriceXPosition(position: CGFloat, textSize: CGFloat, readerWidthSize: CGFloat) -> CGFloat {
    if position < textSize / 2 {
        return textSize / 2
    }
    
    if position + textSize / 2 > readerWidthSize {
        return readerWidthSize - textSize / 2
    }
    
    return position
}
