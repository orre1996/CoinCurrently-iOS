//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct CurrencyOptionsSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let selectedSortOption: CurrencyModel
    let newOptionSelected: (CurrencyModel) -> Void

    @State private var searchInput = ""
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Select Currency"))
            
            searchFieldView
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                bodyView
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var bodyView: some View {
        let filteredOptions = CurrencyModel.allCurrencies.filter({
            searchInput.isEmpty ||
            $0.currency.containsCaseInsensitive(string: searchInput) ||
            $0.localizedName.containsCaseInsensitive(string: searchInput) ||
            $0.code.containsCaseInsensitive(string: searchInput) ||
            $0.symbol.containsCaseInsensitive(string: searchInput)
        }).sorted(by: { $0.currency < $1.currency })
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(filteredOptions, id: \.self) { option in
                SingleSelectView(
                    title: option.localizedName,
                    subtitle: "\(option.code) (\(option.symbol))",
                    imageCase: .nothing,
                    isSelected: option == selectedSortOption,
                    didSelectOption: {
                        newOptionSelected(option)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
    
    private var searchFieldView: some View {
        TextInputField(
            input: $searchInput,
            placeholder: "Search for currency",
            accessibilityValue: searchInput.isEmpty ? Localization.string("Search for currency") : searchInput,
            inputDidChange: { },
            onCommit: { }
        )
    }
}


