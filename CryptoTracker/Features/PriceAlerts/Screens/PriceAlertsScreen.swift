//
//  PriceAlertsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-28.
//

import SwiftUI

struct PriceAlertsScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric private var scale: CGFloat = 1

    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @State var viewModel = PriceAlertsViewModelImp()

    @State private var isLoading = false
    @State private var showError = false
    @State private var isSelectingCoin = false
    @State private var selectedCoin: CurrencyDataModel?
    @State private var tempCoin: CurrencyDataModel?
    
    @State private var selectedAlertCurrencyModel: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var isAddingAlert = false
    @State private var isSelectingCurrency = false
    
    @State private var isAlertByPriceSelected = true
    @State private var priceInput: Double? = 0.0
    @State private var percentInput: Double? = 10.0
    @State private var isRecurringAlertOn = false
    @State private var selectedDirection: ChangeDirection = .up

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0) {
                ScrollView {
                    ScrollViewReader { reader in
                        if !viewModel.hasPush {
                            enablePushNotificationsView
                        } else {
                            enableBigMoveAlertsView
                            
                            if let alerts = viewModel.alerts, viewModel.filteredToplist != nil, viewModel.alertPrices != nil {
                                if alerts.isEmpty {
                                    emptyMessage
                                } else {
                                    alertsList
                                        .padding([.horizontal, .bottom], 16)
                                }
                            } else {
                                tempList
                                    .padding([.horizontal, .bottom], 16)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitle(Localization.string("Price Alerts"), displayMode: .inline)
        .toolbar {
            Group {
                if isLoading {
                    ActivityIndicator(size: 20)
                } else if viewModel.hasPush {
                    Button(action: {
                        Task {
                            let hasBoughtPro = await viewModel.hasBoughtPro()

                            if (viewModel.alerts?.count ?? 0) >= 2 && !hasBoughtPro {
                                AnalyticsManager.shared.log(
                                    BuyProOpened(fromScreen: .priceAlerts, action: .PriceAlert)
                                )
                                showBuyPro()
                            } else {
                                AnalyticsManager.shared.log(
                                    SheetOpened(fromScreen: .priceAlerts, sheet: .coinSearch)
                                )
                                isAlertByPriceSelected = true
                                priceInput = 0.0
                                percentInput = 10.0
                                isRecurringAlertOn = false
                                selectedDirection = .up
                                isSelectingCoin = true
                            }
                        }
                    }, label: {
                        Image.add
                    })
                    .accessibilityLabel(Localization.string("Add new price alert"))
                }
            }
            .frame(width: 24, height: 24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(Localization.string("Close")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel(Localization.string("Close keyboard"))
            }
        }
        .task {
            await viewModel.setStartData()
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getFilteredToplist() }
                group.addTask { await viewModel.getPriceAlerts() }
            }
            
            viewModel.setGroups()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.checkIfUserEnabledPush()
                    
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getFilteredToplist() }
                        group.addTask { await viewModel.getPriceAlerts() }
                    }

                    viewModel.setGroups()
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getFilteredToplist() }
                group.addTask { await viewModel.getPriceAlerts() }
            }
            
            viewModel.setGroups()
        }
        .sheet(isPresented: $isSelectingCoin) {
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .priceAlerts,
                isSheet: true,
                highlightId: nil,
                hideId: nil,
                close: { id, _, _ in
                    isSelectingCoin = false
                    
                    guard let id else {
                        return
                    }

                    
                    Task {
                        isLoading = true
                        
                        defer { isLoading = false }
                        
                        guard let selectedCoin = await viewModel.getSelectedCoin(id: id) else {
                            return
                        }
                        
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .priceAlerts, sheet: .newPriceAlert)
                        )
                        
                        self.selectedCoin = selectedCoin
                    }
                }
            )
        }
        .sheet(item: $selectedCoin) {
            CreatePriceAlertSheet(
                currencyDataModel: $0,
                selectedCurrency: selectedAlertCurrencyModel,
                isLoading: isAddingAlert,
                showError: showError,
                isAlertByPriceSelected: $isAlertByPriceSelected,
                priceInput: $priceInput,
                percentInput: $percentInput,
                isRecurringAlertOn: $isRecurringAlertOn,
                selectedDirection: $selectedDirection,
                selectNewCurrency: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .priceAlerts, sheet: .currencySelector)
                    )
                    
                    tempCoin = selectedCoin
                    selectedCoin = nil
                    isSelectingCurrency = true
                },
                addNewAlert: { alert in
                    isAddingAlert = true
                    let inputType: PriceAlertInputType = isAlertByPriceSelected ? .price : .percent
                    
                    Task {
                        switch await viewModel.addPriceAlert(alertCoin: alert) {
                        case .success:
                            showSnackBar(
                                message: Localization.format("%@ alert added.", selectedCoin?.symbol?.uppercased() ?? Localization.string("Price")),
                                type: .success
                            )
                            
                            AnalyticsManager.shared.log(
                                PriceAlertAdded(
                                    fromScreen: .priceAlerts,
                                    coinName: selectedCoin?.name ?? "",
                                    isRecurring: alert.resetThreshold != nil,
                                    inputType: inputType
                                )
                            )
                            
                            selectedCoin = nil
                        case .fcmTokenUnavailable:
                            showSnackBar(
                                message: Localization.string("Something went wrong. Restart the app and try again."),
                                type: .failure
                            )
                        case .failure:
                            showError.toggle()
                        }
                        
                        isAddingAlert = false
                    }
                }
            )
        }
        .sheet(
            isPresented: $isSelectingCurrency,
            onDismiss: {
                isSelectingCurrency = false
                selectedCoin = tempCoin
            }
        ) {
            CurrencyOptionsSheet(
                selectedSortOption: selectedAlertCurrencyModel,
                newOptionSelected: {
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .priceAlerts, currency: $0.currency)
                    )
                    selectedAlertCurrencyModel = $0
                }
            )
        }
    }
    
    private var tempList: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(0..<(isPad ? 6 : 3), id: \.self) { _ in
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<(isPad ? 6 : 3), id: \.self) { index in
                        CryptoDetailAlertCellView(
                            name: "000",
                            symbol: "000",
                            alert: nil,
                            index: index,
                            alertsCount: isPad ? 6 : 3,
                            deleteAlert: { }
                        )
                        
                        if index != (isPad ? 5 : 2) {
                            Separator()
                        }
                    }
                }
                .cardBackground()
            }
        }
    }
    
    private var alertsList: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            let groups = viewModel.groups
            
            ForEach(groups, id: \.self) { group in
                let currentCoin = viewModel.getCoin(id: group)
                let alerts = viewModel.alerts?
                    .lazy
                    .filter({ $0.coinId == currentCoin?.id })
                    .sorted(by: { ($0.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) > ($1.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) }) ?? []
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(alerts.enumerated()), id: \.element) { index, alert in
                        CryptoDetailAlertCellView(
                            name: currentCoin?.name,
                            symbol: currentCoin?.symbol,
                            alert: alert,
                            index: index,
                            alertsCount: alerts.count,
                            deleteAlert: {
                                Task {
                                    isLoading = true
                                    await viewModel.deleteAlert(alert: alert)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    isLoading = false
                                    AnalyticsManager.shared.log(
                                        PriceAlertDeleted(fromScreen: .priceAlerts, coinName: currentCoin?.name ?? "")
                                    )
                                    showSnackBar(
                                        message: Localization.format("%@ alert deleted.", currentCoin?.symbol?.uppercased() ?? Localization.string("Coin")),
                                        type: .success
                                    )
                                }
                            }
                        )
                        
                        if alert != alerts.last {
                            Separator()
                        }
                    }
                }
                .cardBackground()
            }
        }
    }

    private var emptyMessage: some View {
        EmptyContent(
            title: Localization.string("No price alerts yet"),
            subTitle: Localization.string("Tap + to create your first alert.")
        )
        .padding(
            EdgeInsets(
                top: 72,
                leading: 32,
                bottom: 72,
                trailing: 32
            )
        )
    }
    
    private var enablePushNotificationsView: some View {
        EmptyContent(
            title: Localization.string("Notifications are off"),
            subTitle: Localization.string("Enable push notifications in your device settings to receive price alerts."),
            buttonTitle: Localization.string("Open Settings"),
            buttonAction: {
                AnalyticsManager.shared.log(
                    OpenNotificationSettingsPressed(fromScreen: .priceAlerts)
                )
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
        .padding(
            EdgeInsets(
                top: 72,
                leading: 32,
                bottom: 72,
                trailing: 32
            )
        )
    }
    
    private var enableBigMoveAlertsView: some View {
        SettingsToggleLockedView(
            title: "Big Move Alerts",
            subTitle: "Get notified when BTC or ETH swing more than 5% in either direction.",
            isOn: viewModel.isPriceAlertsOn
        ) {
            Task {
                isLoading = true
                await viewModel.toggleBigMover()
                isLoading = false

                if viewModel.isPriceAlertsOn {
                    AnalyticsManager.shared.log(
                        EnabledBigMoveAlerts(fromScreen: .priceAlerts)
                    )
                } else {
                    AnalyticsManager.shared.log(
                        DisabledBigMoveAlerts(fromScreen: .priceAlerts)
                    )
                }
            }
        }
        .cardBackground()
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
    
    private func getCurrencyModel(currencyCode: String) -> CurrencyModel {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        return CurrencyModel.allCurrencies.filter({ $0.code == currencyCode }).first ?? selectedCurrency
    }
}
