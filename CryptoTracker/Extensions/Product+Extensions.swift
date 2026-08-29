//
//  Product+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/15/25.
//

import StoreKit

extension Product {
    var subscriptionPeriod: StoreKitSubscriptionPeriod {
        guard let subscription = self.subscription else {
            return .none
        }
        
        switch subscription.subscriptionPeriod.unit {
        case .day:
            return .none
        case .week:
            return .weekly
        case .month:
            switch subscription.subscriptionPeriod.value {
            case 1:
                return .monthly
            case 2:
                return .everyTwoMonths
            case 3:
                return .everyThreeMonths
            case 6:
                return .everySixMonths
            default:
                fatalError("ERROR: YOU HAVE NOT CONSIDERED ALL MONTHLY VALUES.")
            }
        case .year:
            return .yearly
        @unknown default:
            fatalError("ERROR: YOU HAVE NOT CONSIDERED ALL SUBSCRIPTION UNITS.")
        }
    }
    
    var introductoryPrice: Double? {
        return self.subscription?.introductoryOffer?.price.doubleValue
    }
    
    func yearlyPrice(period: StoreKitSubscriptionPeriod) -> Double {
        switch subscriptionPeriod {
        case .yearly, .none:
            return self.price.doubleValue
        case .weekly:
            return self.price.doubleValue * 52
        case .monthly:
            return self.price.doubleValue * 12
        case .everyTwoMonths:
            return self.price.doubleValue * 6
        case .everyThreeMonths:
            return self.price.doubleValue * 4
        case .everySixMonths:
            return self.price.doubleValue * 2
        }
    }
    
    func getCurrency() -> CurrencyModel? {
        let currencyCode = self.priceFormatStyle.currencyCode
        return CurrencyModel.allCurrencies.first { $0.code == currencyCode }
    }
}
