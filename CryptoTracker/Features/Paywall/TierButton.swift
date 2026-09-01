//
//  TierButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/20/25.
//

import StoreKit

struct TierButton: Hashable {
    let title: String
    let formattedPrice: String
    let formattedPriceAccessibilityLabel: String
    let subTitle: String?
    let subTitleAccessibilityLabel: String?
    let saveAmount: Double?
    let timeLeft: String?
    let product: Product
    
    func copy(withTimeLeft: String) -> TierButton {
        return TierButton(
            title: title,
            formattedPrice: formattedPrice,
            formattedPriceAccessibilityLabel: formattedPriceAccessibilityLabel,
            subTitle: subTitle,
            subTitleAccessibilityLabel: subTitleAccessibilityLabel,
            saveAmount: saveAmount,
            timeLeft: withTimeLeft,
            product: product
        )
    }
}
