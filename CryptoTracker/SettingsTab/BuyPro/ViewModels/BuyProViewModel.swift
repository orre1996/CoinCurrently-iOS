//
//  BuyProViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/15/25.
//

import StoreKit
import WidgetKit

@MainActor
protocol BuyProViewModel {
    var buttons: [TierButton]? { get }
    var selectedProduct: Product? { get set }
    var isEligableForTrial: Bool { get }
    var hasPush: Bool { get }
    var isLoading: Bool { get }
    var showSnackBar: Bool { get set }
    var snackbarMessage: String { get set }
    var offerTimeLeft: String? { get }
    var offerTimeLeftDate: Date? { get }
    var timer: Timer? { get }
    var subscribeButtonText: String { get }
    
    func setStartData() async
    func setHasPush()
    func getProducts() async
    func buyProduct() async -> Bool
    func restorePurchases() async -> Bool 
}

@Observable
class BuyProViewModelImp: BuyProViewModel {

    var buttons: [TierButton]?
    var selectedProduct: Product?
    var isEligableForTrial = false
    var hasPush = false
    var isLoading = false

    var showSnackBar = false
    var snackbarMessage = ""

    var offerTimeLeft: String?
    var offerTimeLeftDate: Date?
    
    var timer: Timer?
    
    private let storeKitManager: StoreKitManager
    private let cachedStorageManager: CachedStorageManager
    private let settingsManager: SettingsManager
    private let firebaseMananager: FirebaseManager
    private var productsStreamTask: Task<Void, Never>?
    
    init(
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        cachedStorageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
        firebaseMananager: FirebaseManager = FirebaseManagerImp.shared
    ) {
        self.storeKitManager = storeKitManager
        self.cachedStorageManager = cachedStorageManager
        self.settingsManager = settingsManager
        self.firebaseMananager = firebaseMananager
    }
    
    var subscribeButtonText: String {
        return selectedProduct?.id != promotionalName && selectedProduct?.id != welcomeName && isEligableForTrial ? "Start Your Free Trial" : "Upgrade Now"
    }
    
    func setStartData() async {
        startListeningForProductUpdates()

        guard let products = await storeKitManager.requestProducts() else {
            return
        }

        isEligableForTrial = await storeKitManager.isEligableForTrial(using: products)
        await setAvailableProducts(products)
    }

    private func startListeningForProductUpdates() {
        guard productsStreamTask == nil else { return }

        productsStreamTask = Task { [weak self] in
            guard let self else { return }

            for await products in await storeKitManager.streamProducts() {
                guard !Task.isCancelled else { return }

                isEligableForTrial = await storeKitManager.isEligableForTrial(using: products)
                await setAvailableProducts(products)
            }
        }
    }
    
    func setHasPush() {
        let current = UNUserNotificationCenter.current()
        
        current.getNotificationSettings { [weak self] settings in
            let hasPush: Bool
            switch settings.authorizationStatus {
            case .notDetermined, .denied:
                hasPush = false
            case .authorized:
                hasPush = true
            default:
                hasPush = false
            }
            Task { @MainActor in
                self?.hasPush = hasPush
            }
        }
    }
    
    func getProducts() async {
        let products = await storeKitManager.requestProducts()
        await setAvailableProducts(products)
    }
    
    func buyProduct() async -> Bool {
        guard !isLoading else { return false }
        guard let product = selectedProduct else {
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let wasEligableForTrail = isEligableForTrial
        let shouldSchedulePush = wasEligableForTrail && hasPush && selectedProduct?.id != promotionalName && selectedProduct?.id != welcomeName
        
        let productId = product.id
        let status = await storeKitManager.purchase(product)

        var hasLoggedPurchaseOutcome = false
        func logPurchase(_ outcome: SubscriptionPurchaseOutcome) {
            guard !hasLoggedPurchaseOutcome else { return }
            hasLoggedPurchaseOutcome = true
            AnalyticsManager.shared.log(
                SubscriptionPurchaseCompleted(fromScreen: .buyPro, productId: productId, outcome: outcome)
            )
        }

        switch status {
        case .invalidReceipt:
            logPurchase(.failed)
            snackbarMessage = "Purchase could not be verified. If you're testing in Xcode, upload your StoreKit public certificate to RevenueCat, or test on a device with a Sandbox Apple Account."
            showSnackBar.toggle()
            return false
        case .failed:
            logPurchase(.failed)
            snackbarMessage = "Something went wrong. Please try again later."
            showSnackBar.toggle()
            return false
        case .cancelled:
            logPurchase(.cancelled)
            return false
        case .pending:
            logPurchase(.pending)
            return false
        case .unknown:
            logPurchase(.unknown)
            return false
        case .renewal:
            logPurchase(.renewal)
            break
        case .success:
            logPurchase(.success)
            break
        }
        
        if shouldSchedulePush {
            addNotification()
        }

        asyncMain(delay: 0.5) {
            CoinCurrently.showSnackBar(
                message: "Purchase complete. Thank you so much for your support! \(shouldSchedulePush ? "A reminder has been scheduled." : "")",
                type: .success
            )
            
            NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: ["force" : true]))
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        func logRestore(_ outcome: SubscriptionRestoreOutcome) {
            AnalyticsManager.shared.log(
                SubscriptionRestoreCompleted(fromScreen: .buyPro, outcome: outcome)
            )
        }

        switch await storeKitManager.restorePurchase() {
        case .restored:
            logRestore(.restored)
            asyncMain(delay: 0.5) {
                CoinCurrently.showSnackBar(
                    message: "Purchase restored.",
                    type: .success
                )

                NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: ["force" : true]))
            }

            WidgetCenter.shared.reloadAllTimelines()
            return true
        case .nothingToRestore:
            logRestore(.nothingToRestore)
            snackbarMessage = "No purchases to restore"
            showSnackBar.toggle()
            return false
        case .cancelled:
            logRestore(.cancelled)
            return false
        case .failed:
            logRestore(.failed)
            snackbarMessage = "Something went wrong. Please try again later."
            showSnackBar.toggle()
            return false
        }
    }
    
    private func addNotification() {
        let content = UNMutableNotificationContent()
        content.title = "CoinCurrently reminder"
        content.body = "Your free trial is ending in 1 day"
        content.userInfo["cryptoID"] = String.trialReminder
        
        let date = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
        let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: String.trialReminderId, content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { _ in }
    }
    
    private func accessiblePricePerPeriod(_ price: Double, period: String, currency: CurrencyModel) -> String {
        "\(price.currencyAccessible(currency: currency)) per \(period)"
    }
    
    private func setAvailableProducts(_ products: [Product]?) async {
        guard let products else {
            return
        }
        
        let monthlyProduct = products.first(where: { $0.id == monthlyName })
        let monthlyYearlyPrice = monthlyProduct?.yearlyPrice(period: .yearly) ?? 0

        var newButtons: [TierButton] = []
        let timeLeft = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate) ?? Date()
        if let offerProduct = products.first(where: { $0.id == promotionalName }), let showOffer = await firebaseMananager.getConfigBool(key: .showPromotionalOffer), showOffer, isEligableForTrial {
            let currency = offerProduct.getCurrency() ?? CurrencyModel()
            let regularPrice = offerProduct.price.doubleValue
            
            newButtons.append(
                TierButton(
                    title: "Limited Offer",
                    formattedPrice: "\(offerProduct.introductoryPrice?.formatCurrency(threshold: FormattingThreshold.none, currency: currency) ?? "Couldn't retrieve price") / year",
                    formattedPriceAccessibilityLabel: offerProduct.introductoryPrice.map {
                        accessiblePricePerPeriod($0, period: "year", currency: currency)
                    } ?? "Couldn't retrieve price",
                    subTitle: "For the first year, then \(regularPrice.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) per year",
                    subTitleAccessibilityLabel: "For the first year, then \(accessiblePricePerPeriod(regularPrice, period: "year", currency: currency))",
                    saveAmount: abs(Double.getDifferenceInPercent(between: offerProduct.introductoryPrice ?? 0, and: monthlyYearlyPrice) ?? 0),
                    timeLeft: nil,
                    product: offerProduct
                )
            )
        } else if let welcomeProduct = products.first(where: { $0.id == welcomeName }), timeLeft > Date(), isEligableForTrial {
            let currency = welcomeProduct.getCurrency() ?? CurrencyModel()
            let regularPrice = welcomeProduct.price.doubleValue
            
            newButtons.append(
                TierButton(
                    title: "Welcome Plan",
                    formattedPrice: "\(welcomeProduct.introductoryPrice?.formatCurrency(threshold: FormattingThreshold.none, currency: currency) ?? "Couldn't retrieve price") / year",
                    formattedPriceAccessibilityLabel: welcomeProduct.introductoryPrice.map {
                        accessiblePricePerPeriod($0, period: "year", currency: currency)
                    } ?? "Couldn't retrieve price",
                    subTitle: "For the first year, then \(regularPrice.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) per year",
                    subTitleAccessibilityLabel: "For the first year, then \(accessiblePricePerPeriod(regularPrice, period: "year", currency: currency))",
                    saveAmount: abs(Double.getDifferenceInPercent(between: welcomeProduct.introductoryPrice ?? 0, and: monthlyYearlyPrice) ?? 0),
                    timeLeft: nil,
                    product: welcomeProduct
                )
            )
            
            if settingsManager.get(key: AppSettingKey.hasClosedApp) ?? false {
                await setShowWelcomeMessage()
            }
        } else if let annualProduct = products.first(where: { $0.id == yearlyName }) {
            let price = annualProduct.price.doubleValue
            let currency = annualProduct.getCurrency() ?? CurrencyModel()
            let monthlyEquivalent = price / 12
            
            newButtons.append(
                TierButton(
                    title: "Annual Plan",
                    formattedPrice: "\(price.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) / year",
                    formattedPriceAccessibilityLabel: accessiblePricePerPeriod(price, period: "year", currency: currency),
                    subTitle: "Equivalent to \(monthlyEquivalent.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) per month.",
                    subTitleAccessibilityLabel: "Equivalent to \(accessiblePricePerPeriod(monthlyEquivalent, period: "month", currency: currency))",
                    saveAmount: abs(Double.getDifferenceInPercent(between: price, and: monthlyYearlyPrice) ?? 0),
                    timeLeft: nil,
                    product: annualProduct
                )
            )
        }
        
        if let monthlyProduct = products.first(where: { $0.id == monthlyName }) {
            let currency = monthlyProduct.getCurrency() ?? CurrencyModel()
            let monthlyPrice = monthlyProduct.price.doubleValue
            let yearlyTotal = monthlyProduct.yearlyPrice(period: .monthly)
            
            newButtons.append(
                TierButton(
                    title: "Monthly Plan",
                    formattedPrice: "\(monthlyPrice.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) / month",
                    formattedPriceAccessibilityLabel: accessiblePricePerPeriod(monthlyPrice, period: "month", currency: currency),
                    subTitle: "For a total of \(yearlyTotal.formatCurrency(threshold: FormattingThreshold.none, currency: currency)) per year",
                    subTitleAccessibilityLabel: "For a total of \(accessiblePricePerPeriod(yearlyTotal, period: "year", currency: currency))",
                    saveAmount: nil,
                    timeLeft: nil,
                    product: monthlyProduct
                )
            )
        }
        
        buttons = newButtons

        if let selectedProduct,
           newButtons.contains(where: { $0.product.id == selectedProduct.id }) {
            self.selectedProduct = newButtons.first(where: { $0.product.id == selectedProduct.id })?.product
        } else {
            selectedProduct = newButtons.first?.product
        }
        
        Task {
            isEligableForTrial = await newButtons.first?.product.subscription?.isEligibleForIntroOffer ?? false
        }
    }
    
    private func setShowWelcomeMessage() async {
        var date: Date? = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate)

        if date == nil {
            date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            await cachedStorageManager.save(type: LocalStorageKeys.homeWelcomeOfferDate, data: date)
        }

        offerTimeLeftDate = date
        
        guard let date, date > Date() else {
            return
        }
        
        setWelcomeTimerDate()
        await MainActor.run {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setWelcomeTimerDate), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func setWelcomeTimerDate() {
        Task { @MainActor in
            let timeLeft = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate) ?? Date()
            
            guard timeLeft > Date() else {
                timer?.invalidate()
                timer = nil
                offerTimeLeft = nil
                await cachedStorageManager.save(type: LocalStorageKeys.didCloseWelcome, data: true)

                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: timeLeft)
            let days = components.day ?? 0
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0
            let seconds = components.second ?? 0
            
            if let index = buttons?.firstIndex(where: { $0.title == "Welcome Plan" }),
                let newTierButton = buttons?[index].copy(withTimeLeft: "Expires in \(days)d \(hours)h \(minutes)m \(seconds)s") {
                buttons?[index] = newTierButton
            }
        }
    }
}
