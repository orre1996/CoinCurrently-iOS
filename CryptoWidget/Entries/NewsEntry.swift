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
    let selectedCategory: NewsWidgetCategory
    let isPlaceholder: Bool
    
    func copyWithPlaceholder() -> NewsEntry {
        NewsEntry(
            newsModel: newsModel,
            selectedCategory: selectedCategory,
            isPlaceholder: true
        )
    }
    
    static func empty() -> NewsEntry {
        return NewsEntry(
            newsModel: [],
            selectedCategory: .general,
            isPlaceholder: true
        )
    }
}
