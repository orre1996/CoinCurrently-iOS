//
//  WatchConnectivityViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-08-27.
//

import SwiftUI
@preconcurrency import WatchConnectivity
import Combine

protocol WatchConnectivityViewModelProtocol: ObservableObject {
    var isReachable: Bool { get }
    var isSending: Bool { get }
    var isActive: Bool { get set }

    #if os(watchOS)
    func sendCurrencyModelToiPhone(currency: CurrencyModel?)
    func sendCurrencyToiPhone(currency: Toplist?, add: Bool)
    #endif
    #if os(iOS) || os(watchOS)
    func sendCurrencyModelToWatch(currency: CurrencyModel?)
    func sendCurrencyToWatch(currency: [String], add: Bool, syncing: Bool)
    #endif
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
        replyHandler([:])
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("received message: \(message)")
    }
    
    #if os(watchOS)
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
}
