//
//  WatchConnectivityViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-08-27.
//

import SwiftUI
@preconcurrency import WatchConnectivity
import Combine

private final class ReplyBox: @unchecked Sendable {
    let handler: ([String: Any]) -> Void
    init(handler: @escaping ([String: Any]) -> Void) { self.handler = handler }
    func call(_ value: [String: Any]) { handler(value) }
}

protocol WatchConnectivityViewModelProtocol: ObservableObject {
    var isReachable: Bool { get }
    var isSending: Bool { get }
    var isActive: Bool { get set }

    #if os(watchOS)
    func sendSyncCall()
    func sendCurrencyModelToiPhone(currency: CurrencyModel?)
    func sendCurrencyToiPhone(currency: Toplist?, add: Bool)
    #endif
    #if os(iOS) || os(watchOS)
    func sendCurrencyModelToWatch(currency: CurrencyModel?)
    func sendCurrencyToWatch(currency: [String], add: Bool, syncing: Bool)
    #endif
    func sendPremiumStatusToWatch()
}

@MainActor final class WatchConnectivityViewModel: NSObject, ObservableObject, WCSessionDelegate {
    
    private let session = WCSession.default
    
    @Published var isReachable = false
    @Published var isSending = false
    @Published var isActive = true
    
    @MainActor
    static let shared = WatchConnectivityViewModel()
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation did complete \(activationState.rawValue)")
        
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isReachable = isReachable
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isReachable = isReachable
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive \(session.activationState.rawValue)")
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        print("Session watch state did change \(session.activationState.rawValue)")
    }
    #endif
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        #if os(iOS)
        let hasSyncPremium = message["syncPremiumStatus"] as? String != nil
        let reply = ReplyBox(handler: replyHandler)
        Task { @MainActor in
            if hasSyncPremium {
                if self.isActive {
                    NotificationCenter.default.post(Notification(name: .syncPremiumStatus,
                                                                 object: nil,
                                                                 userInfo: ["syncPremiumStatus" : ""]))
                } else {
                    let content = UNMutableNotificationContent()
                    content.title = "Tap to sync"
                    content.body = "Open the app to sync your watch and phone"
                    content.sound = .default
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                    try? await UNUserNotificationCenter.current().add(request)
                }
                reply.call(["syncPremiumStatus" : ""])
            } else {
                reply.call([:])
            }
        }
        #endif
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("received message: \(message)")
        
        let status = message["syncPremiumStatus"] as? Int
        Task { @MainActor in
            if let status {
                NotificationCenter.default.post(Notification(name: .syncPremiumStatus,
                                                             object: nil,
                                                             userInfo: ["syncPremiumStatus" : status]))
            }
        }
    }
    
    #if os(watchOS)
    func sendSyncCall() {
        
        let message = ["syncPremiumStatus" : ""]
        
        self.isSending = true
        
        self.session.sendMessage(message, replyHandler: { [weak self] _ in
            print("reply received")
            Task { @MainActor in
                self?.isSending = false
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                print(error.localizedDescription)
                self?.isSending = false
            }
        })
    }
    
    func sendCurrencyModelToiPhone(currency: CurrencyModel?) {
        let message = ["currencyCode" : currency?.code ?? "USD"]
        
        session.sendMessage(message, replyHandler: { replyHandler in
            print(replyHandler)
        }, errorHandler: { error in
            print(error.localizedDescription)
        })
    }
    
    func sendCurrencyToiPhone(currency: Toplist?, add: Bool) {
        if let id = currency?.id {
            let message = [
                "currency": id,
                "add" : add] as [String : Any]
            
            session.sendMessage(message, replyHandler: { replyHandler in
                print(replyHandler)
            }, errorHandler: { error in
                print(error.localizedDescription)
            })
        }
    }
    #endif
    
    #if os(iOS) || os(watchOS)
    func sendCurrencyModelToWatch(currency: CurrencyModel?) {
        let message = ["currencyCode" : currency?.code ?? "USD"]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    func sendCurrencyToWatch(currency: [String], add: Bool, syncing: Bool) {
        let message = [
            "currency" : currency,
            "add" : add,
            "syncing" : syncing] as [String : Any]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    #endif
    
    func sendPremiumStatusToWatch() {
        Task { @MainActor in
            let currentSubscription: String? = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.proStatus)
            let message = [
                "syncPremiumStatus" : currentSubscription != nil,
                "isProEnabled" : true
            ]
            
            if session.isReachable {
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
        }
    }
}
