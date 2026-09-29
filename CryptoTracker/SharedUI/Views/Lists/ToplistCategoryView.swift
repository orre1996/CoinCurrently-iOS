//
//  ToplistCategoryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct ToplistCategoryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let toplist: [Toplist]?
    let favoriteList: [Toplist]?
    let showViewAll: Bool
    let carouselFilter: CarouselFilter
    let toggleFavorite: (Toplist) async -> Void
    let navigateToCryptoDetail: (Toplist) -> Void
    let viewAllPressed: () -> Void
    let refresh: () async -> Void
    
    var body: some View {
        LazyVStack(spacing: 0) {
            if let toplist, toplist.isEmpty {
                emptyView
            } else if let toplist {
                realList(toplist: toplist)
            } else {
                tempList
            }
            
            if showViewAll {
                showAllButton
            }
        }
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16 + safeAreaInsets.leading,
                bottom: 32,
                trailing: 16 + safeAreaInsets.trailing
            )
        )
        .refreshable {
            Task {
                await refresh()
            }
        }
    }

    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 20 : 10), id: \.self) { index in
            ToplistCardView(
                coin: nil,
                selectedChangeOption: .sevenDays,
                isFirstElement: index == 0,
                listIndex: index,
                listCount: isPad ? 20 : 10,
                navigateToCryptoDetail: { }
            )
        }
    }
    
    private func realList(toplist: [Toplist]) -> some View {
        ForEach(toplist, id: \.self) { coin in
            let index = toplist.firstIndex(of: coin) ?? 0
            let isFavorited = favoriteList?.contains(where: { $0.id == coin.id }) ?? false
            
            ToplistCardView(
                coin: coin,
                selectedChangeOption: .sevenDays,
                isFirstElement: index == 0,
                listIndex: index,
                listCount: toplist.count,
                navigateToCryptoDetail: {
                    navigateToCryptoDetail(coin)
                }
            )
            .animation(.none, value: UUID())
            .contextMenu {
                Button {
                    Task {
                        await toggleFavorite(coin)
                    }
                } label: {
                    Label(title: {
                        Text(Localization.string(isFavorited ? "Remove from favorites" : "Add to favorites"))
                    }, icon: {
                        isFavorited ? Image.starFill : Image.star
                    })
                }
            }
        }
    }
    
    private var showAllButton: some View {
        SecondaryButton(text: Localization.string("View All")) {
            viewAllPressed()
        }
        .accessibilityLabel(Localization.format("View all %@", Localization.string(carouselFilter.rawValue)))
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 6)
    }
    
    private var emptyView: some View {
        VStack(spacing: 44) {
            EmptyContent(
                title: Localization.string("No favorites yet"),
                subTitle: Localization.string("Tap the star on any coin to add it here and track it easily.")
            )
            .padding(.horizontal, 16)
            
            HStack(spacing: 8) {
                Image.info
                    .resizable()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityHidden(true)
                
                Text(Localization.string("Tip: Long press any coin to add it to favorites."))
                    .foregroundStyle(Color.onSurfaceDim)
                    .font(.satoshiRegular(14))
            }
        }
        .accessibilityElement(children: .combine)
        .multilineTextAlignment(.center)
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 32,
                trailing: 16
            )
        )
    }
}
