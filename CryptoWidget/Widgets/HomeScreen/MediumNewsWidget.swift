//
//  MediumNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-23.
//

import SwiftUI

struct MediumNewsWidget: View {
    var entry: NewsEntry

    var body: some View {
        HStack(spacing: 0) {
            SmallNewsWidget(
                newsItem: entry.newsModel[safely: 0],
                showsWidgetURL: false
            )
            
            VerticalSeparator()
                .padding(.vertical, 16)
            
            SmallNewsWidget(
                newsItem: entry.newsModel[safely: 1],
                showsWidgetURL: false
            )
        }
    }
}
