//
//  DetailAboutView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-12.
//

import SwiftUI

struct DetailAboutSection: Hashable {
    let title: String
    let contents: [String]
    let icons: [Image]

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(contents)
    }

    static func == (lhs: DetailAboutSection, rhs: DetailAboutSection) -> Bool {
        lhs.title == rhs.title && lhs.contents == rhs.contents
    }
}

struct DetailAboutView: View {
    let sections: [DetailAboutSection]
    let isLoading: Bool
    let emptyStateMessage: String
    let fromScreen: ScreenLabel
    @Binding var newsUrl: String?
    var headerContent: AnyView?

    init(
        sections: [DetailAboutSection],
        isLoading: Bool,
        emptyStateMessage: String,
        fromScreen: ScreenLabel,
        newsUrl: Binding<String?>,
        headerContent: AnyView? = nil
    ) {
        self.sections = sections
        self.isLoading = isLoading
        self.emptyStateMessage = emptyStateMessage
        self.fromScreen = fromScreen
        self._newsUrl = newsUrl
        self.headerContent = headerContent
    }

    var body: some View {
        if let header = headerContent {
            header
                .padding(
                    EdgeInsets(
                        top: 32,
                        leading: 16,
                        bottom: 0,
                        trailing: 16
                    )
                )
        }
        
        if isLoading {
            loadingView
        } else if !sections.isEmpty {
            ForEach(sections, id: \.self) {
                CryptoDetailInfoCell(
                    title: $0.title,
                    contents: $0.contents,
                    icons: $0.icons,
                    fromScreen: fromScreen,
                    infoUrl: $newsUrl
                )
                .accessibilityElement(children: .contain)
            }
        } else {
            EmptyContent(
                title: Localization.string("No details yet"),
                subTitle: Localization.string(emptyStateMessage)
            )
            .frame(maxWidth: .infinity)
            .padding(
                EdgeInsets(
                    top: 72,
                    leading: 32,
                    bottom: 32,
                    trailing: 32
                )
            )
        }
    }
    
    private var loadingView: some View {
        ForEach(0..<3, id: \.self) { _ in
            CryptoDetailInfoCell(
                title: nil,
                contents: ["0000000000", "0000000000", "0000000000"],
                icons: [],
                downloading: true,
                fromScreen: fromScreen,
                infoUrl: $newsUrl
            )
        }
    }
}
