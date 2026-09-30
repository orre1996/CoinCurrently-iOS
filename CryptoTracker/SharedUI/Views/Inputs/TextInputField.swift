//
//  NumericInputField.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct TextInputField<Content: View>: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    @Binding var input: String
    let placeholder: String
    let accessibilityValue: String
    let leadingIcon: Image?
    let fillWidth: Bool
    let isSearchField: Bool
    let outlineColor: [Color]
    let trailingView: () -> Content
    let inputDidChange: () -> Void
    let onCommit: () -> Void
    
    init(
        input: Binding<String>,
        placeholder: String = "Search for coin",
        accessibilityValue: String,
        leadingIcon: Image? = .search,
        fillWidth: Bool = true,
        isSearchField: Bool = true,
        outlineColor: [Color] = [Color.outlineVariant],
        @ViewBuilder trailingView: @escaping () -> Content = { Text("") },
        inputDidChange: @escaping () -> Void,
        onCommit: @escaping () -> Void
    ) {
        self._input = input
        self.placeholder = placeholder
        self.accessibilityValue = accessibilityValue
        self.leadingIcon = leadingIcon
        self.fillWidth = fillWidth
        self.isSearchField = isSearchField
        self.outlineColor = outlineColor
        self.trailingView = trailingView
        self.inputDidChange = inputDidChange
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(spacing: 0) {
            if let leadingIcon {
                leadingIcon
                    .resizable()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(.trailing, 8)
                    .accessibilityHidden(true)
            }
            
            TextField(
                "",
                text: $input,
                prompt: Text(AppCopy.string(placeholder)).foregroundStyle(Color.onSurfaceDimmer),
            )
            .if(fillWidth) { view in
                view.frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityValue(AppCopy.format("%@, %@", accessibilityValue, AppCopy.string(isSearchField ? "search field" : "text field")))
            .accessibilityHint(AppCopy.string("Double tap to edit"))
            .accessibilityAddTraits(.isSearchField)
            .submitLabel(.search)
            .onSubmit {
                onCommit()
            }
            
            trailingView()
                .padding(.leading, 8)
        }
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
#if IS_APP
        .keyboardType(.alphabet)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 16,
                trailing: 16
            )
        )
#endif
        .background(Color.surface)
#if IS_APP
        .roundedBorderModifier(
            outlineColor: outlineColor
        )
#endif
        .onChange(of: input) {
            inputDidChange()
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}
