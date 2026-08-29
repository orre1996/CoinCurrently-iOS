//
//  AlertCoinDetails.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-29.
//

import SwiftUI

struct AlertCoinDetails: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let selectedCoin: Toplist?
    let alertCoin: AlertCoin?
    let coinPrices: [Cryptocurrency]?
    let close: (AlertCoin?, Bool) -> Void

    @State private var selectedPreSetPrice = -1
    @State private var showSign = false
    @State private var isEditing = false
    @State private var targetPrice = ""
    @State private var validInput = false
    @State private var isEditingAlert = false
    @State private var currentlySelectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var isCurrencySelectionShowing = false
    @State private var isScrollable: Bool = false
    @State private var textfieldHeight: CGFloat = 0
    @State private var viewID = UUID()
    
    @AccessibilityFocusState private var focusHeader
    
    var body: some View {
        KeyboardView {
            GeometryReader { reader in
                ZStack {
                    Color.overlayBackground.opacity(0.7)
                        .ignoresSafeArea()
                        .highPriorityGesture(DragGesture())
                        .onTapGesture {
                            if isEditing {
                                endTextEditing()
                                isEditing = false
                            } else {
                                close(nil, isEditingAlert)
                            }
                        }
                    
                    VStack(alignment: .center, spacing: 0) {
                        Text(alertCoin != nil ? "Edit price alert" : "Add price alert")
                            .font(.poppinsSemibold(20))
                            .multilineTextAlignment(.center)
                            .lineLimit(verticalSizeClass == .compact ? 1 : 2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(16)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($focusHeader)
                        
                        Separator()
                        
                        AdaptiveScroll(isScrollable: isScrollable) {
                            VStack(alignment: .center, spacing: 0) {
                                headerView
                                
                                preCalculatedAlerts
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 16)
                                
                                Text("Target price")
                                    .foregroundColor(.onSurface)
                                    .font(.poppinsRegular(12))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(EdgeInsets(top: 12, leading: 18, bottom: 6, trailing: 18))
                                
                                HStack(spacing: 16) {
                                    inputField
                                    
                                    /*CurrencyButton(
                                        title: currentlySelectedCurrency.code.uppercased(),
                                        action: {
                                            endTextEditing()
                                            isCurrencySelectionShowing = true
                                        }
                                    )*/
                                }
                                .padding(.horizontal, 16)
                                
                                let currentPrice = coinPrices?.first(where: { $0.id == selectedCoin?.id ?? "" })?.prices[currentlySelectedCurrency.code.lowercased()]

                                Text("Current price: \(currentPrice?.getFormattedString(dontShort: true, selectedCurrency: currentlySelectedCurrency) ?? "$0.00")")
                                    .font(.poppinsRegular(12))
                                    .foregroundColor(Color.onSurface)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(EdgeInsets(top: 6, leading: 18, bottom: 16, trailing: 18))
                                    .accessibilityLabel("Current price: \(currentPrice?.currencyAccessible(currency: currentlySelectedCurrency) ?? "$0.00")")
                            }
                        }
                        .id(viewID)
                        
                        Separator()
                        
                        actionButtons
                    }
                    .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, alignment: .center)
                   // .background(Color.primaryBackgroundColor)
                    .cornerRadius(8)
                    .padding(16)
                    .readSize {
                        if !isScrollable {
                            isScrollable = $0.height > reader.size.height - safeAreaInsets.resolvedTop - safeAreaInsets.resolvedBottom
                        }
                    }
                    .opacity(isCurrencySelectionShowing ? 0 : 1)
                    .accessibilityHidden(isCurrencySelectionShowing)
                    
                   /* if isCurrencySelectionShowing {
                        AlertCurrencySelection(close: { currency in
                            if let currency = currency {
                                if currentlySelectedCurrency.code != currency.code {
                                    if targetPrice.replacingOccurrences(of: ",", with: "").isNumeric || targetPrice.replacingOccurrences(of: ".", with: "").isNumeric {
                                        validInput = true
                                    } else {
                                        validInput = false
                                    }
                                }
                                
                                currentlySelectedCurrency = currency
                            }
                            
                            isCurrencySelectionShowing = false
                        })
                    }*/
                }
            }
            .onAppear {
                if let alertCoin = alertCoin {
                    targetPrice = String(alertCoin.targetPrice).removeZerosFromEnd(maximumDigits: 7)
                    isEditingAlert = true
                    showSign = true
                    
                    let currency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
                    currentlySelectedCurrency = CurrencyModel.allCurrencies.filter({ $0.code == alertCoin.preferredCurrency }).first ?? currency
                } else {
                    currentlySelectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
                }
            }
            .foregroundColor(.onSurface)
            .onChange(of: targetPrice) {
                if isEditing {
                    selectedPreSetPrice = -1
                }
            }
            .onAppDidBecomeActive {
                isScrollable = false
                textfieldHeight = 0
                viewID = UUID()
            }
            .onRotate { _ in
                asyncMain(delay: 0.2) {
                    isScrollable = false
                    textfieldHeight = 0
                    viewID = UUID()
                }
            }
            .onUIKitDidAppear {
                focusHeader = true
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            ShimmeringImage(imageUrl: selectedCoin?.image ?? "",
                            downloading: false,
                            size: 24 * min(scale, 1.5))
            .accessibilityHidden(true)

            Text("\(selectedCoin?.name ?? "") (\(selectedCoin?.symbol?.uppercased() ?? ""))")
                .font(.poppinsRegular(16))
                .foregroundColor(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(selectedCoin?.name ?? "")
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .accessibilityElement(children: .contain)
    }
    
    private var inputField: some View {
        InputField(placeholder: "Enter target price",
                   input: $targetPrice,
                   isEditing: $isEditing,
                   accessibilityText: targetPrice.isEmpty ? "Enter target price" : "\(Double(targetPrice.replacingOccurrences(of: ",", with: "."))?.currencyAccessible(currency: currentlySelectedCurrency) ?? "$0.00")",
                   leadingView: currentlySelectedCurrency.suffix ? nil : .leadingIcon(text: currentlySelectedCurrency.symbol),
                   trailingView: !currentlySelectedCurrency.suffix ? nil : .trailingIcon(text: currentlySelectedCurrency.symbol),
                   editingChanged: { isEditing in
            if !targetPrice.isEmpty {
                let newString = targetPrice.trimmedInput()
                self.targetPrice = String(Double(newString.replacingOccurrences(of: ",", with: "."))?.removeZerosFromEnd(maximumDigits: 7) ?? "0.00")
                showSign = true
            } else if isEditing {
                showSign = true
            } else {
                showSign = false
            }
            
            if targetPrice.replacingOccurrences(of: ",", with: "").isNumeric || targetPrice.replacingOccurrences(of: ".", with: "").isNumeric {
                validInput = true
            } else {
                validInput = false
            }
            
            self.isEditing = isEditing
            
            if !isEditing && targetPrice != String(selectedCoin?.current_price ?? 0.0) && !targetPrice.isEmpty {
                self.targetPrice = targetPrice.removeZerosFromEnd(maximumDigits: 7)
            }
        }, onCommit: { })
        .onChange(of: targetPrice) {
            checkIfInputIsValid()
        }
        .readSize {
            if textfieldHeight == 0 {
                textfieldHeight = $0.height
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16) {
            PrimaryButton(text: "Cancel") {
                close(nil, isEditingAlert)
            }
            .accessibilityLabel("Cancel, close window")
            
            //let price = coinPrices?.first(where: { $0.id == selectedCoin?.id ?? "" })?.prices[currentlySelectedCurrency.code.lowercased()] ?? 0
           // let targetPrice = Double(targetPrice.replacingOccurrences(of: ",", with: ".")) ?? 0
            
            PrimaryButton(text: "Save", isEnabled: validInput) {
                if selectedCoin?.id != nil, validInput && !isEditingAlert {
                    /*close(AlertCoin(id: id,
                                    aboveOrBelow: targetPrice > price ? "above" : "below",
                                    targetPrice: targetPrice,
                                    currency: currentlySelectedCurrency.code),
                          isEditingAlert)*/
                } else if validInput && isEditingAlert {
                    let editingCoin = alertCoin

                    //editingCoin?.targetPrice = targetPrice
                    //editingCoin?.aboveOrBelow = targetPrice > price ? "above" : "below"
                    //editingCoin?.currency = currentlySelectedCurrency.code
                    
                    close(editingCoin, isEditingAlert)
                }
            }
            .accessibilityLabel("Save price alert. \(!validInput ? "Enter valid target price to continue" : "Close window")")
        }
        .padding(16)
    }
    
    private func checkIfInputIsValid() {
        validInput = (targetPrice.replacingOccurrences(of: ",", with: "").isNumeric || targetPrice.replacingOccurrences(of: ".", with: "").isNumeric) && Double(targetPrice) != 0
    }
    
    private var preCalculatedAlerts: some View {
        VStack(spacing: 0) {
            Separator()
            
            let currentPrice = coinPrices?.first(where: { $0.id == selectedCoin?.id ?? "" })?.prices[currentlySelectedCurrency.code.lowercased()] ?? 0
            
            HStack(spacing: 0) {
                let targetMinus15 = (currentPrice * 0.85).removeZerosFromEnd(maximumDigits: 2)
                let targetMinus15Clean = (currentPrice * 0.85).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetMinus15
                    selectedPreSetPrice = 0
                    showSign = true
                    validInput = true
                }) {
                    Text("-15%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                       // .foregroundColor(selectedPreSetPrice == 0 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                //.background(selectedPreSetPrice == 0 ? Color.trendDown : Color.cardBackground)
                .accessibilityLabel("Set target price to -15%. \(targetMinus15Clean)")
                
                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 50, maxHeight: 50, alignment: .center)
                  //  .foregroundColor(Color.borderColor)
                
                let targetMinus10 = (currentPrice * 0.90).removeZerosFromEnd(maximumDigits: 2)
                let targetMinus10Clean = (currentPrice * 0.90).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetMinus10
                    selectedPreSetPrice = 1
                    showSign = true
                    validInput = true
                }) {
                    Text("-10%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                      //  .foregroundColor(selectedPreSetPrice == 1 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
              //  .background(selectedPreSetPrice == 1 ? Color.mainRed : Color.cardBackground)
                .accessibilityLabel("Set target price to -10%. \(targetMinus10Clean)")
                
                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 50, maxHeight: 50, alignment: .center)
                   // .foregroundColor(Color.borderColor)
                
                let targetMinus5 = (currentPrice * 0.95).removeZerosFromEnd(maximumDigits: 2)
                let targetMinus5Clean = (currentPrice * 0.95).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetMinus5
                    selectedPreSetPrice = 2
                    showSign = true
                    validInput = true
                }) {
                    Text("-5%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        //.foregroundColor(selectedPreSetPrice == 2 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                // .background(selectedPreSetPrice == 2 ? Color.mainRed : Color.cardBackground)
                .accessibilityLabel("Set target price to -5%. \(targetMinus5Clean)")
                
                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 50, maxHeight: 50, alignment: .center)
                   // .foregroundColor(Color.borderColor)
                
                let targetPlus5 = (currentPrice * 1.05).removeZerosFromEnd(maximumDigits: 2)
                let targetPlus5Clean = (currentPrice * 1.05).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetPlus5
                    selectedPreSetPrice = 3
                    showSign = true
                    validInput = true
                }) {
                    Text("+5%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                       // .foregroundColor(selectedPreSetPrice == 3 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
               // .background(selectedPreSetPrice == 3 ? Color.mainGreen : Color.cardBackground)
                .accessibilityLabel("Set target price to +5%. \(targetPlus5Clean)")

                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 50, maxHeight: 50, alignment: .center)
                   // .foregroundColor(Color.borderColor)
                
                let targetPlus10 = (currentPrice * 1.1).removeZerosFromEnd(maximumDigits: 2)
                let targetPlus10Clean = (currentPrice * 1.1).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetPlus10
                    selectedPreSetPrice = 4
                    showSign = true
                    validInput = true
                }) {
                    Text("+10%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                       // .foregroundColor(selectedPreSetPrice == 4 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                //.background(selectedPreSetPrice == 4 ? Color.mainGreen : Color.cardBackground)
                .accessibilityLabel("Set target price to +10%. \(targetPlus10Clean)")

                Rectangle()
                    .frame(minWidth: 1, maxWidth: 1, minHeight: 50, maxHeight: 50, alignment: .center)
                    //.foregroundColor(Color.borderColor)

                let targetPlus15 = (currentPrice * 1.15).removeZerosFromEnd(maximumDigits: 2)
                let targetPlus15Clean = (currentPrice * 1.15).getFormattedString(dontShort: true)
                
                Button(action: {
                    endTextEditing()
                    isEditing = false
                    targetPrice = targetPlus15
                    selectedPreSetPrice = 5
                    showSign = true
                    validInput = true
                }) {
                    Text("+15%")
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        // .foregroundColor(selectedPreSetPrice == 5 ? .cardBackground : .onSurface)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                //.background(selectedPreSetPrice == 5 ? Color.mainGreen : Color.cardBackground)
                .accessibilityLabel("Set target price to +15%. \(targetPlus15Clean)")
            }
            .font(.poppinsRegular(14))
            // .background(Color.cardBackground)
            .padding(.horizontal, 1)

            Separator()
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
    }
    
    func getCorrectCurrencySign(editing: Bool) -> CurrencyModel {
        return currentlySelectedCurrency
    }
}
