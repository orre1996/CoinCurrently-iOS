//
//  NewsEntry.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-21.
//

import Foundation
import SwiftUI
import WidgetKit

struct NewsEntry: TimelineEntry {
    let date = Date()
    let newsModel: [NewsItem]
    let hasPro: Bool
    let selectedCategory: NewsWidgetCategory
    let isPlaceholder: Bool

    var showBuyProOverlay: Bool {
        selectedCategory.requiresPro && !hasPro
    }
    
    func copyWithPlaceholder() -> NewsEntry {
        NewsEntry(
            newsModel: newsModel,
            hasPro: hasPro,
            selectedCategory: selectedCategory,
            isPlaceholder: true
        )
    }
    
    static func empty() -> NewsEntry {
        return NewsEntry(
            newsModel: [],
            hasPro: false,
            selectedCategory: .general,
            isPlaceholder: true
        )
    }
}
