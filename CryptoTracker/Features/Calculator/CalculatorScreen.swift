//
//  CalculatorScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-04-10.
//

import SwiftUI

private struct CalculatorRowItem: Identifiable {
    let id: String
    let coin: Toplist?
    let formattedAmount: String?
    let accessibilityLabel: String

    static func placeholder(index: Int) -> CalculatorRowItem {
        CalculatorRowItem(
            id: "placeholder-\(index)",
            coin: nil,
            formattedAmount: nil,
            accessibilityLabel: Localization.format("Loading currency %d of %d", index + 1, 25)
        )
    }
}

struct CalculatorScreen: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel = CalculatorViewModelImp()
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var input = "1000"
    @State private var rows: [CalculatorRowItem] = (0..<25).map { CalculatorRowItem.placeholder(index: $0) }
    @State private var isSelectingCurrency = false
    @State private var didLoad = false

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                searchFieldView

                coinsList
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarTitle(Localization.string("Converter"), displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(Localization.string("Close")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel(Localization.string("Close keyboard"))
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true

            Task {
                await viewModel.setStartData()
                await viewModel.getCalculatorPrices()
                updateRows()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, didLoad else { return }

            Task {
                await viewModel.getCalculatorPrices()
                updateRows()
            }
        }
        .refreshable {
            await viewModel.getCalculatorPrices()
            updateRows()
        }
        .sheet(isPresented: $isSelectingCurrency) {
            CurrencyOptionsSheet(
                selectedSortOption: selectedCurrency,
                newOptionSelected: {
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .converter, currency: $0.currency)
                    )
                    selectedCurrency = $0
                    viewModel.selectedCurrency = $0
                    updateRows()
                }
            )
        }
    }

    private var searchFieldView: some View {
        TextInputField(
            input: $input,
            placeholder: "",
            accessibilityValue: input,
            leadingIcon: nil,
            isSearchField: false,
            trailingView: {
                CurrencyButton(
                    currency: selectedCurrency,
                    selectNewCurrency: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .converter, sheet: .currencySelector)
                        )
                        isSelectingCurrency = true
                    }
                )
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            },
            inputDidChange: {
                scheduleRowUpdate()
            },
            onCommit: {
                if !input.isNumeric {
                    input = "0"
                } else if !input.isEmpty {
                    viewModel.input = input
                }
            }
        )
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
    }

    private var coinsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(rows) { row in
                    CalculatorRow(
                        coin: row.coin,
                        amount: row.formattedAmount
                    )
                    .accessibilityLabel(row.accessibilityLabel)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func scheduleRowUpdate() {
        DispatchQueue.main.async {
            updateRows()
        }
    }

    private func updateRows() {
        let list = viewModel.calculatorList
        let totalCount = list?.count ?? 25

        rows = (0..<totalCount).map { index in
            let coin = list?[safely: index]
            let amount = viewModel.getAmount(for: coin?.id, input: input, currency: selectedCurrency)
            let places = abs(amount ?? 0) < 0.1 ? 7 : 4

            return CalculatorRowItem(
                id: coin?.id ?? "placeholder-\(index)",
                coin: coin,
                formattedAmount: amount?.formatCurrency(threshold: .million, currency: CurrencyModel.empty),
                accessibilityLabel: Localization.format(
                    "Currency %d of %d, %@, %@ %@ equals %@ %@",
                    index + 1,
                    totalCount,
                    coin?.name ?? "",
                    input,
                    selectedCurrency.localizedName,
                    amount?.numberAccessible(maxPlaces: places) ?? "",
                    coin?.name ?? ""
                )
            )
        }
    }
}
