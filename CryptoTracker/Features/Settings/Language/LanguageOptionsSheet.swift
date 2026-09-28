//
//  LanguageOptionsSheet.swift
//  CoinCurrently
//

import SwiftUI

struct LanguageOptionsSheet: View {
    @Environment(\.presentationMode) private var presentationMode

    let selectedOption: AppLanguagePreference
    let newOptionSelected: (AppLanguagePreference) -> Void

    @State private var searchInput = ""

    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Select Language")

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
        let filteredLanguages = AppLanguage.allCases.filter { language in
            searchInput.isEmpty ||
            language.nativeName.containsCaseInsensitive(string: searchInput) ||
            language.englishName.containsCaseInsensitive(string: searchInput) ||
            language.rawValue.containsCaseInsensitive(string: searchInput)
        }

        VStack(alignment: .leading, spacing: 4) {
            if searchInput.isEmpty {
                SingleSelectView(
                    title: "System",
                    subtitle: "Currently \(AppLanguage.matching().nativeName)",
                    imageCase: .nothing,
                    isSelected: selectedOption == .system,
                    didSelectOption: {
                        select(.system)
                    }
                )
            }

            ForEach(filteredLanguages) { language in
                SingleSelectView(
                    title: language.nativeName,
                    subtitle: language.subtitle,
                    imageCase: .nothing,
                    isSelected: selectedOption == .fixed(language),
                    didSelectOption: {
                        select(.fixed(language))
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
            placeholder: "Search for language",
            accessibilityValue: searchInput.isEmpty ? "Search for language" : searchInput,
            inputDidChange: { },
            onCommit: { }
        )
    }

    private func select(_ option: AppLanguagePreference) {
        newOptionSelected(option)
        presentationMode.wrappedValue.dismiss()
    }
}
