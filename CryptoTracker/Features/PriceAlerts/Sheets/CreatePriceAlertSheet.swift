//
//  NewPriceAlertScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/20/25.
//

import SwiftUI

struct CreatePriceAlertSheet: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1

    let currencyDataModel: CurrencyDataModel?
    let selectedCurrency: CurrencyModel
    let isLoading: Bool
    let showError: Bool
    
    @Binding var isAlertByPriceSelected: Bool
    @Binding var priceInput: Double?
    @Binding var percentInput: Double?
    @Binding var isRecurringAlertOn: Bool
    @Binding var selectedDirection: ChangeDirection
    
    let selectNewCurrency: () -> Void
    let addNewAlert: (PostAlertCoin) -> Void
    
    @State private var showSnackbar: Bool = false
    @State private var headerHeight: CGFloat = 0
    @State private var bodyHeight: CGFloat = 0
    @State private var currentPriceHeight: CGFloat = 0
    @State private var buttonHeight: CGFloat = 0
    
    var currentPrice: Double? {
        return currencyDataModel?.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code)
    }
    
    var targetPrice: Double {
        let operation = selectedDirection.operation()
        let clamped = selectedDirection == .down
            ? percentInput.map { min(max($0, 0), 100) }
            : percentInput
        let change = (currentPrice ?? 0.0) * operation(1, ((clamped ?? 0) / 100))
        return change
    }
    
    var targetPercent: String {
        let change = targetPercentChange
        let decimals = change.changePercentDecimalPoints
        return (change == 0 ? "-" : ((priceInput ?? 0) >= (currentPrice ?? 0) ? "+" : "")) + change.formatted(.number.precision(.fractionLength(decimals)))
    }
    
    private var targetPercentChange: Double {
        Double.getDifferenceInPercent(between: priceInput, and: currentPrice) ?? -100.0
    }
    
    private var targetPercentAccessibilityLabel: String {
        let change = targetPercentChange
        let decimals = change.changePercentDecimalPoints
        let accessibleChange = change.numberAccessible(maxPlaces: decimals)
        return "Change from current price: \(change.directionAccessible.lowercased()) \(accessibleChange) percent"
    }
    
    private var currentPriceAccessibilityLabel: String {
        let price = currentPrice?.currencyAccessible(currency: selectedCurrency) ?? ""
        return "Current \(currencyDataModel?.name ?? "") price: \(price)"
    }
    
    var percentColor: Color {
        if Double(priceInput ?? 0) >= (currentPrice ?? 0) {
            return Color.trendUp
        } else {
            return Color.trendDown
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                DragHandle(title: "Set Price Alert")
                    .readSize {
                        headerHeight = $0.height
                    }
                
                Separator()
                    .padding(.horizontal, 16)
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        alertTypeView
                            .padding(
                                EdgeInsets(
                                    top: 24,
                                    leading: 16,
                                    bottom: 64,
                                    trailing: 16
                                )
                            )
                        
                        Text(isAlertByPriceSelected ? "Target Price" : "Target Price Change %")
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .font(.satoshiMedium(14))
                            .accessibilityHidden(true)
                            .padding(.horizontal, 16)
                        
                        Color.clear
                            .frame(height: 0)
                            .accessibilityElement()
                            .accessibilityLabel(currentPriceAccessibilityLabel)
                            .accessibilityHidden(!accessibilityVoiceOverEnabled)
                        
                        inputField
                            .padding(
                                EdgeInsets(
                                    top: 8,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 16
                                )
                            )
                        
                        if isAlertByPriceSelected {
                            percentChangeView
                                .accessibilityLabel(targetPercentAccessibilityLabel)
                                .padding(.horizontal, 16)
                        } else {
                            let formattedTargetPrice = targetPrice.formatCurrency(threshold: FormattingThreshold.none, currency: selectedCurrency).withoutSymbol
                            
                            priceChangeView(formattedTargetPrice: formattedTargetPrice)
                                .accessibilityLabel("Target Price: \(formattedTargetPrice)")
                                .padding(.horizontal, 16)
                        }
                        
                        recurringView
                            .padding(
                                EdgeInsets(
                                    top: 64,
                                    leading: 16,
                                    bottom: 24,
                                    trailing: 16
                                )
                            )
                    }
                    .readSize {
                        bodyHeight = $0.height
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                
                Separator()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 0) {
                    currentPriceView
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(
                            EdgeInsets(
                                top: 24,
                                leading: 16,
                                bottom: 12,
                                trailing: 16
                            )
                        )
                        .accessibilityHidden(accessibilityVoiceOverEnabled)
                        .multilineTextAlignment(.center)
                    
                    addAlertButtonView
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 24,
                                trailing: 16
                            )
                        )
                }
                .readSize {
                    buttonHeight = $0.height
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            SnackbarView(
                showSnackBar: $showSnackbar,
                message: .constant("Couldn’t add \(currencyDataModel?.symbol?.uppercased() ?? "coin") alert. Please try again."),
                buttonTitle: .constant(""),
                type: .failure,
                isTabbarHidden: true,
                isOverlayShowing: false,
                isPresented: .constant(false),
                reportedHeight: .constant(0),
                overlayPressed: { },
                buttonAction: { }
            )
        }
        .onAppear {
            priceInput = (currencyDataModel?.market_data?.current_price?.getConvertedCurrency(
                selectedCurrency: selectedCurrency.code
            ) ?? 0.0) * 1.1
        }
        .onChange(of: selectedCurrency) {
            priceInput = (currencyDataModel?.market_data?.current_price?.getConvertedCurrency(
                selectedCurrency: selectedCurrency.code
            ) ?? 0.0) * 1.1
        }
        .onChange(of: showError) {
            showSnackbar.toggle()
        }
        .presentationDetents([.height(max(1, headerHeight + bodyHeight + buttonHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
    }
    
    private var alertTypeView: some View {
        HStack(spacing: 8) {
            chartButton(
                title: "By Price",
                isSelected: isAlertByPriceSelected,
                action: {
                    isAlertByPriceSelected = true
                }
            )
            .accessibilityHidden(accessibilityVoiceOverEnabled)
            .accessibilityAddTraits(isAlertByPriceSelected ? .isSelected : [])
            .accessibilityLabel("Alert by price")
            
            chartButton(
                title: "By Δ%",
                isSelected: !isAlertByPriceSelected,
                action: {
                    isAlertByPriceSelected = false
                }
            )
            .accessibilityHidden(accessibilityVoiceOverEnabled)
            .accessibilityAddTraits(isAlertByPriceSelected ? [] : .isSelected)
            .accessibilityLabel("Alert by percent")
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .lineLimit(2)
        .if(accessibilityVoiceOverEnabled) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Alert type")
                .accessibilityValue(selectedAlertTypeAccessibilityValue)
                .accessibilityHint("Swipe up or down to change alert type.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        selectAdjacentAlertType(offset: 1)
                    case .decrement:
                        selectAdjacentAlertType(offset: -1)
                    @unknown default:
                        break
                    }
                }
        }
    }
    
    private var selectedAlertTypeAccessibilityValue: String {
        let index = isAlertByPriceSelected ? 0 : 1
        let label = isAlertByPriceSelected ? "Alert by price" : "Alert by percent"
        return "Type \(index + 1) of 2, \(label)."
    }
    
    private func selectAdjacentAlertType(offset: Int) {
        let currentIndex = isAlertByPriceSelected ? 0 : 1
        let newIndex = currentIndex + offset
        guard (0...1).contains(newIndex) else { return }
        isAlertByPriceSelected = newIndex == 0
    }
    
    private func chartButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceContainer)
                .font(.satoshiMedium(16))
                .padding(
                    EdgeInsets(
                        top: 12,
                        leading: 16,
                        bottom: 12,
                        trailing: 16
                    )
                )
                .background(isSelected ? Color.primary : Color.surfaceContainerHigh)
                .clipShape(Capsule())
        })
    }
    
    @ViewBuilder
    private func priceChangeView(formattedTargetPrice: String) -> some View {
        Text("Target Price")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiMedium(14))
        
        +
        
        Text(" \(formattedTargetPrice)")
            .foregroundStyle(selectedDirection == .up ? Color.trendUp : Color.trendDown)
            .font(.satoshiMedium(14))
    }
    
    @ViewBuilder
    private var percentChangeView: some View {
        Text("\(targetPercent)%")
            .foregroundStyle(percentColor)
            .font(.satoshiMedium(14))
        
        +
        
        Text(" from current Price")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiMedium(14))
    }
    
    @ViewBuilder
    private var inputField: some View {
        let priceText = "Trigger alert at \(priceInput?.formatCurrency(threshold: FormattingThreshold.none, currency: selectedCurrency) ?? "")"
        
        let decimals = percentInput?.changePercentDecimalPoints ?? 2
        let formattedPercent = percentInput?.formatted(.number.precision(.fractionLength(decimals))) ?? ""
        let percentText = "Trigger alert when \(currencyDataModel?.name ?? "") is \(selectedDirection.rawValue) \(formattedPercent) percent"
        
        NumericInputField(
            input: isAlertByPriceSelected ? $priceInput : $percentInput,
            accessibilityValue: isAlertByPriceSelected ? priceText : percentText,
            trailingView: { menuButton },
            inputDidChange: { }
        )
    }
    
    @ViewBuilder
    private var menuButton: some View {
        if isAlertByPriceSelected {
            Button(action: {
                selectNewCurrency()
            }, label: {
                HStack(spacing: 8) {
                    Text(selectedCurrency.code.uppercased())
                        .font(.satoshiBold(18))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(Color.onSurfaceContainer)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Image.trendDown
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.onSurfaceContainer)
                        .scaledToFill()
                        .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                }
            })
            .accessibilityLabel("Change currency, currently selected: \(selectedCurrency.currency)")
        } else {
            Menu {
                if !isAlertByPriceSelected {
                    ForEach(ChangeDirection.allCases, id: \.self) { direction in
                        Button(action: {
                            selectedDirection = direction
                        }, label: {
                            Text(direction.symbol)
                        })
                    }
                }
            } label: {
                ChangeButton(direction: selectedDirection, action: { })
            }
            .accessibilityLabel("Change percent direction, currently selected: \(selectedDirection.rawValue)")
        }
    }
    
    private var recurringView: some View {
        CheckboxView(
            trailingText: "Set as recurring alert",
            isChecked: $isRecurringAlertOn
        )
    }
    
    private var currentPriceView: some View {
        Text("Current \(currencyDataModel?.symbol?.uppercased() ?? "") Price ")
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiMedium(14))
            .accessibilityLabel("Current \(currencyDataModel?.name ?? "") price: ")
        
        +
        
        Text(currentPrice?.formatCurrency(threshold: FormattingThreshold.none) ?? "0000000")
            .foregroundStyle(Color.onSurface)
            .font(.satoshiMedium(14))
    }
    
    private var addAlertButtonView: some View {
        PrimaryButton(
            text: "Set Price Alert",
            isEnabled: (isAlertByPriceSelected && priceInput != nil) || (!isAlertByPriceSelected && percentInput != nil),
            isLoading: isLoading,
            fullWidth: true,
            opaqueBackground: true
        ) {
            guard let symbol = currencyDataModel?.id else {
                return
            }
            
            let target = isAlertByPriceSelected ? priceInput : targetPrice
                
            addNewAlert(
                PostAlertCoin(
                    coinId: symbol,
                    targetPrice: target ?? 0,
                    direction: target ?? 0 > currentPrice ?? 0.0 ? .above : .below,
                    resetThreshold: isRecurringAlertOn ? 6 : nil,
                    preferredCurrency: selectedCurrency.code
                )
            )
        }
    }
}
