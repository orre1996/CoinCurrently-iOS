//
//  NetworkManager.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-12-06.
//

import Foundation
import SwiftUI

/// Protocol defining the network operations used throughout the app.
/// Conforming types can be injected for testing and dependency injection.
protocol NetworkManager: Actor {
    func setCurrentScreen(_ screen: String)
    func get<T: Decodable>(endpoint: Endpoint) async -> T?
    func getRaw(endpoint: Endpoint) async -> (data: Data, response: HTTPURLResponse)?
    func getCached<T: Decodable>(endpoint: Endpoint) async -> T?
    /// Replaces the on-disk entry for this endpoint with an encoded JSON payload (same cache key as `get`).
    func persistDecodedResponse<T: Encodable>(_ value: T, endpoint: Endpoint) async
    func post<G: Codable, T: Codable>(endpoint: Endpoint, bodyStruct: T) async -> (G?, Int)
}

actor NetworkManagerImp: NetworkManager {
    static let shared = NetworkManagerImp()
    
    private var currentScreen: String = "Loading"
    private var cache: [String: CachedData<Data>] = [:]
    private var hasLoadedCache = false
    private let decoder = JSONDecoder()
    private let session: URLSession
    private let storeKitManager: StoreKitManager
    private let firebaseManager: FirebaseManager
    private let coreDataManager: CoreDataManager
    
    init(
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        firebaseManager: FirebaseManager = FirebaseManagerImp.shared,
        coreDataManager: CoreDataManager = CoreDataManager.shared,
        session: URLSession = .shared
    ) {
        self.storeKitManager = storeKitManager
        self.firebaseManager = firebaseManager
        self.coreDataManager = coreDataManager
        self.session = session
        
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.nonConformingFloatDecodingStrategy = .throw
    }
    
    private var responseEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }
    
    func setCurrentScreen(_ screen: String) {
        currentScreen = screen
    }
    
    // MARK: - URL Building
    
    private func buildURL(for endpoint: Endpoint, pathComponent: String) -> URL? {
        guard var urlComponents = URLComponents(string: pathComponent) else {
            return nil
        }
        
        let queryItems = endpoint.queryItems
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        return urlComponents.url
    }
    
    private func showErrorIfNeeded(
        for endpoint: Endpoint,
        date: Date?,
        error: NetworkManagerError
    ) {
        if endpoint.shouldShowSnackbar {
            showSnackBar(
                message: error.errorMessage(date: date),
                type: .failure
            )
        }
    }

    private func cacheAndDecodeEmpty<T: Decodable>(cacheKey: String) async -> T? {
        let emptyData = Data("{}".utf8)
        cache[cacheKey] = CachedData(data: emptyData, date: Date())
        await coreDataManager.set(cache, forKey: .networkCache)
        return try? decoder.decode(T.self, from: emptyData)
    }
    
    // MARK: - GET
    
    public func getCached<T: Decodable>(endpoint: Endpoint) async -> T? {
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let pathComponent = await endpoint.pathComponent(hasBoughtPro: hasActiveSubscription)
        
        guard let url = buildURL(for: endpoint, pathComponent: pathComponent) else {
            return nil
        }
        
        let cacheKey = url.absoluteString
        
        if !hasLoadedCache {
            hasLoadedCache = true
            cache = await coreDataManager.get(forKey: .networkCache) ?? [:]
        }
        
        guard let cached = cache[cacheKey] else { return nil }
        
        if endpoint.shouldReturnRawData {
            return cached.data as? T
        }
        return try? decoder.decode(T.self, from: cached.data)
    }
    
    public func persistDecodedResponse<T: Encodable>(_ value: T, endpoint: Endpoint) async {
        guard !endpoint.shouldReturnRawData else { return }
        guard let encoded = try? responseEncoder.encode(value) else {
            return
        }
        
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let pathComponent = await endpoint.pathComponent(hasBoughtPro: hasActiveSubscription)
        
        guard let url = buildURL(for: endpoint, pathComponent: pathComponent) else {
            return
        }
        
        let cacheKey = url.absoluteString
        
        if !hasLoadedCache {
            hasLoadedCache = true
            cache = await coreDataManager.get(forKey: .networkCache) ?? [:]
        }
        
        cache[cacheKey] = CachedData(data: encoded, date: Date())
        await coreDataManager.set(cache, forKey: .networkCache)
    }
    
    public func getRaw(endpoint: Endpoint) async -> (data: Data, response: HTTPURLResponse)? {
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let pathComponent = await endpoint.pathComponent(hasBoughtPro: hasActiveSubscription)
        
        guard let url = buildURL(for: endpoint, pathComponent: pathComponent) else {
            showErrorIfNeeded(
                for: endpoint,
                date: nil,
                error: .invalidUrl
            )
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("\(String.platformSource)\(currentScreen)", forHTTPHeaderField: "x-source")
        request.addValue(AppSecrets.backendAPIKey, forHTTPHeaderField: "x-coin-currently-key")
        
        if endpoint.shouldAddBearerToken() {
            guard let token = await firebaseManager.getUserToken() else {
                showErrorIfNeeded(
                    for: endpoint,
                    date: nil,
                    error: .couldntGenerateIdToken
                )
                return nil
            }
            
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }
            
            if httpResponse.statusCode != 200,
               let error = NetworkManagerError.resolved(statusCode: httpResponse.statusCode, data: data) {
                print("🔴 ERROR GETTING \(endpoint) \(error.localizedDescription)")
                
                if error == .tooManyRequests, endpoint.shouldTryAgain(hasBoughtPro: hasActiveSubscription) {
                    return await getRaw(endpoint: endpoint.withPremiumVersion)
                }
                
                showErrorIfNeeded(
                    for: endpoint,
                    date: nil,
                    error: error
                )
                return nil
            }
            
            return (data, httpResponse)
        } catch {
            print("🔴 ERROR GETTING \(endpoint) \(error.localizedDescription)")
            guard (error as? URLError)?.code != .cancelled else { return nil }
            let managerError = NetworkManagerError.from(caughtError: error)
            showErrorIfNeeded(
                for: endpoint,
                date: nil,
                error: managerError
            )
            return nil
        }
    }
    
    public func get<T: Decodable>(endpoint: Endpoint) async -> T? {
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let pathComponent = await endpoint.pathComponent(hasBoughtPro: hasActiveSubscription)
        
        guard let url = buildURL(for: endpoint, pathComponent: pathComponent) else {
            showErrorIfNeeded(
                for: endpoint,
                date: nil,
                error: .invalidUrl
            )
            return nil
        }
        
        let cacheKey = url.absoluteString
        
        if !hasLoadedCache {
            hasLoadedCache = true
            cache = await coreDataManager.get(forKey: .networkCache) ?? [:]
        }
        
        let cacheValidMinutes = endpoint.cacheTimeMinutes(hasBoughtPro: hasActiveSubscription)
        let isCacheValid = { (date: Date) in
            Date().timeIntervalSince(date) <= 60 * Double(cacheValidMinutes)
        }
        
        let cached = cache[cacheKey]
        if let cached, isCacheValid(cached.date) {
            if endpoint.shouldReturnRawData {
                return cached.data as? T
            }
            return try? decoder.decode(T.self, from: cached.data)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("\(String.platformSource)\(currentScreen)", forHTTPHeaderField: "x-source")
        request.addValue(AppSecrets.backendAPIKey, forHTTPHeaderField: "x-coin-currently-key")
        
        if endpoint.shouldAddBearerToken() {
            guard let token = await firebaseManager.getUserToken() else {
                showErrorIfNeeded(
                    for: endpoint,
                    date: nil,
                    error: .couldntGenerateIdToken
                )

                return nil
            }
            
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let responseCode = (response as? HTTPURLResponse)?.statusCode,
               responseCode != 200,
               let error = NetworkManagerError.resolved(statusCode: responseCode, data: data) {
                print("🔴 ERROR GETTING \(endpoint) \(error.localizedDescription)")
                
                if error == .tooManyRequests, endpoint.shouldTryAgain(hasBoughtPro: hasActiveSubscription) {
                    return await get(endpoint: endpoint.withPremiumVersion)
                }

                if endpoint.treatsNotFoundAsEmpty, error == .notFound {
                    return await cacheAndDecodeEmpty(cacheKey: cacheKey)
                }
                
                showErrorIfNeeded(
                    for: endpoint,
                    date: cached?.date,
                    error: error
                )
                
                if let data = cached?.data {
                    return try? decoder.decode(T.self, from: data)
                } else {
                    return nil
                }
            } else {
                cache[cacheKey] = CachedData(data: data, date: Date())
                await coreDataManager.set(cache, forKey: .networkCache)
                if endpoint.shouldReturnRawData {
                    return data as? T
                }
                return try decoder.decode(T.self, from: data)
            }
        } catch {
            print("🔴 ERROR GETTING \(endpoint) \(error.localizedDescription)")
            guard (error as? URLError)?.code != .cancelled else { return nil }
            let managerError = NetworkManagerError.from(caughtError: error)
            showErrorIfNeeded(
                for: endpoint,
                date: cached?.date,
                error: managerError
            )
            if let data = cached?.data {
                return try? decoder.decode(T.self, from: data)
            } else {
                return nil
            }
        }
    }
    
    // MARK: - POST
    
    public func post<G: Codable, T: Codable>(endpoint: Endpoint, bodyStruct: T) async -> (G?, Int) {
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let pathComponent = await endpoint.pathComponent(hasBoughtPro: hasActiveSubscription)
        
        guard let url = buildURL(for: endpoint, pathComponent: pathComponent) else {
            showErrorIfNeeded(
                for: endpoint,
                date: nil,
                error: .invalidUrl
            )
            
            return (nil, NetworkManagerError.invalidUrl.rawValue)
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try? JSONEncoder().encode(bodyStruct)
            request.addValue("\(String.platformSource)\(currentScreen)", forHTTPHeaderField: "x-source")
            request.addValue(AppSecrets.backendAPIKey, forHTTPHeaderField: "x-coin-currently-key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if endpoint.shouldAddBearerToken() {
                guard let token = await firebaseManager.getUserToken() else {
                    showErrorIfNeeded(
                        for: endpoint,
                        date: nil,
                        error: .couldntGenerateIdToken
                    )
                    
                    return (nil, NetworkManagerError.couldntGenerateIdToken.rawValue)
                }
                
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                return (nil, NetworkManagerError.notFound.rawValue)
            }
            
            guard !data.isEmpty else {
                return (nil, statusCode)
            }
            
            return (try decoder.decode(G.self, from: data), statusCode)
        } catch {
            print("🔴 ERROR POSTING \(endpoint) \(error.localizedDescription)")
            guard (error as? URLError)?.code != .cancelled else {
                return (nil, NetworkManagerError.unknownError.rawValue)
            }
            let managerError = NetworkManagerError.from(caughtError: error)
            showErrorIfNeeded(
                for: endpoint,
                date: nil,
                error: managerError
            )
            return (nil, managerError.rawValue)
        }
    }
}
