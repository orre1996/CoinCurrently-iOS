//
//  StoreKitManagerImp.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-05-07.
//

import Foundation
import StoreKit
import WidgetKit
import RevenueCat
#if os(iOS)
import UserNotifications
#endif

let monthlyName = "com.monthly.subscription.2"
let yearlyName = "com.yearly.subscription.2"
let promotionalName = "com.promotional.offer.subscription.2"
let welcomeName = "com.welcome.subscription.2"

/// Must match the entitlement identifier configured in the RevenueCat dashboard.
let proEntitlementIdentifier = "CoinCurrently: Crypto Tracker Pro"

enum RevenueCatConfigurator {
    static func configureIfNeeded() {
        guard !Purchases.isConfigured else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: AppSecrets.revenueCatAPIKey)
    }
}

enum TransactionState {
    case success
    case cancelled
    case pending
    case failed
    /// RevenueCat could not validate the App Store receipt (common with Xcode StoreKit Configuration testing).
    case invalidReceipt
    case renewal
    case unknown
}

enum RestorePurchaseResult: Equatable {
    /// Sync succeeded and an active subscription was found.
    case restored
    /// Sync succeeded but no active subscription was found for this Apple ID.
    case nothingToRestore
    /// User dismissed the App Store sign-in / sync UI.
    case cancelled
    /// Sync failed (network, StoreKit error, etc.).
    case failed
}

protocol StoreKitManager: Actor {
    var storeProducts: [Product]? { get }
    var updateListenerTask: Task<Void, Error>? { get }
    var currentSubscription: String? { get }
    
    func setStartData(downloadSubscriptions: Bool) async
    func fetchStoreProducts() async
    func requestProducts() async -> [Product]?
    func streamProducts() -> AsyncStream<[Product]>
    func isEligableForTrial(using products: [Product]?) async -> Bool
    func purchase(_ product: Product) async -> TransactionState
    func listenForTransaction() -> Task<Void, Error>
    func updatePurchasedStatus() async
    func restorePurchase() async -> RestorePurchaseResult
    func getSubscriptionStatus(product: Product?) async -> Bool
    func stream() -> AsyncStream<Bool>
    func applyCustomerInfo(_ customerInfo: CustomerInfo?) async
}

actor StoreKitManagerImp: StoreKitManager {
    static let shared = StoreKitManagerImp()
    
    private let storageManager: CachedStorageManager
    private var productDict: [String: String] = [:]
    private var storeProductsById: [String: StoreProduct] = [:]
    
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    private var productContinuations: [UUID: AsyncStream<[Product]>.Continuation] = [:]
    private var foregroundRefreshTask: Task<Void, Never>?
    private var offeringsRefreshTask: Task<Void, Never>?
    private var hasLoadedProductsFromOfferings = false
    private var hasStartedSubscriptionMonitoring = false
    
    var updateListenerTask: Task<Void, Error>? = nil
    var storeProducts: [Product]?
    var currentSubscription: String?
    
    init(
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.storageManager = storageManager
    }

    func setStartData(downloadSubscriptions: Bool = true) async {
        RevenueCatConfigurator.configureIfNeeded()
        currentSubscription = await storageManager.load(type: LocalStorageKeys.proStatus)
        startSubscriptionMonitoringIfNeeded()
        warmOfferingsCache()

        if downloadSubscriptions {
            await refreshSubscriptionStatusFromRevenueCat()
        }
    }
    
    func fetchStoreProducts() async {
        RevenueCatConfigurator.configureIfNeeded()
        setProductDictionary()
        startSubscriptionMonitoringIfNeeded()
        warmOfferingsCache()

        _ = await requestProducts()
        await refreshSubscriptionStatusFromRevenueCat()
    }

    private func warmOfferingsCache() {
        setProductDictionary()
        scheduleOfferingsRefresh(identifiers: Array(Set(productDict.values)))
    }

    private func startSubscriptionMonitoringIfNeeded() {
        guard !hasStartedSubscriptionMonitoring else { return }
        hasStartedSubscriptionMonitoring = true

        if updateListenerTask == nil {
            updateListenerTask = listenForTransaction()
        }

        foregroundRefreshTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .backFromBackground) {
                await refreshSubscriptionStatusFromRevenueCat()
            }
        }
    }

    private func refreshSubscriptionStatusFromRevenueCat() async {
        RevenueCatConfigurator.configureIfNeeded()

        do {
            let customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            await applyCustomerInfo(customerInfo)
        } catch {
            print("Failed to refresh RevenueCat customer info: \(error)")
            currentSubscription = await storageManager.load(type: LocalStorageKeys.proStatus)
        }
    }


    func isEligableForTrial(using products: [Product]?) async -> Bool {
        guard let product = products?.first else { return false }

        guard let storeProduct = storeProductsById[product.id] else {
            return await product.subscription?.isEligibleForIntroOffer ?? false
        }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: storeProduct)
        return eligibility == .eligible
    }
    
    private static let defaultProductDict: [String: String] = [
        "Monthly Subscription": monthlyName,
        "Yearly Subscription": yearlyName,
        "Offer Subscription": promotionalName,
        "Welcome Subscription": welcomeName,
    ]

    private func setProductDictionary() {
#if DEBUG
        if let plistPath = Bundle.main.path(forResource: "PropertyList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath),
           let plistDict = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String],
           !plistDict.isEmpty {
            productDict = plistDict
            return
        }
#endif
        productDict = Self.defaultProductDict
    }

    func requestProducts() async -> [Product]? {
        RevenueCatConfigurator.configureIfNeeded()
        setProductDictionary()

        let identifiers = Set(productDict.values)
        guard !identifiers.isEmpty else { return nil }

        if let storeProducts,
           !storeProducts.isEmpty,
           identifiers.allSatisfy({ storeProductsById[$0] != nil }) {
            if !hasLoadedProductsFromOfferings {
                scheduleOfferingsRefresh(identifiers: Array(identifiers))
            }
            return storeProducts
        }

        if let cachedOfferings = Purchases.shared.cachedOfferings,
           let products = extractProducts(from: cachedOfferings, identifiers: identifiers) {
            applyProducts(products, publishUpdate: true)
            scheduleOfferingsRefresh(identifiers: Array(identifiers))
            return products
        }

        if let offerings = try? await Purchases.shared.offerings(),
           let products = extractProducts(from: offerings, identifiers: identifiers) {
            hasLoadedProductsFromOfferings = true
            applyProducts(products, publishUpdate: true)
            return products
        }

        return await fetchProductsByIdentifier(identifiers: Array(identifiers), publishUpdate: true)
    }

    func streamProducts() -> AsyncStream<[Product]> {
        let id = UUID()

        return AsyncStream { continuation in
            productContinuations[id] = continuation

            continuation.onTermination = { _ in
                Task {
                    await self.removeProductContinuation(id)
                }
            }
        }
    }

    private func removeProductContinuation(_ id: UUID) {
        productContinuations.removeValue(forKey: id)
    }

    private func publishProducts(_ products: [Product]) {
        productContinuations.values.forEach {
            $0.yield(products)
        }
    }

    private func scheduleOfferingsRefresh(identifiers: [String]) {
        guard offeringsRefreshTask == nil else { return }

        offeringsRefreshTask = Task {
            defer { offeringsRefreshTask = nil }
            await refreshProductsFromOfferings(identifiers: Set(identifiers), publishUpdate: true)
        }
    }

    private func refreshProductsFromOfferings(
        identifiers: Set<String>,
        publishUpdate: Bool
    ) async {
        guard let offerings = try? await Purchases.shared.offerings(),
              let products = extractProducts(from: offerings, identifiers: identifiers) else {
            return
        }

        hasLoadedProductsFromOfferings = true
        applyProducts(products, publishUpdate: publishUpdate)
    }

    private func extractProducts(from offerings: Offerings, identifiers: Set<String>) -> [Product]? {
        var productsById: [String: Product] = [:]

        for package in offerings.all.values.flatMap(\.availablePackages) {
            let storeProduct = package.storeProduct
            let productId = storeProduct.productIdentifier
            guard identifiers.contains(productId) else { continue }

            storeProductsById[productId] = storeProduct
            if let product = storeProduct.sk2Product {
                productsById[productId] = product
            }
        }

        guard !productsById.isEmpty else { return nil }
        return productsById.values.sorted(by: { $0.price < $1.price })
    }

    private func fetchProductsByIdentifier(
        identifiers: [String],
        publishUpdate: Bool
    ) async -> [Product]? {
        let revenueCatProducts = await Purchases.shared.products(identifiers)
        let identifierSet = Set(identifiers)

        for storeProduct in revenueCatProducts {
            storeProductsById[storeProduct.productIdentifier] = storeProduct
        }

        var productsById: [String: Product] = [:]
        for storeProduct in revenueCatProducts {
            if let product = storeProduct.sk2Product {
                productsById[product.id] = product
            }
        }

        if productsById.count < identifiers.count,
           let storeKitProducts = try? await Product.products(for: identifiers) {
            for product in storeKitProducts {
                productsById[product.id] = product
                if storeProductsById[product.id] == nil {
                    storeProductsById[product.id] = StoreProduct(sk2Product: product)
                }
            }
        }

        let products = productsById.values
            .filter { identifierSet.contains($0.id) }
            .sorted(by: { $0.price < $1.price })
        guard !products.isEmpty else { return nil }

        applyProducts(products, publishUpdate: publishUpdate)
        return products
    }

    private func applyProducts(_ products: [Product], publishUpdate: Bool) {
        storeProducts = products

        if publishUpdate {
            publishProducts(products)
        }
    }
    
    func purchase(_ product: Product) async -> TransactionState {
        RevenueCatConfigurator.configureIfNeeded()

        guard let storeProduct = storeProductsById[product.id] else {
            return .failed
        }

        do {
            let result = try await Purchases.shared.purchase(product: storeProduct)

            if result.userCancelled {
                return .cancelled
            }

            await applyCustomerInfo(result.customerInfo)

            guard hasActiveProEntitlement(result.customerInfo) else {
                return .pending
            }

            return .success
        } catch {
            return transactionState(for: error)
        }
    }
    
    nonisolated func listenForTransaction() -> Task<Void, Error> {
        Task.detached {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await StoreKitManagerImp.shared.applyCustomerInfo(customerInfo)
            }
        }
    }
    
    func updatePurchasedStatus() async {
        await refreshSubscriptionStatusFromRevenueCat()
    }
    
    func restorePurchase() async -> RestorePurchaseResult {
        RevenueCatConfigurator.configureIfNeeded()

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await applyCustomerInfo(customerInfo)

            if currentSubscription != nil {
                return .restored
            }
            return .nothingToRestore
        } catch {
            if transactionState(for: error) == .cancelled {
                return .cancelled
            }
            return .failed
        }
    }
    
    func getSubscriptionStatus(product: Product?) async -> Bool {
        RevenueCatConfigurator.configureIfNeeded()

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return hasActiveProEntitlement(customerInfo)
        } catch {
            return currentSubscription != nil
        }
    }
    
    func stream() -> AsyncStream<Bool> {
        let id = UUID()
        
        return AsyncStream { continuation in
            continuations[id] = continuation
            
            continuation.onTermination = { _ in
                Task {
                    await self.remove(id)
                }
            }
        }
    }
    
    private func remove(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    func publish(_ hasActiveSubscription: Bool) {
        continuations.values.forEach {
            $0.yield(hasActiveSubscription)
        }
    }

    private func isInvalidReceiptError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == ErrorCode.errorDomain,
           ErrorCode(rawValue: nsError.code) == .invalidReceiptError {
            return true
        }
        if nsError.userInfo["rc_backend_error_code"] as? Int == 7103 {
            return true
        }
        if nsError.userInfo["readable_error_code"] as? String == "INVALID_RECEIPT" {
            return true
        }
        return false
    }

    private func transactionState(for error: Error) -> TransactionState {
        if isInvalidReceiptError(error) {
            print(
                """
                RevenueCat receipt validation failed (INVALID_RECEIPT).
                If you use Product.storekit in the Xcode scheme, upload the StoreKit public certificate \
                in the RevenueCat dashboard (Editor → Save Public Certificate in Xcode).
                For device testing, use a Sandbox Apple Account and configure the In-App Purchase Key in RevenueCat.
                Bundle ID must match: Cryptium.Cryptocurrently1
                """
            )
            return .invalidReceipt
        }

        let nsError = error as NSError
        guard nsError.domain == ErrorCode.errorDomain,
              let errorCode = ErrorCode(rawValue: nsError.code) else {
            return .failed
        }

        switch errorCode {
        case .paymentPendingError:
            return .pending
        case .purchaseCancelledError:
            return .cancelled
        default:
            return .failed
        }
    }

    func applyCustomerInfo(_ customerInfo: CustomerInfo?) async {
        let newSubscriptionId = customerInfo.flatMap(subscriptionProductId(from:))
        await persistSubscriptionState(newSubscriptionId: newSubscriptionId)
    }

    private func hasActiveProEntitlement(_ customerInfo: CustomerInfo) -> Bool {
        if customerInfo.entitlements[proEntitlementIdentifier]?.isActive == true {
            return true
        }
        return !customerInfo.entitlements.active.isEmpty
    }

    private func subscriptionProductId(from customerInfo: CustomerInfo) -> String? {
        guard hasActiveProEntitlement(customerInfo) else {
            return nil
        }

        if let configuredEntitlement = customerInfo.entitlements[proEntitlementIdentifier],
           configuredEntitlement.isActive {
            let productId = configuredEntitlement.productIdentifier
            if !productId.isEmpty {
                return productId
            }
        }

        for entitlement in customerInfo.entitlements.active.values {
            let productId = entitlement.productIdentifier
            if !productId.isEmpty {
                return productId
            }
        }

        return customerInfo.activeSubscriptions.first
    }

    private var runsInMainIOSApplication: Bool {
        #if os(iOS)
        guard Bundle.main.bundleURL.pathExtension == "app" else { return false }
        return !Bundle.main.bundlePath.contains("Watch")
        #else
        return false
        #endif
    }

    private func persistSubscriptionState(newSubscriptionId: String?) async {
        #if os(iOS)
        if newSubscriptionId == nil, runsInMainIOSApplication {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        #endif

        if newSubscriptionId != currentSubscription {
            WidgetCenter.shared.reloadAllTimelines()
        }

        let previousSubscription = currentSubscription
        currentSubscription = newSubscriptionId

        if let newSubscriptionId {
            await storageManager.save(type: LocalStorageKeys.proStatus, data: newSubscriptionId)
        } else {
            _ = await storageManager.clear(type: LocalStorageKeys.proStatus)
        }

        publish(newSubscriptionId != nil)

        if previousSubscription != newSubscriptionId {
            asyncMain {
                NotificationCenter.default.post(name: .subscriptionStatusDidChange, object: nil)
            }
        }

        #if os(iOS)
        if newSubscriptionId != nil, runsInMainIOSApplication {
            asyncMain {
                NotificationCenter.default.post(Notification(name: .checkForBannedUser, object: nil, userInfo: [:]))
            }
        }
        #endif
    }
}
