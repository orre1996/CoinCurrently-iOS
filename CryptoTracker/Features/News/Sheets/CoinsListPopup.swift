//
//  CoinsListPopup.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-05-02.
//

import SwiftUI

struct CoinsListPopup: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @ScaledMetric private var scale: CGFloat = 1

    var coinsList: [CoinsListModel]
    var close: (CoinsListModel?) -> () = { _ in }

    @State var input = ""
    @State var isEditing = false
    @State var filteredList = [CoinsListModel]()

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
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .lineLimit(verticalSizeClass == .compact ? 1 : 2)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focusHeader)
                
                searchField
                    .padding(.bottom, 16)
                
                Separator()
                
                ScrollView(.vertical) {
                    
                    ScrollViewReader { reader in
                        
                        LazyVStack(spacing: 16) {
                            
                            ForEach((0..<filteredList.count + 1), id: \.self) { index in
                                
                                if let coin = filteredList[safely: index] {
                                    
                                    Button(action: {
                                        close(coin)
                                        endTextEditing()
                                    }) {
                                        
                                        Text("\(coin.name ?? "") (\(coin.symbol?.uppercased() ?? ""))")
                                            .font(.poppinsRegular(16))
                                            .foregroundColor(.onSurface)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .modifier(CardBackground())
                                    .padding(.horizontal, 16)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(Localization.format("Currency %d of %d. %@.", index + 1, filteredList.count, coin.name ?? ""))
                                    
                                } else {
                                    
                                    if filteredList.count == 0 && !input.isEmpty {
                                        
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
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 1)
                
                Separator()
                
                PrimaryButton(text: Localization.string("Close")) {
                    close(nil)
                    endTextEditing()
                }
                .padding(.vertical, 16)
                .accessibilityLabel(Localization.string("Close window"))
            }
            .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, minHeight: 0, maxHeight: 524, alignment: .center)
            .background(Color.surface)
            .cornerRadius(8)
            .padding(16)
            .onAppear {
                filteredList = coinsList.filter({$0.id != ""}).sorted(by: { $0.name ?? "" < $1.name ?? ""})
            }
        }
        .foregroundColor(.onSurface)
        .animation(.none, value: UUID())
        .ignoresSafeArea(.keyboard)
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
    
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
               // .foregroundColor(isEditing || !input.isEmpty ? .onSurface : .onSurfaceDim)
                .accessibilityHidden(true)
            
            CustomTextField(placeholder:
                                Text(Localization.string("Search"))
                .foregroundColor(Color.onSurfaceDim)
                .font(.poppinsRegular(16)), isEditing: isEditing, text: $input, commit: {
                    isEditing = false
                    endTextEditing()
                })
            .onChange(of: input) {
                filteredList = getFilteredCoinsList()
            }
            .lineLimit(1)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .center)
            .background(Color.clear)
            .foregroundColor(.onSurface)
            .cornerRadius(8)
            .padding(.horizontal, 8)
            .onTapGesture {
                isEditing = true
            }
            .accessibilityElement(children: .ignore)
            .accessibilityHint(Localization.string("Double tap to edit"))
            .accessibilityValue(Localization.format("%@. Textfield", input.isEmpty ? Localization.string("Search") : input))
            
            if isEditing {
                Button(action: {
                    input = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .resizable()
                        .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                        .foregroundColor(Color.onSurface)
                }
                .accessibilityLabel(Localization.string("Clear text field"))
            }
            
        }
        .accessibilityElement(children: .contain)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .center)
        .padding(.horizontal, 16)
       // .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
              //  .stroke(Color.borderColor, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    func getFilteredCoinsList() -> [CoinsListModel] {
        let input = input.trimmingCharacters(in: .whitespacesAndNewlines)

        var filteredList = coinsList.filter({ $0.name?.containsCaseInsensitive(string: input) ?? true ||
            $0.symbol?.containsCaseInsensitive(string: input) ?? true ||
            input.isEmpty })
        
        let exactSearch = filteredList.filter({ $0.name?.lowercased() == input.lowercased() || $0.symbol?.lowercased() == input.lowercased() })
        
        if !exactSearch.isEmpty {
            
            exactSearch.forEach({ coin in
                filteredList.removeAll(where: { $0.id == coin.id })
            })
            
            filteredList.insert(contentsOf: exactSearch, at: 0)
        }
        
        if input.isEmpty {
            filteredList = coinsList.sorted(by: { $0.name ?? "" < $1.name ?? ""})
        }
        
        return filteredList.filter({ $0.id != "" })
    }
}
