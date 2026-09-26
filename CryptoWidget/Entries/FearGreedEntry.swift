//
//  FearGreedEntry.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-28.
//

import Foundation
import SwiftUI
import WidgetKit

struct FearGreedEntry: TimelineEntry {
    let date: Date = Date()
    let fearModel: FearGreed?
    let isPlaceholder: Bool
    
    func copyWithPlaceholder() -> FearGreedEntry {
        return FearGreedEntry(
            fearModel: fearModel,
            isPlaceholder: true
        )
    }

    static func empty() -> FearGreedEntry {
        return FearGreedEntry(
            fearModel: nil,
            isPlaceholder: true
        )
    }
}
