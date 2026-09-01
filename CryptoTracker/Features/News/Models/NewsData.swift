//
//  NewsData.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-16.
//

import Foundation

struct NewsData: Codable {
    var imageUrl: URL? = nil
    var pageDescription: String? = nil
    var pageTitle: String? = nil
    var pageType: String? = nil
    var siteName: String? = nil
    var sourceUrl: URL? = nil
    var url: URL?
    var pubDate: Date?
}
