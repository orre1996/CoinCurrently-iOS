//
//  CompareCoinSelector.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-02.
//

import SwiftUI

struct CompareCoinSelection: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ScaledMetric private var scale: CGFloat = 1

    let coinsList: [Toplist]
    let mainCoinId: String
    let currentCoinId: String?
    let showNone: Bool
    let close: (String?) -> Void

    @State private var input = ""
    @State private var isEditing = false

    @AccessibilityFocusState private var focusHeader
    
    var body: some View {
        ZStack {
            Color.overlayBackground.opacity(0.7)
                .ignoresSafeArea()
                .highPriorityGesture(DragGesture())
                .onTapGesture {
                    if isEditing {
                        endTextEditing()
                        isEditing = false
                    } else {
                        close(nil)
                    }
                }
            
            VStack(alignment: .center, spacing: 0) {
                headerView

                searchField
                    .padding(.bottom, 16)
                
                Separator()
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 16) {
                        let filteredList = coinsList.filter({ $0.name?.containsCaseInsensitive(string: input) ?? true ||
                                           $0.id?.containsCaseInsensitive(string: input) ?? true ||
                                           input.isEmpty })
                        
                        if filteredList.isEmpty {
                            emptyView
                        } else {
                           coinsListView(list: filteredList)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 1)
                
                Separator()
                
                PrimaryButton(text: Localization.string("Close")) {
                    close(nil)
                }
                .padding(.vertical, 16)
            }
            .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, minHeight: 0, maxHeight: 524, alignment: .center)
            .background(Color.surfaceContainerLow)
            .cornerRadius(8)
            .padding(16)
        }
        .foregroundColor(.onSurface)
        .ignoresSafeArea(.keyboard)
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
    
    private var headerView: some View {
        Text(Localization.string("Select Coin"))
            .font(.poppinsSemibold(22))
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .lineLimit(verticalSizeClass == .compact ? 1 : 2)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var searchField: some View {
        InputField(placeholder: "Search",
                   input: $input,
                   isEditing: $isEditing,
                   accessibilityText: Localization.format("%@. Textfield", input.isEmpty ? Localization.string("Search") : input),
                   leadingView: .magnifyingGlass,
                   trailingView: .clearButton,
                   keyboardType: .default)
        .padding(.horizontal, 16)
    }
    
    private func coinsListView(list: [Toplist]) -> some View {
        ForEach(list, id: \.self) { coin in
            let index = list.firstIndex(of: coin) ?? -1

            if coin.id != currentCoinId && mainCoinId != coin.id {
                Button(action: {
                    guard let id = coin.id else { return }

                    close(id)
                }, label: {
                    HStack(spacing: 16) {
                        if let url = coin.image {
                            ShimmeringImage(imageUrl: url, downloading: false, size: 32 * min(scale, 1.5))
                        }

                        Text("\(coin.name ?? "") (\(coin.symbol?.uppercased() ?? ""))")
                            .font(.poppinsRegular(16))
                            .foregroundColor(.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                })
                .frame(maxWidth: .infinity)
                .modifier(CardBackground())
                .padding(.horizontal, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Localization.format("Currency %d of %d. %@.", index + 1, list.count, coin.name ?? ""))
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 0) {
            Text(Localization.string("We couldn't find the currency you were looking for."))
                .foregroundColor(.onSurface)
                .font(.poppinsSemibold(16))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)
            
            Text(Localization.string("Try searching for something else."))
                .foregroundColor(.onSurface)
                .font(.poppinsRegular(14))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .modifier(CardBackground())
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}
