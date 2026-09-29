//
//  StartTabView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-19.
//

import SwiftUI

struct StartTabView: View {
    @ScaledMetric private var scale: CGFloat = 1

    private let marketPages: [StartMarketPage] = [.currencies, .nfts, .categories, .exchanges, .derivatives]

    let tab: StartTab
    let index: Int
    let totalCount: Int
    let selectedTab: StartTab
    let selectedMarketPage: StartMarketPage
    let tabAction: (StartTab) -> Void
    let pageAction: (StartMarketPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                tabAction(tab)
            }) {
                HStack(spacing: 0) {
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                        .frame(width: 32 * min(scale, 1.5), height: 32 * min(scale, 1.5), alignment: .center)
                        .background(tab == selectedTab ? Color.primary : .clear)
                        .clipShape(Circle())
                        .padding(.trailing, 16)

                    Text(Localization.string(tab.rawValue))
                        .font(.poppinsRegular(16))
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.onSurface)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if tab == .market {
                        Image.chevronUp
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.onSurface)
                            .scaledToFill()
                            .frame(width: 20 * min(scale, 1.5), height: 10 * min(scale, 1.5))
                            .rotationEffect(.init(degrees: tab == selectedTab ? 180 : 0))
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                tab == .lastUsed
                    ? Localization.format("%@, tab %d of %d.", Localization.string(tab.rawValue), index + 1, totalCount)
                    : Localization.format("Tab %d of %d. %@.", index + 1, totalCount, Localization.string(tab.rawValue))
            )
            .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            
            if tab == .market && selectedTab == .market {
                marketPageView
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .modifier(CardBackground(hasPadding: false))
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var marketPageView: some View {
        Separator()
            .padding(.vertical, 16)
        
        Text(Localization.string("Page"))
            .font(.poppinsRegular(16))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .accessibilityAddTraits(.isHeader)
        
        ForEach(marketPages, id: \.self) { page in
            let index = marketPages.firstIndex(of: page) ?? 0

            Separator()

            StartMarketPageView(page: page, selectedPage: selectedMarketPage) { page in
                pageAction(page)
            }
            .padding(.bottom, page == marketPages.last ? 0 : 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Localization.format("Market page %d of %d. %@.", index + 1, marketPages.count, Localization.string(page.rawValue)))
            .accessibilityAddTraits(selectedMarketPage == page ? [.isSelected] : [])
        }
    }
}
