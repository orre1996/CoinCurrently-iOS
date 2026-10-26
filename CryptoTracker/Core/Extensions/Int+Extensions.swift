//
//  Int+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-15.
//

import Foundation
import SwiftUI

extension Int {
    var boolValue: Bool {
        self >= 1 ? true : false
    }
    
    var tabName: String {
        switch self {
        case 0:
            return "Home"
        case 1:
            return "Portfolio"
        case 2:
            return "Market"
        case 3:
            return "Settings"
        default:
            return "Error"
        }
    }

    var tabToScreenLabel: ScreenLabel? {
        switch self {
        case 0:
            return .home
        case 1:
            return .portfolio
        case 2:
            return .market
        case 3:
            return .settings
        default:
            return nil
        }
    }

    /// Page-selector titles on ``CryptoDetailScreen`` (analytics).
    var cryptoDetailPageTabName: String {
        switch self {
        case 0: return "Overview"
        case 1: return "About"
        case 2: return "Portfolio"
        case 3: return "Markets"
        default: return "Unknown"
        }
    }

    /// Page-selector titles on ``NFTDetailScreen`` (analytics).
    var nftDetailPageTabName: String {
        switch self {
        case 0: return "Overview"
        case 1: return "About"
        case 2: return "Markets"
        default: return "Unknown"
        }
    }

    /// Page-selector titles on ``ExchangeDetailScreen`` (analytics).
    var exchangeDetailPageTabName: String {
        switch self {
        case 0: return "Markets"
        case 1: return "About"
        default: return "Unknown"
        }
    }

    /// Page-selector titles on ``DerivativeDetailScreen`` (analytics).
    var derivativeDetailPageTabName: String {
        switch self {
        case 0: return "Perpetuals"
        case 1: return "Futures"
        default: return "Unknown"
        }
    }
    
#if IS_APP
    var trustColor: Color {
        switch self {
        case 10, 9:
            return .extremeGreed
            
        case 7, 8:
            return .greed
            
        case 5, 6:
            return .neutral
            
        case 3, 4:
            return .fear
            
        case 1,2 :
            return .extremeFear
            
        default:
            return .onSurfaceDim
        }
    }
#endif
}

extension Optional where Wrapped == Int {
    var cryptoDetailPageTabName: String {
        (self ?? 0).cryptoDetailPageTabName
    }

    var nftDetailPageTabName: String {
        (self ?? 0).nftDetailPageTabName
    }

    var exchangeDetailPageTabName: String {
        (self ?? 0).exchangeDetailPageTabName
    }

    var derivativeDetailPageTabName: String {
        (self ?? 0).derivativeDetailPageTabName
    }
}
