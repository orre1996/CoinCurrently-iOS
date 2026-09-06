//
//  WidgetReloadService.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-09.
//

import Foundation
import SwiftUI

#if !os(watchOS)
    import WidgetKit
#endif

class WidgetReloadService {
    @AppStorage("savedCoin", store: UserDefaults(suiteName: .groupIdentifier))
    var savedCoins: Data = Data()

    @AppStorage("savedPortfolio", store: UserDefaults(suiteName: .groupIdentifier))
    var savedPortfolio: Data = Data()

    // nonisolated(unsafe) - accessed from actors and widget providers
    nonisolated(unsafe) public static let shared = WidgetReloadService()

   func getSavedCurrencies() -> [String] {
        let savedCurrency = (try? JSONDecoder().decode(Array<String>.self, from: savedCoins)) ?? [String]()
        return savedCurrency
    }
     
    // DON'T REMOVE
    func getSavedPortfolio() -> [PortfolioCurrencyModel] {
        guard let savedPortfolio = (try? JSONDecoder().decode([PortfolioCurrencyModel].self, from: savedPortfolio)) else { return [] }
        return savedPortfolio.filter({ $0.id != "" })
    }

    enum WidgetTypes {
        case currencies
        case portfolio
        case all
    }
    
    func forceUpdateWidgets(type: WidgetTypes = .all) {
#if !os(watchOS)
        if type == .portfolio {
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Portfolio_Widget")
        } else if type == .currencies {
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "CoinCurrently_Duo_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Quad_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Multi_Widget")
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
#endif
    }
}
