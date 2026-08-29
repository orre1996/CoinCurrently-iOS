//
//  BuyProScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-07-30.
//

import SwiftUI
import WidgetKit
import StoreKit

enum SubscriptionTypes {
    case Monthly
    case Yearly
    case Offer
    case Lifetime
    case Welcome
}

enum TierType: Equatable {
    case text(String)
    case image(Image)
}

struct Tier: Equatable {
    let title: String
    let freeText: TierType
    let proText: TierType
    let accessibilityLabel: String
}

struct BuyProScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var viewModel = BuyProViewModelImp()
    
    @State private var showAllFeatures = false

    private let appFeatures: [Tier] = [
        Tier(title: "Market data sync frequency (minutes)",
             freeText: .text("15"),
             proText: .text("3"),
             accessibilityLabel: "App updates every 15 minutes with the free version and every 3 minutes with pro"),
        
        Tier(title: "Live price updates",
             freeText: .image(.minus),
             proText: .image(.check),
             accessibilityLabel: "Live price updates on coin detail pages are available with pro only"),
        
        Tier(title: "Import addresses",
             freeText: .image(.minus),
             proText: .image(.check),
             accessibilityLabel: "With coincurrently pro you can import wallet addresses"),
        
        Tier(title: "Portfolio transactions",
             freeText: .text("3"),
             proText: .image(.infinity),
             accessibilityLabel: "3 portfolio transactions can be added with the free version and unlimited with pro"),
        
        Tier(title: "Portfolio tax exports",
             freeText: .image(.minus),
             proText: .image(.check),
             accessibilityLabel: "Portfolio tax software exports are available with pro only"),
        
        Tier(title: "Home screen widgets",
             freeText: .text("8"),
             proText: .text("16"),
             accessibilityLabel: "8 home screen widgets are included in the free version and 16 with pro"),
        
        Tier(title: "Favorite coins",
             freeText: .text("2"),
             proText: .image(.infinity),
             accessibilityLabel: "2 currencies can be favorite marked with the free version and unlimited with pro"),
        
        Tier(title: "Lock screen widgets",
             freeText: .text("7"),
             proText: .text("10"),
             accessibilityLabel: "9 lock screen widgets are included in the free version and 13 with pro"),
        
        Tier(title: "News categories",
             freeText: .text("4"),
             proText: .text("8"),
             accessibilityLabel: "4 news categories are included in the free version and 8 with pro"),
        
        Tier(title: "Price alerts",
             freeText: .text("2"),
             proText: .image(.infinity),
             accessibilityLabel: "2 price alerts can be added with the free version and unlimited with pro")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            GeometryReader { reader in
                VStack(alignment: .leading, spacing: 0) {
                    closeButton
                    
                    ScrollView {
                        header
                        
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                tierHeader
                                    .accessibilityHidden(true)
                                
                                let features = showAllFeatures ? appFeatures : Array(appFeatures.prefix(4))
                                
                                ForEach(features, id: \.title) {
                                    featureRow(
                                        title: $0.title,
                                        freeTitle: $0.freeText,
                                        premiumTitle: $0.proText
                                    )
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel($0.accessibilityLabel)
                                    .padding(.vertical, $0 == features.first ? 8 : 0)
                                    
                                    if $0 != features.last {
                                        Separator()
                                    }
                                }
                            }
                            .padding(
                                EdgeInsets(
                                    top: 16,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 16
                                )
                            )
                            .cardBackground(
                                hasPadding: false
                            )
                            
                            SecondaryButton(
                                text: showAllFeatures ? "Show less features" : "Show all features",
                                fullWidth: true,
                                action: {
                                    showAllFeatures.toggle()
                                }
                            )
                            .padding(.top, 16)
                            
                            Text("Select Plan")
                                .font(.satoshiBold(22))
                                .foregroundStyle(Color.onSurfaceDim)
                                .padding(
                                    EdgeInsets(
                                        top: 32,
                                        leading: 0,
                                        bottom: 16,
                                        trailing: 0
                                    )
                                )
                                .accessibilityAddTraits(.isHeader)
                            
                            if let buttons = viewModel.buttons {
                                realButtons(buttons: buttons)
                            } else {
                                tempButtons
                            }

                            if viewModel.isEligableForTrial {
                                freeTrialInformation
                            } else {
                                Text("Cancel anytime")
                                    .padding(.top, 16)
                                    .font(.satoshiRegular(14))
                                    .foregroundStyle(Color.onSurfaceDimmer)
                            }
                            
                            termsAndConditionsView
                        }
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 32,
                                trailing: 16
                            )
                        )
                    }
                    .accessibilitySortPriority(9)
                    
                    Separator()
                    
                    subscribeButton
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .ignoresSafeArea(edges: .bottom)
            
            SnackbarView(
                showSnackBar: $viewModel.showSnackBar,
                message: $viewModel.snackbarMessage,
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
        .task {
            viewModel.setHasPush()
            await viewModel.setStartData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.setHasPush()
            default:
                break
            }
        }
    }
    
    private var closeButton: some View {
        HStack(spacing: 0) {
            Button(action: {
                Task {
                    if await viewModel.restorePurchases() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }, label: {
                Text("Restore")
                    .font(.satoshiBold(18))
                    .foregroundStyle(Color.primary)
            })
            .accessibilityLabel("Restore previous purchase")
            
            Spacer(minLength: 0)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image.cross
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .padding(8)
                    .background(Color.surfaceContainer)
                    .foregroundStyle(Color.onSurface)
                    .clipShape(Circle())
            })
            .accessibilityLabel("Close window")
        }
        .padding(
            EdgeInsets(
                top: 8,
                leading: 16,
                bottom: 8,
                trailing: 16
            )
        )
        .accessibilitySortPriority(0)
    }
    
    private var header: some View {
        HStack(spacing: 16) {
            Image.premiumLogo
                .resizable()
                .frame(width: 84, height: 84)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("CoinCurrently Pro")
                    .font(.satoshiBold(22))
                    .foregroundStyle(Color.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Upgrade to CoinCurrently Pro for enhanced features.")
                    .font(.satoshiRegular(16))
                    .foregroundStyle(Color.onSurfaceDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(2)
        .cardBackground()
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 32,
                trailing: 16
            )
        )
    }
    
    private var tierHeader: some View {
        HStack(spacing: 24) {
            Spacer(minLength: 0)
            
            MinimumTextSize(
                text: "FREE",
                extraSize: 16
            ) {
                Text("FREE")
                    .font(.satoshiBold(12))
                    .padding(
                        EdgeInsets(
                            top: 4,
                            leading: 8,
                            bottom: 4,
                            trailing: 8
                        )
                    )
                    .background(Color.surfaceContainerHigh)
                    .foregroundStyle(Color.onSurface)
                    .cornerRadius(8)
            }
            .font(.satoshiBold(16))
            
            MinimumTextSize(
                text: "FREE",
                extraSize: 16
            ) {
                Text("PRO")
                    .font(.satoshiBold(12))
                    .padding(
                        EdgeInsets(
                            top: 4,
                            leading: 8,
                            bottom: 4,
                            trailing: 8
                        )
                    )
                    .background(Color.primaryContainer)
                    .foregroundStyle(Color.primary)
                    .cornerRadius(8)
            }
            .font(.satoshiBold(16))
        }
    }
    
    private func tierButton(
        button: TierButton?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
        }, label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 12) {
                    NewShimmeringText(
                        text: button?.title ?? "00000000",
                        isDownloading: button?.title == nil
                    )
                    .font(.satoshiBold(18))
                    .foregroundColor(.primary90)
                    
                    if let saveAmount = button?.saveAmount {
                        Text("Save \(saveAmount.formatted(.number.precision(.fractionLength(2))))%")
                            .font(.satoshiBold(12))
                            .foregroundStyle(Color.primary90)
                            .padding(
                                EdgeInsets(
                                    top: 4,
                                    leading: 8,
                                    bottom: 4,
                                    trailing: 8
                                )
                            )
                            .background(Color.surfaceContainerHighest)
                            .cornerRadius(8)
                    }
                }
                
                NewShimmeringText(
                    text: button?.formattedPrice ?? "0000000000000",
                    isDownloading: button?.formattedPrice == nil
                )
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceContainer)
                .padding(.top, 4)
                .accessibilityLabel(button?.formattedPriceAccessibilityLabel ?? "")
                
                if !(button?.subTitle?.isEmpty ?? false) {
                    NewShimmeringText(
                        text: button?.subTitle ?? "0000000000000000000000",
                        isDownloading: button?.subTitle == nil
                    )
                    .font(.satoshiRegular(14))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityLabel(button?.subTitleAccessibilityLabel ?? "")
                }
                
                if let timeLeft = button?.timeLeft {
                    Text(timeLeft)
                        .font(.satoshiRegular(12))
                        .foregroundStyle(Color.onSurfaceDim)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        })
        .cardBackground(
            hasPadding: false,
            backgroundColor: isSelected ? Color.secondary15 : Color.surfaceContainer,
            cornerRadius: 12,
            outlineColor: isSelected ? .primary : .outlineVariant
        )
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.bottom, 16)
        .disabled(viewModel.isLoading)
        .accessibilityElement(children: .combine)
    }
    
    private func featureRow(
        title: String,
        freeTitle: TierType,
        premiumTitle: TierType
    ) -> some View {
        HStack(spacing: 24) {
            Text(title)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurfaceDim)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            MinimumTextSize(text: "FREE", extraSize: 16) {
                switch freeTitle {
                case .text(let string):
                    Text(string)
                case .image(let image):
                    image
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                }
            }
            .foregroundStyle(Color.onSurface)
            
            MinimumTextSize(text: "FREE", extraSize: 16) {
                switch premiumTitle {
                case .text(let string):
                    Text(string)
                case .image(let image):
                    image
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                }
            }
            .foregroundStyle(Color.primary)
        }
        .font(.satoshiBold(16))
        .padding(.vertical, 8)
        .frame(minHeight: 54)
    }
    
    private func realButtons(buttons: [TierButton]) -> some View {
        ForEach(buttons, id: \.self) { button in
            tierButton(
                button: button,
                isSelected: viewModel.selectedProduct == button.product,
                action: {
                    AnalyticsManager.shared.log(
                        SubscriptionOptionSelected(fromScreen: .buyPro, subscription: viewModel.selectedProduct?.id ?? "")
                    )
                    
                    viewModel.selectedProduct = button.product
                }
            )
        }
    }
    
    private var tempButtons: some View {
        ForEach(0..<2, id: \.self) { _ in
            tierButton(
                button: nil,
                isSelected: false,
                action: { }
            )
        }
    }
    
    @ViewBuilder
    private var freeTrialInformation: some View {
        ZStack {
            if viewModel.hasPush {
                Text("All plans include a 7-day trial, with limited offers excluded. You’ll get a push notification reminder a day before the trial ends. Cancel anytime.")
            } else {
                Text(
                    underlinedLinks(
                        "All plans include a 7-day trial, with limited offers excluded. You’ll get a push notification reminder a day before the trial ends. Please enable notifications in the app [settings](https://www.google.se) to get reminders. Cancel anytime."
                    )
                )
            }
        }
        .padding(.top, 16)
        .font(.satoshiRegular(14))
        .foregroundStyle(Color.onSurfaceDimmer)
        .tint(Color.primary)
        .environment(\.openURL, OpenURLAction { url in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            return .handled
        })
    }
    
    private var termsAndConditionsView: some View {
        Text(
            underlinedLinks(
                "By subscribing, you agree to the [Terms & Conditions](https://coincurrently.app/terms) and [Privacy Policy](https://coincurrently.app/privacy)."
            )
        )
        .padding(.top, 16)
        .font(.satoshiRegular(14))
        .foregroundStyle(Color.onSurfaceDimmer)
        .tint(Color.primary)
        .environment(\.openURL, OpenURLAction { url in
            UIApplication.shared.open(url)
            return .handled
        })
    }
    
    private func underlinedLinks(_ markdown: String) -> AttributedString {
        guard let nsString = try? NSMutableAttributedString(
            markdown: Data(markdown.utf8),
            options: .init(),
            baseURL: nil
        ) else {
            return AttributedString(markdown)
        }

        nsString.enumerateAttribute(.link, in: NSRange(location: 0, length: nsString.length)) { value, range, _ in
            guard value != nil else { return }
            nsString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }

        return AttributedString(nsString)
    }
    
    @ViewBuilder
    private var subscribeButton: some View {
        PrimaryButton(
            text: viewModel.subscribeButtonText,
            isLoading: viewModel.isLoading || viewModel.buttons == nil,
            fullWidth: true
        ) {
            AnalyticsManager.shared.log(
                BuyProPressed(fromScreen: .buyPro, subscription: viewModel.selectedProduct?.id ?? "")
            )
            
            Task {
                if await viewModel.buyProduct() {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .multilineTextAlignment(.leading)
        .disabled(viewModel.isLoading)
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
        .accessibilitySortPriority(1)
    }
}
