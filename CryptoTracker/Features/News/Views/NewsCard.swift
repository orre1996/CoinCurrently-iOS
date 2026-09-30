//
//  NewsCard.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-14.
//

import SwiftUI

struct NewsCard: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }

    let news: NewsItem?
    var selected: Bool = false
    let index: Int
    let totalCount: Int
    var newsType: NewsContentKind = .article
    var topPadding: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            newsImageView
            
            VStack(alignment: .leading, spacing: 4) {
                textsView
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                if isHorizontal {
                    OverflowLayout(spacing: 4) {
                        tagsView
                            .padding(.trailing, 8)
                        
                        metadataView
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                } else {
                    AdaptiveStack(isHorizontal: false, spacing: 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                        tagsView
                        metadataView
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint(Localization.string("Double tap to read more"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .multilineTextAlignment(.leading)
        .padding(
            EdgeInsets(
                top: topPadding,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
    }
    
    private var contentKindTitle: String {
        switch newsType {
        case .article:
            return Localization.string("Article")
        case .video:
            return Localization.string("Video")
        case .podcast:
            return Localization.string("Podcast")
        }
    }

    private var accessibilityDescription: String {
        let position = Localization.format("%1$@ %2$d of %3$d", contentKindTitle, index, totalCount)
        let title = news?.title ?? ""
        let source = Localization.format("By %@", news?.source_name ?? "000000")
        let published = Localization.format(
            "Published %@",
            news?.publishedDate?.timeAgoDisplay ?? "000000"
        )
        var description = "\(position). \(title). \(source). \(published)"
        let coins = Array((news?.relatedCoinNames ?? []).prefix(3))
        if !coins.isEmpty {
            description += ". " + Localization.format("Tickers, %@", coins.joined(separator: ", "))
        }
        return description
    }

    private var newsImageView: some View {
        ShimmeringImage(
            imageUrl: news?.image_url ?? "",
            downloading: news == nil,
            size: 80,
            scaleMode: .fill
        )
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var textsView: some View {
        ShimmeringText(
            text: news?.title ?? String.getStringRandomLength(length: 60),
            isDownloading: news?.title == nil
        )
        .foregroundStyle(Color.onSurface)
        .font(.satoshiBold(16))
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .truncationMode(.tail)
    }
    
    private var metadataView: some View {
        ShimmeringText(
            text: "\(news?.source_name ?? "000000") · \(news?.publishedDate?.timeAgoDisplay ?? "000000")",
            isDownloading: news?.source_name == nil || news?.posted_at == nil
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsView: some View {
        let names = news?.relatedCoinNames ?? []

        return Group {
            if news == nil || !names.isEmpty {
                ShimmeringText(
                    text: names.prefix(3).joined(separator: " · ").isEmpty ? "000" : names.prefix(3).joined(separator: " · "),
                    isDownloading: news == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(12))
                .padding(
                    EdgeInsets(
                        top: 4,
                        leading: 8,
                        bottom: 4,
                        trailing: 8
                    )
                )
                .background(Color.surfaceContainerHigh)
                .cornerRadius(8)
            }
        }
    }
}
