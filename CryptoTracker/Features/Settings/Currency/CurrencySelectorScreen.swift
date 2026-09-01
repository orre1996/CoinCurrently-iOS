//
//  AddToWidgetViewController.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-11-09.
//

import SwiftUI
import FirebaseMessaging

struct CurrencySelectorScreen: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Environment(NavigationViewModel.self) private var navigationViewModel

    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0) {
                HeaderViewNavigated(presentationMode: presentationMode, title: "Currency")
                
                Separator()
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        let currencies = CurrencyModel.allCurrencies.sorted(by: { $0.currency < $1.currency })
                        
                        ForEach(currencies, id: \.code) { currency in
                            let index = currencies.firstIndex(where: { $0.code == currency.code }) ?? 0
                            
                            CurrencyRowView(currency: currency, selectedCurrency: selectedCurrency, action: { currency in
                                selectedCurrency = currency
                                
                                SettingsManager.shared.set(data: selectedCurrency, key: GlobalSettingKey.selectedCurrency)
                                
                                Task {
                                    let sortOption: SortOption = await CachedStorageManagerImp.shared.load(type: AppSettingKey.toplistSortOption.rawValue) ?? .mktCapDesc
                                    let priceChange: PriceChange = await CachedStorageManagerImp.shared.load(type: AppSettingKey.toplistPriceChange.rawValue) ?? .sevenDays
                                    await ToplistRepositoryImp.shared.refreshForCurrencyChange(
                                        sortOption: sortOption,
                                        priceChange: priceChange
                                    )
                                    GlobalFunctions.shared.forceUpdateWidgets()
                                    NotificationCenter.default.post(name: .downloadNewToplist, object: nil)
                                }
                                
                                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { permission in
                                    if permission.authorizationStatus == .authorized {
                                        guard let fcmToken = Messaging.messaging().fcmToken, !fcmToken.isEmpty else {
                                            return
                                        }
                                        
                                        Task {
                                            await PriceAlertsRepositoryImp.shared.updateUser(
                                                fcmToken: fcmToken
                                            )
                                        }
                                    }
                                })
                            })
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Currency \(index + 1) of \(currencies.count). \(currency.currency).")
                            .accessibilityAddTraits(selectedCurrency.code == currency.code ? [.isSelected] : [])
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .listRowBackground(Color.surfaceContainerLow)
    }
}
