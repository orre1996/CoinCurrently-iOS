//
//  ExchangeDetailAboutView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-12.
//

import SwiftUI

struct ExchangeDetailAboutView: View {
    let exchange: Exchange
    
    @Binding var newsUrl: String?
    
    private var sections: [DetailAboutSection] {
        var result: [DetailAboutSection] = []
        
        if let description = exchange.description, !description.isEmpty {
            result.append(DetailAboutSection(
                title: "Description",
                contents: [description],
                icons: []
            ))
        }
        
        var officialWebsites: [String] = []
        var websiteIcons: [Image] = []
        if let url = exchange.url, !url.isEmpty {
            officialWebsites.append(url)
            websiteIcons.append(.website)
        }
        if !officialWebsites.isEmpty {
            result.append(DetailAboutSection(
                title: "Official Websites",
                contents: officialWebsites,
                icons: websiteIcons
            ))
        }
        
        var communityUrls: [String] = []
        var communityIcons: [Image] = []
        if let facebook = exchange.facebook_url, !facebook.isEmpty {
            communityUrls.append(facebook)
            communityIcons.append(.meta)
        }
        if let reddit = exchange.reddit_url, !reddit.isEmpty {
            communityUrls.append(reddit)
            communityIcons.append(.reddit)
        }
        if let twitter = exchange.twitter_handle, !twitter.isEmpty {
            communityUrls.append("https://twitter.com/\(twitter)")
            communityIcons.append(.x)
        }
        if let telegram = exchange.telegram_url, !telegram.isEmpty {
            communityUrls.append(telegram)
            communityIcons.append(.telegram)
        }
        if let other1 = exchange.other_url_1, !other1.isEmpty {
            communityUrls.append(other1)
            communityIcons.append(Image.icon(for: other1))
        }
        if let other2 = exchange.other_url_2, !other2.isEmpty {
            communityUrls.append(other2)
            communityIcons.append(Image.icon(for: other2))
        }
        if !communityUrls.isEmpty {
            result.append(DetailAboutSection(
                title: "Communities",
                contents: communityUrls,
                icons: communityIcons
            ))
        }
        
        return result
    }

    private var hasExchangeInfo: Bool {
        exchange.year_established != nil ||
        (exchange.country != nil && !(exchange.country?.isEmpty ?? true)) ||
        exchange.centralized != nil
    }

    var body: some View {
        DetailAboutView(
            sections: sections,
            isLoading: false,
            emptyStateMessage: "When information about this exchange appears, it'll show up here.",
            fromScreen: .exchangeDetail,
            newsUrl: $newsUrl,
            headerContent: hasExchangeInfo ? AnyView(ExchangeInfoCell(exchange: exchange)) : nil
        )
    }
}
