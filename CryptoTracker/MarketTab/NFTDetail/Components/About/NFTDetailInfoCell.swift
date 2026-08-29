//
//  CryptoDetailInfoCell.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-07-14.
//

import SwiftUI
import WebKit
import SwiftSoup

struct NFTDetailInfoCell: View {
    @Environment(\.accessibilityVoiceOverEnabled) var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let title: String?
    let contents: [String]
    let icons: [Image]
    var downloading: Bool = false
    let fromScreen: ScreenLabel
    
    @Binding var infoUrl: String?
    
    @State private var showMore = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
                .accessibilitySortPriority(4)

            LazyVStack(alignment: .leading, spacing: 12) {
                if title == "Description" {
                    descriptionView
                        .accessibilitySortPriority(3)
                    
                    if !accessibilityVoiceOverEnabled && (contents.first?.count ?? 0) > 500 {
                        viewMoreButton
                            .accessibilitySortPriority(2)
                    }
                } else {
                    urlsView
                        .accessibilitySortPriority(1)
                }
            }
            .cardBackground()
        }
        .accessibilityElement(children: .contain)
    }

    private var headerView: some View {
        NewShimmeringText(
            text: title ?? "000000000",
            isDownloading: downloading
        )
        .font(.satoshiBold(22))
        .foregroundStyle(Color.onSurface)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .accessibilityAddTraits(.isHeader)
    }

    private var urlsView: some View {
        ForEach(0..<contents.count, id: \.self) { index in
            let content = contents[safely: index] ?? "00000000"
            
            Button(action: {
                AnalyticsManager.shared.log(
                    WebViewOpened(fromScreen: fromScreen, url: content)
                )
                infoUrl = content
            }, label: {
                let index = contents.firstIndex(of: content) ?? 0
                
                HStack(spacing: 8) {
                    if let icon = icons[safely: index] ?? icons[safely: 0] {
                        icon
                            .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .accessibilityHidden(true)
                    }
                    
                    NewShimmeringText(
                        text: content,
                        isDownloading: title == nil
                    )
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel(content
                        .replacingOccurrences(of: "https://", with: "")
                        .replacingOccurrences(of: "http://", with: "")
                        .replacingOccurrences(of: "www", with: ""))
                }
            })
        }
    }
    
    @ViewBuilder
    private var descriptionView: some View {
        let htmlText = getHtmlText(html: contents.first)
        let text = showMore || accessibilityVoiceOverEnabled ? htmlText : String(htmlText.prefix(500)) + (htmlText.count > 500 ? "..." : "")
        
        Text(text)
            .font(.satoshiRegular(16))
            .foregroundStyle(Color.onSurfaceDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
    
    private var viewMoreButton: some View {
        Text(showMore ? "View Less" : "View More")
            .foregroundStyle(Color.onSurfaceContainer)
            .font(.satoshiBold(18))
            .padding(
                EdgeInsets(
                    top: 12,
                    leading: 24,
                    bottom: 12,
                    trailing: 24
                )
            )
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .onTapGesture {
                if showMore {
                    AnalyticsManager.shared.log(
                        ViewMoreCollapsed(fromScreen: fromScreen)
                    )
                } else {
                    AnalyticsManager.shared.log(
                        ViewMoreExpanded(fromScreen: fromScreen)
                    )
                }
                showMore.toggle()
            }
    }
    
    private func getHtmlText(html: String?) -> String {
        do {
            var html = html
            let doc = try? SwiftSoup.parse(html ?? "").select("a")
            
            if let doc = doc {
                for link in doc {
                    let linkHref: String = try link.attr("href")
                    let linkText: String = try link.text()
                    html = html?.replacingOccurrences(of: linkHref, with: linkText)
                }
            }
            
            html = html?.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
            return html ?? ""
        } catch {
            return ""
        }
    }
}
