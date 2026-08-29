//
//  MediumNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-23.
//

import SwiftUI

struct MediumNewsWidget: View {
    @Environment(\.colorScheme) var scheme

    var entry: NewsEntry

    var body: some View {
        HStack(spacing: 0) {
            SmallNewsWidget(
                newsItem: entry.newsModel[safely: 0],
                linksToNews: !entry.showBuyProOverlay,
                showsWidgetURL: !entry.showBuyProOverlay
            )
            
            VerticalSeparator()
                .padding(.vertical, 16)
            
            SmallNewsWidget(
                newsItem: entry.newsModel[safely: 1],
                linksToNews: !entry.showBuyProOverlay,
                showsWidgetURL: !entry.showBuyProOverlay
            )
        }
        .blur(radius: entry.showBuyProOverlay ? 5 : 0)
        .overlay {
            BuyProView(hasBoughtPro: !entry.showBuyProOverlay)
        }
        .widgetURL(entry.showBuyProOverlay ? URL(string: "buyPro") : nil)
    }
}
