//
//  GasFeeEntry.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2024-03-20.
//

import Foundation
import SwiftUI
import WidgetKit

struct GasFeeEntry: TimelineEntry {
    let date: Date = Date()
    let gasFeesModel: GasFees?
    let isPlaceholder: Bool
    
    func copyWithPlaceholder() -> GasFeeEntry {
        return GasFeeEntry(
            gasFeesModel: gasFeesModel,
            isPlaceholder: true
        )
    }
    
    static func empty() -> GasFeeEntry {
        return GasFeeEntry(
            gasFeesModel: nil,
            isPlaceholder: true
        )
    }
}
