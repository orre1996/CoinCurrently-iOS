//
//  DeletePriceAlertOverlay.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-22.
//

import SwiftUI

struct DeletePriceAlertOverlay: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let coin: Toplist?
    let alert: AlertCoin?
    let noPressed: () -> Void
    let yesPressed: () -> Void
    
    @State private var isScrollable = false

    @AccessibilityFocusState private var focusHeader

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: Alignment(horizontal: .center, vertical: .center), content: {
                Color.overlayBackground.opacity(0.7)
                    .ignoresSafeArea()
                    .highPriorityGesture(DragGesture())
                    .onTapGesture {
                        noPressed()
                    }
                
                VStack(spacing: 16) {
                    AdaptiveScroll(isScrollable: isScrollable) {
                        VStack(spacing: 16) {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)

                                ShimmeringImage(imageUrl: coin?.image,
                                                downloading: coin == nil,
                                                size: 32 * min(scale, 1.5))
                                .padding(.trailing, 16)
                                
                                Text("\(coin?.name ?? "") (\(coin?.symbol?.uppercased() ?? ""))")
                                    .font(.poppinsSemibold(16))
                                    .foregroundColor(.onSurface)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer(minLength: 0)
                            }
                            .accessibilityHidden(true)
                            
                            /*Text("Are you sure you want to delete this price alert with a target price of \(alert?.targetPrice?.getFormattedString(dontShort: true, selectedCurrency: CurrencyModel.allCurrencies.filter({ $0.code == alert?.currency }).first) ?? "USD")?")
                                .font(.poppinsRegular(14))
                                .foregroundColor(.onSurface)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Are you sure you want to delete this \(coin?.name ?? "") price alert with a target price of \(alert?.targetPrice?.currencyAccessible(currency: getCurrencyModel(currencyCode: alert?.currency)) ?? "$0.00")?")
                                .accessibilityFocused($focusHeader)*/
                        }
                        .padding(.top, 16)
                    }
                    
                    AdaptiveStack(
                        isHorizontal: !category.isAccessibilityCategory || verticalSizeClass == .compact,
                        spacing: 16
                    ) {
                        PrimaryButton(text: "No") {
                            noPressed()
                        }
                        .accessibilityLabel("No, close window")
                        
                        PrimaryButton(text: "Yes") {
                            yesPressed()
                        }
                        .accessibilityLabel("Yes, close window")
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, minHeight: 0, alignment: .center)
                .background(Color.surfaceContainerLow)
                .cornerRadius(8)
                .padding(16)
                .readSize {
                    isScrollable = $0.height >= reader.size.height - safeAreaInsets.resolvedTop - safeAreaInsets.resolvedBottom
                }
            })
        }
        .onUIKitDidAppear {
            focusHeader = true
        }
        .onAppDidBecomeActive {
            isScrollable = false
        }
        .onRotate { _ in
            asyncMain(delay: 0.2) {
                isScrollable = false
            }
        }
    }

    func getCurrencyModel(currencyCode: String?) -> CurrencyModel {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        return CurrencyModel.allCurrencies.filter({ $0.code == currencyCode }).first ?? selectedCurrency
    }
}

#Preview {
    DeletePriceAlertOverlay(coin: nil,
                            alert: nil,
                            noPressed: { },
                            yesPressed: { })
}
