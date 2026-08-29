//
//  NewsModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-31.
//

import Foundation
import SwiftUI

struct NewsModel: Codable {
    let data: [NewsItem]
}

struct NewsItem: Codable, Equatable, Hashable {
    var news_url: String? = nil
    var image_url: String? = nil
    var title: String? = nil
    var text: String? = nil
    var source_name: String? = nil
    var date: String? = nil
    var topics: [String]? = nil
    var sentiment: String? = nil
    var type: String? = nil
    var tickers: [String]? = nil
}

extension NewsItem {
    var getSentimentSign: Image {
        if sentiment == "Negative" {
            return .trendDown
        } else if sentiment == "Positive" {
            return .trendUp
        } else {
            return .trendStill
        }
    }
    
    #if IS_APP
    var getSentimentColor: Color {
        if sentiment == "Negative" {
            return .trendDown
        } else if sentiment == "Positive" {
            return .trendUp
        } else {
            return .onSurfaceDim
        }
    }
    #elseif IS_WIDGET
    func getSentimentColor(for scheme: ColorScheme) -> Color {
        if sentiment == "Negative" {
            return .trendDown(for: scheme)
        } else if sentiment == "Positive" {
            return .trendUp(for: scheme)
        } else {
            return Color.onSurfaceDim(for: scheme)
        }
    }
    #endif
}
