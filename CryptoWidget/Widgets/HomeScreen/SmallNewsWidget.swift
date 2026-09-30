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
    var linksToNews: Bool = true
    var showsWidgetURL: Bool = true
    
    var body: some View {
        let newsURL = URL(string: newsItem?.news_url ?? .appName)

        Group {
            if linksToNews, let newsURL {
                Link(destination: newsURL) {
                    content
                }
            } else {
                content
            }
        }
        .widgetURL(showsWidgetURL ? newsURL : nil)
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
        let names = newsItem?.relatedCoinNames ?? []

        return Group {
            if newsItem == nil || !names.isEmpty {
                ShimmeringText(
                    text: names.prefix(2).joined(separator: " · ").isEmpty ? "000" : names.prefix(2).joined(separator: " · "),
                    isDownloading: newsItem == nil
                )
                .foregroundStyle(Color.onSurface(for: scheme))
                .font(.satoshiBold(12))
                .padding(
                    EdgeInsets(
                        top: 4,
                        leading: 8,
                        bottom: 4,
                        trailing: 8
                    )
                )
                .background(Color.surfaceContainerHigh(for: scheme))
                .cornerRadius(8)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var metadataView: some View {
        let source = newsItem?.source_name ?? "000000"
        let timeAgo = newsItem?.publishedDate?.timeAgoDisplay ?? "000000"
        let text = "\(nonBreaking(source)) · \(nonBreaking(timeAgo))"

        return ShimmeringText(
            text: text,
            isDownloading: newsItem?.source_name == nil || newsItem?.posted_at == nil
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
