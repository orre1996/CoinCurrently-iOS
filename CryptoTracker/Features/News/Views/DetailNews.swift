//
//  DetailNews.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-16.
//

import SwiftUI

struct DetailNews: View {
    @Environment(NavigationViewModel.self) private var viewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let title: String?
    let fromScreen: ScreenLabel
    let news: [NewsItem]
    let showError: Bool
    let errorMessage: String
    
    let refresh: () async -> Void
    
    var body: some View {
        if showError {
            EmptyContent(
                title: Localization.string("No news yet"),
                subTitle: Localization.format(
                    "When news about this %@ appears, it'll show up here.",
                    Localization.string(errorMessage)
                )
            )
            .padding(
                EdgeInsets(
                    top: 72,
                    leading: 32,
                    bottom: 72,
                    trailing: 32
                )
            )
        } else if news.isEmpty {
            tempList
        } else {
            realList
        }
    }
    
    @ViewBuilder
    private var tempList: some View {
        let cardCount: Int = isPad ? 20 : 10

        ForEach(0..<cardCount, id: \.self) { index in
            Button(action: {
            }, label: {
                NewsCard(
                    news: nil,
                    index: index + 1,
                    totalCount: cardCount
                )
            })
        }
    }

    private var realList: some View {
        ForEach(news, id: \.self) { news in
            let index = self.news.firstIndex(of: news) ?? -1
            
            AdaptiveButton(buttonAction: {
                guard let url = news.news_url, !url.isEmpty else { 
                    return
                }
                
                AnalyticsManager.shared.log(
                    NewsOpened(fromScreen: fromScreen)
                )
                
                viewModel.newsUrl = url
            }) {
                NewsCard(
                    news: news,
                    index: index + 1,
                    totalCount: self.news.count
                )
            }
        }
    }
}
