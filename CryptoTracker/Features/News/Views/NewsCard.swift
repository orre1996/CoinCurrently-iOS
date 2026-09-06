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
    
    @ScaledMetric private var scale: CGFloat = 1
    
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
            .accessibilityLabel("""
                \(newsType.rawValue) \(index) of \(totalCount).
                \(news?.title ?? ""). By \(news?.source_name ?? "000000"). 
                Published \(news?.date?.convertStringToDate(dateFormat: .EdMMMyyyyHHmmssZ)?.timeAgoDisplay ?? "000000"). Sentiment, \(news?.sentiment ?? "") 
                \(news?.tickers?.isEmpty ?? true ? "" : ". Tickers, ")
                \(news?.tickers?[safely: 0] ?? ""). \(news?.tickers?[safely: 1] ?? ""). \(news?.tickers?[safely: 2] ?? "")
            """)
            .accessibilityHint("Double tap to read more")
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
            text: "\(news?.source_name ?? "000000") · \(news?.date?.convertStringToDate(dateFormat: .EdMMMyyyyHHmmssZ)?.timeAgoDisplay ?? "000000")",
            isDownloading: news?.source_name == nil || news?.date == nil
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsView: some View {
        HStack(spacing: 4) {
            sentimentIcon
            
            if news == nil || news?.tickers?.isEmpty == false {
                ShimmeringText(
                    text: news?.tickers?.prefix(3).map({ $0 }).joined(separator: " · ") ?? "000",
                    isDownloading: news == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(12))
            }
        }
        .padding(
            EdgeInsets(
                top: 4,
                leading: 4,
                bottom: 4,
                trailing: news == nil || news?.tickers?.isEmpty == false ? 8 : 4
            )
        )
        .background(Color.surfaceContainerHigh)
        .cornerRadius(8)
    }
    
    private var sentimentIcon: some View {
        ZStack {
            MinimumTextSize(text: "X") {
                if news?.sentiment != nil || news == nil {
                    (news?.getSentimentSign ?? Image.trendStill)
                        .foregroundStyle(news == nil ? Color.shimmeringBackground.opacity(0.15) : news?.getSentimentColor ?? .onSurfaceDim)
                        .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                }
                
                if news == nil {
                    (news?.getSentimentSign ?? Image.trendStill)
                        .foregroundStyle(news == nil ? Color.onSurface.opacity(0.5) : Color.onSurfaceDim)
                        .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                        .shimmer()
                }
            }
            .font(.satoshiBold(12))
        }
    }
}
