//
//  AppDelegate.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-24.
//

import Foundation
import SwiftUI
import Firebase
@preconcurrency import FirebaseMessaging
import FirebaseCore
import StoreKit
@preconcurrency import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    var deeplinkHelper = DeeplinkHelper()
    
    static var orientationLock = SettingsManager.shared.get(key: AppSettingKey.lockRotation) ?? false ? UIInterfaceOrientationMask.portrait : UIInterfaceOrientationMask.allButUpsideDown {
        didSet {
            UIApplication.shared.connectedScenes.forEach { scene in
                if let windowScene = scene as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationLock))
                }
            }
            
            UIApplication.shared.window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        guard !isRunningTests else { return true }
        
        _ = WidgetConfigurationIntentRegistry.supportedIntents

        Task {
            let widgetCoins: [Toplist]? = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.widgets)
            await CoinImageCache.prefetch(urlStrings: widgetCoins?.compactMap(\.image) ?? [])
        }
        
        application.accessibilityLanguage = "en"
        
        FirebaseApp.configure()
        AptabaseConfigurator.configureIfNeeded()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Task {
                await CachedStorageManagerImp.shared.save(type: LocalStorageKeys.lastVersion, data: version)
            }
        }

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handlePushNotification(userInfo: userInfo, fromUserTap: true)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (_) in
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
            AchievementStreakTracker.recordAppOpen()
            Task { @MainActor in
                await AchievementManager.shared.checkForNewUnlocks()
            }
            NotificationCenter.default.post(name: Notification.Name.backFromBackground, object: nil, userInfo: [:])
        }
        
        AchievementStreakTracker.recordAppOpen()
        Task { @MainActor in
            await AchievementManager.shared.checkForNewUnlocks()
        }
        
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SettingsManager.shared.set(data: true, key: AppSettingKey.hasClosedApp)
    }
    
    func setupPush() async -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        
        guard granted ?? false else {
            return false
        }
        
        guard let fcmToken = Messaging.messaging().fcmToken, !fcmToken.isEmpty else {
            return false
        }
        
        await PriceAlertsRepositoryImp.shared.updateUser(fcmToken: fcmToken)
        
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        handlePushNotification(userInfo: userInfo, fromUserTap: false)
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
    
    @MainActor
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        handlePushNotification(userInfo: userInfo, fromUserTap: false)
        return UIBackgroundFetchResult.newData
    }
    
    // Called when a notification is delivered to a foreground app.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        
        let cryptoID = userInfo["cryptoID"] as? String ?? ""
        let alertId = userInfo["cryptoID"] as? String
        
        Task { @MainActor in
            if cryptoID == String.trialReminder {
                showSnackBar(
                    message: Localization.string("Your free trial is ending in 1 day"),
                    type: .information
                )
            } else {
                deeplinkHelper.deepLinkUrl = cryptoID
            }
        }
        
        if let id = alertId {
            Task {
                await PriceAlertsRepositoryImp.shared.deleteLocalAlert(alertId: id)
            }
        }
        
        completionHandler([.banner, .list, .sound, .badge])
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    //Ta hand om payload här från push
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        
        Task { @MainActor in
            handlePushNotification(userInfo: userInfo, fromUserTap: true)
        }
        
        completionHandler()
    }
    
    @MainActor
    func handlePushNotification(userInfo: [AnyHashable: Any], fromUserTap: Bool) {
        let cryptoID = userInfo["cryptoID"] as? String ?? ""
        let alertId = userInfo["alertId"] as? String
        let hasSync = userInfo["sync"] as? String != nil
        
        if fromUserTap, !cryptoID.isEmpty {
            deeplinkHelper.deepLinkUrl = cryptoID
            NotificationCenter.default.post(Notification(name: .fromPush, object: nil, userInfo: [
                "cryptoID": cryptoID
            ]))
        }
        
        if hasSync {
            NotificationCenter.default.post(Notification(name: .sync, object: nil, userInfo: [
                "sync": ""
            ]))
        }
        
        if let id = alertId {
            Task {
                await PriceAlertsRepositoryImp.shared.deleteLocalAlert(alertId: id)
            }
        }
    }
    
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let fcmToken, !fcmToken.isEmpty else { return }
        
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            guard settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional else {
                return
            }
            
            await PriceAlertsRepositoryImp.shared.updateUser(fcmToken: fcmToken)
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        // Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let state = UIApplication.shared.applicationState
        guard state == .active || state == .inactive else { return }
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let state = UIApplication.shared.applicationState
        guard state == .active || state == .inactive else { return }
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
        
        NotificationCenter.default.post(name: Notification.Name.backFromBackground, object: nil, userInfo: [:])
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        deeplinkHelper.deepLinkUrl = url.absoluteString
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        deeplinkHelper.deepLinkUrl = url.absoluteString
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("Memory warning")
    }
}


extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
        // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}

class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    var shortCutAction = ""
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcutItem(shortcutItem)
        completionHandler(true)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.deeplinkHelper.deepLinkUrl = url.absoluteString
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
        
        if let response = connectionOptions.notificationResponse,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            Task { @MainActor in
                appDelegate.handlePushNotification(
                    userInfo: response.notification.request.content.userInfo,
                    fromUserTap: true
                )
            }
        }
    }
    
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        shortCutAction = shortcutItem.type
    }
}
