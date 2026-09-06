//
//  SmallNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-21.
//

import SwiftUI

struct SmallNewsWidget: View {
    @Environment(\.colorScheme) var scheme

    let newsItem: NewsItem?
    var showBuyProOverlay: Bool = false
    var linksToNews: Bool = true
    var showsWidgetURL: Bool = true
    
    var body: some View {
        let buyProURL = URL(string: "buyPro")
        let newsURL = URL(string: newsItem?.news_url ?? .appName)

        Group {
            if linksToNews, !showBuyProOverlay, let newsURL {
                Link(destination: newsURL) {
                    content
                }
            } else {
                content
            }
        }
        .blur(radius: showBuyProOverlay ? 5 : 0)
        .overlay {
            if showBuyProOverlay {
                WidgetBuyProOverlay(hasBoughtPro: false)
            }
        }
        .widgetURL(resolvedWidgetURL(buyProURL: buyProURL, newsURL: newsURL))
    }

    private func resolvedWidgetURL(buyProURL: URL?, newsURL: URL?) -> URL? {
        if showBuyProOverlay {
            return buyProURL
        }
        guard showsWidgetURL else { return nil }
        return newsURL
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShimmeringText(
                text: newsItem?.title ?? "CoinCurrently",
                isDownloading: newsItem == nil
            )
            .foregroundStyle(Color.onSurface(for: scheme))
            .font(.satoshiBold(16))
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .layoutPriority(0)
            
            tagsView
                .layoutPriority(1)
            
            metadataView
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }
    
    private var tagsView: some View {
        HStack(spacing: 4) {
            sentimentIcon
            
            if newsItem == nil || newsItem?.tickers?.isEmpty == false {
                ShimmeringText(
                    text: newsItem?.tickers?.prefix(2).map({ $0 }).joined(separator: " · ") ?? "000",
                    isDownloading: newsItem == nil
                )
                .foregroundStyle(Color.onSurface(for: scheme))
                .font(.satoshiBold(12))
            }
        }
        .padding(
            EdgeInsets(
                top: 4,
                leading: 4,
                bottom: 4,
                trailing: newsItem == nil || newsItem?.tickers?.isEmpty == false ? 8 : 4
            )
        )
        .background(Color.surfaceContainerHigh(for: scheme))
        .cornerRadius(8)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var sentimentIcon: some View {
        MinimumTextSize(text: "X") {
            if newsItem?.sentiment != nil || newsItem == nil {
                (newsItem?.getSentimentSign ?? Image.trendStill)
                    .foregroundStyle(newsItem?.getSentimentColor(for: scheme) ?? .onSurfaceDim(for: scheme))
                    .frame(width: 16, height: 16)
            }
        }
        .font(.satoshiBold(12))
    }
    
    private var metadataView: some View {
        let source = newsItem?.source_name ?? "000000"
        let timeAgo = newsItem?.date?
            .convertStringToDate(dateFormat: .EdMMMyyyyHHmmssZ)?
            .timeAgoDisplay ?? "000000"
        let text = "\(nonBreaking(source)) · \(nonBreaking(timeAgo))"

        return ShimmeringText(
            text: text,
            isDownloading: newsItem?.source_name == nil || newsItem?.date == nil
        )
        .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
        .font(.satoshiBold(12))
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
    }

    /// Keeps each metadata segment on one line; wrapping only occurs at the ` · ` separator.
    private func nonBreaking(_ string: String) -> String {
        string.replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}
