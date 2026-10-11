//
//  FirebaseManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2020-12-12.
//

import Foundation

#if IS_WATCH

/// Watch does not link Firebase. Shared networking still asks for an auth token;
/// the watch app does not call authenticated endpoints, so this returns nil.
protocol FirebaseManager: Actor {
    func getUserToken() async -> String?
}

final actor FirebaseManagerImp: FirebaseManager {
    static let shared = FirebaseManagerImp()

    private init() {}

    func getUserToken() async -> String? {
        nil
    }
}

#else

@preconcurrency import FirebaseRemoteConfig
@preconcurrency import FirebaseAuth

#if IS_APP
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseMessaging
import RevenueCat
import WidgetKit
#endif

protocol FirebaseManager: Actor {
    var fcmToken: String { get set }
    var user: User? { get set }

    func getConfig(key: RemoteConfigKeys) async -> RemoteConfigValue?
    func getConfigBool(key: RemoteConfigKeys) async -> Bool?
    func getConfigString(key: RemoteConfigKeys) async -> String?
    func getConfigJsonValue<T: Codable>(key: RemoteConfigKeys) async -> T?
    func getUserToken() async -> String?

#if IS_APP
    func login() async -> Bool
    func syncRevenueCatCustomerInfo() async
    func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult
    func compareAppVersion(with version: String?) async -> ComparisonResult
    func removeUser() async
#else
    func login() async
#endif
}

final actor FirebaseManagerImp: FirebaseManager {
    static let shared = FirebaseManagerImp()
    
    private let storeKitManager: StoreKitManager
    private let storageManger: CachedStorageManager
    
    private var remoteConfig: RemoteConfig?
    private var idToken = ""
    private var uid = ""
    
    var fcmToken: String = ""
    var user: User?
    
    
    init(
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        storageManger: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.storeKitManager = storeKitManager
        self.storageManger = storageManger
    }
    
#if IS_APP
    
    private var db: Firestore?
    
    func login() async -> Bool {
        configureFirestore()
        
        do {
            let user = try await signInAnonymously()
            
            self.user = user
            self.uid = user.uid
            self.idToken = try await user.getIDToken()
            await syncRevenueCatCustomerInfo()
            
            await getRemoteConfigs()
            await handlePromotionalOffer()
            await handleFCMToken()
            
            return await checkAppVersion()
            
        } catch {
            return false
        }
    }
    
    func syncRevenueCatCustomerInfo() async {
        RevenueCatConfigurator.configureIfNeeded()

        do {
            if !uid.isEmpty {
                _ = try await Purchases.shared.logIn(uid)
            }

            let customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            await storeKitManager.applyCustomerInfo(customerInfo)
        } catch {}
    }
    
    // MARK: - User

    func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let paddedV1 = padVersion(v1)
        let paddedV2 = padVersion(v2)
        return paddedV1.versionCompare(paddedV2)
    }
    
    func compareAppVersion(with version: String?) -> ComparisonResult {
        guard let version = version, !version.isEmpty,
              let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return .orderedSame
        }
        
        return compareVersions(currentAppVersion, version)
    }
    
    // MARK: - Helper Functions
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        
        db = Firestore.firestore()
        db?.settings = settings
    }
    
    private func handlePromotionalOffer() async {
        if let config = await getConfig(key: .showPromotionalOffer)?.boolValue, !config {
            await CachedStorageManagerImp.shared.save(type: LocalStorageKeys.didClosePromotions, data: false)
        }
    }
    
    private func handleFCMToken() async {
        if let token = Messaging.messaging().fcmToken {
            self.fcmToken = token
        }
    }
    
    private func checkAppVersion() async -> Bool {
        guard let minimumVersion =  await getConfig(key: .minimumVersion)?.stringValue else { return false }
        return compareAppVersion(with: minimumVersion) == .orderedAscending
    }
    
    private func padVersion(_ version: String) -> String {
        let components = version.split(separator: ".")
        let needed = max(3 - components.count, 0)
        return version + String(repeating: ".0", count: needed)
    }
    
    // Temporary
    func removeUser() async {
        SettingsManager.shared.purge()
        SettingsManager.shared.purgeStandardUserDefaults()

        SettingsManager.shared.setDefaults()
        
        _ = await CachedStorageManagerImp.shared.purge()
        WidgetCenter.shared.reloadAllTimelines()
 
        if let db, let querySnapshot = try? await db.collection(uid).getDocuments() {
            for document in querySnapshot.documents {
                try? await document.reference.delete()
            }
        }
        
        if let user = Auth.auth().currentUser {
            try? await user.delete()
        }
    }
    
#else
    
    func login() async {
        do {
            let user = try await signInAnonymously()
            
            self.user = user
            self.uid = user.uid
            self.idToken = try await user.getIDToken()
            
            await getRemoteConfigs()
        } catch {
            return
        }
    }
    
#endif
    
    private func signInAnonymously() async throws -> User {
        let user = try await Auth.auth().signInAnonymously().user
        return user
    }
    
    
    private func getRemoteConfigs() async {
        do {
            remoteConfig = RemoteConfig.remoteConfig()
            
            guard try await remoteConfig?.fetch() == .success else { return }
            
            try await remoteConfig?.activate()
        } catch {
            return
        }
    }
    
    func getConfig(key: RemoteConfigKeys) async -> RemoteConfigValue? {
        if remoteConfig == nil {
            await getRemoteConfigs()
        }
        
        return remoteConfig?.configValue(forKey: key.rawValue)
    }
    
    func getConfigBool(key: RemoteConfigKeys) async -> Bool? {
        await getConfig(key: key)?.boolValue
    }
    
    func getConfigString(key: RemoteConfigKeys) async -> String? {
        await getConfig(key: key)?.stringValue
    }
    
    func getConfigJsonValue<T: Codable>(key: RemoteConfigKeys) async -> T? {
        guard let configValue = await getConfig(key: key)?.dataValue else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: configValue)
        } catch {
            return nil
        }
    }
    
    func getUserToken() async -> String? {
        do {
            if let user {
                return try await user.getIDToken()
            } else {
                _ = await login()
                return self.idToken
            }
        } catch {
            return nil
        }
    }
}

#endif
