//
//  AlertCoinSelection.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-29.
//

import SwiftUI

struct AlertCoinSelection: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @ScaledMetric private var scale: CGFloat = 1

    let close: (Toplist?) -> ()
    let coinsList: [Toplist]

    @State var selectedCoin: Toplist?
    @State var input = ""
    @State var isEditing = false

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
                Text(Localization.string("Select Coin"))
                    .font(.poppinsSemibold(20))
                    .lineLimit(verticalSizeClass == .compact ? 1 : 2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focusHeader)
                
                InputField(placeholder: "Search",
                           input: $input,
                           isEditing: $isEditing,
                           accessibilityText: Localization.format("%@. Textfield", input.isEmpty ? Localization.string("Search") : input),
                           leadingView: .magnifyingGlass,
                           trailingView: .clearButton,
                           keyboardType: .default,
                           editingChanged: { editing in
                    }, onCommit: {
                    endTextEditing()
                })
                .padding(16)
                
                Separator()
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 16) {
                        let filteredList = coinsList.filter({ $0.name?.containsCaseInsensitive(string: input) ?? true || $0.id?.containsCaseInsensitive(string: input) ?? true || input.isEmpty })
                        
                        ForEach(filteredList, id: \.self) { coin in
                            let index = coinsList.firstIndex(of: coin) ?? -1
                            
                            CoinRowView(coin: coin, index: index, totalCount: filteredList.count) {
                                close(coin)
                                endTextEditing()
                            }
                        }
                        
                        if filteredList.isEmpty {
                            emptySearchView
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 1)
                
                Separator()
                    .padding(.bottom, 16)
                
                PrimaryButton(text: Localization.string("Close")) {
                    close(nil)
                    endTextEditing()
                }
                .accessibilityLabel(Localization.string("Close window"))
            }
            .padding(.vertical, 16)
            .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, maxHeight: 524, alignment: .center)
            // .background(Color.primaryBackgroundColor)
            .cornerRadius(8)
            .padding(16)
        }
        .foregroundColor(.onSurface)
        .animation(.none, value: UUID())
        .ignoresSafeArea(.keyboard)
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
    
    private var emptySearchView: some View {
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


