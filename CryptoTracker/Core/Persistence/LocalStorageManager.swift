//
//  LocalStorageManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-08-03.
//

import Foundation

enum LocalStorageKeys: Keyable {
    case proStatus
    case proExpirationDate
    case lastVersion
    case widgets
    case alertPrices
    case priceAlerts
    case portfolioPies
    case portfolioPrices
    case walletRefreshDate
    case homeShowFreeTrial
    case homeNextFreeTrialDate
    case favorites
    case didClosePromotions
    case didCloseWelcome
    case homeWelcomeOfferDate
    case otherCoins
    case referralCode

    func key() -> String {
        switch self {
        case .proStatus:
            return "proStatus-1"
        case .proExpirationDate:
            return "proExpirationDate"
        case .lastVersion:
            return "lastVersion"
        case .widgets:
            return "widgets"
        case .alertPrices:
            return "alertPrices"
        case .priceAlerts:
            return "priceAlerts"
        case .portfolioPies:
            return "portfolioPies-2"
        case .portfolioPrices:
            return "portfolioPrices-1"
        case .walletRefreshDate:
            return "walletRefreshDate"
        case .homeShowFreeTrial:
            return "homeShowFreeTrial"
        case .homeNextFreeTrialDate:
            return "homeNextFreeTrialDate"
        case .favorites:
            return "favorites"
        case .didClosePromotions:
            return "didClosePromotions"
        case .didCloseWelcome:
            return "didCloseWelcome"
        case .homeWelcomeOfferDate:
            return "homeWelcomeOfferDate"
        case .otherCoins:
            return "otherCoins"
        case .referralCode:
            return "referralCode"
        }
    }
}

protocol DispatchQueuing {
  func sync<T>(execute work: () throws -> T) rethrows -> T
  func async(group: DispatchGroup?, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute work: @escaping @convention(block) () -> Void)
}

extension DispatchQueuing {
  func async(execute work: @escaping @convention(block) () -> Void) {
    async(group: nil, qos: DispatchQoS.default, flags: [], execute: work)
  }
}

private struct ClearKey: Keyable, Sendable {
    let keyValue: String
    func key() -> String { keyValue }
}

protocol CachedStorageManager: Actor {
    func save<T>(type: Keyable, data: T) where T: Decodable, T: Encodable
    func save<T>(type: String, data: T) where T: Decodable, T: Encodable
    func load<T>(type: Keyable) -> T? where T: Decodable, T: Encodable
    func load<T>(type: String) -> T? where T: Decodable, T: Encodable
    func clear(type: Keyable) -> Bool
    func purge() -> Bool
}

actor CachedStorageManagerImp: CachedStorageManager {
    private struct Container {
        var value: Any?
    }

    static let shared = CachedStorageManagerImp()

    private let storageManager: SaveAndLoadable
    private var cache: [String: Container] = [:]

    init(storageManager: SaveAndLoadable = LocalStorageManager()) {
        self.storageManager = storageManager
    }

    func save<T>(type: Keyable, data: T) where T: Decodable, T: Encodable {
        let typeKey = type.key()
        cache[typeKey] = Container(value: data as Any?)
        storageManager.save(type: typeKey, data: data)
    }

    func save<T>(type: String, data: T) where T: Decodable, T: Encodable {
        cache[type] = Container(value: data as Any?)
        storageManager.save(type: type, data: data)
    }

    func load<T>(type: Keyable) -> T? where T: Decodable, T: Encodable {
        let typeKey = type.key()
        if let container = cache[typeKey], let value = container.value as? T {
            return value
        }
        if let value: T = storageManager.load(type: typeKey) {
            cache[typeKey] = Container(value: value)
            return value
        }
        return nil
    }

    func load<T>(type: String) -> T? where T: Decodable, T: Encodable {
        if let container = cache[type], let value = container.value as? T {
            return value
        }
        if let value: T = storageManager.load(type: type) {
            cache[type] = Container(value: value)
            return value
        }
        return nil
    }

    func clear(type: Keyable) -> Bool {
        let typeKey = type.key()
        cache[typeKey] = Container(value: nil)
        let keyForClear = ClearKey(keyValue: typeKey)
        return storageManager.clear(type: keyForClear)
    }

    func purge() -> Bool {
        cache.removeAll()
        return storageManager.purge()
    }
}

private class LocalStorageManager: SaveAndLoadable {
    private static let appGroupIdentifier: String = "group.com.Cryptium.CoinCurrently"
    private static let legacyMigrationLock: NSLock = NSLock()
    nonisolated(unsafe) private static var didMigrateLegacyCoinCurrently: Bool = false

    func clear(type: Keyable) -> Bool {
        if let filePath = archiveUserFilePath(type.key()), (try? FileManager.default.removeItem(at: filePath)) != nil {
            return true
        }

        return false
    }

    fileprivate init() { }

    private static func migrateLegacyCoinCurrentlyIfNeeded(appGroupCoinCurrently: URL, fileManager: FileManager) {
        legacyMigrationLock.lock()
        defer { legacyMigrationLock.unlock() }
        guard !didMigrateLegacyCoinCurrently else { return }
        didMigrateLegacyCoinCurrently = true
        guard let documentsDirectory: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let legacyRoot: URL = documentsDirectory.appendingPathComponent("coincurrently", isDirectory: true)
        guard fileManager.fileExists(atPath: legacyRoot.path) else { return }
        guard let contents: [URL] = try? fileManager.contentsOfDirectory(at: legacyRoot, includingPropertiesForKeys: nil) else { return }
        for fileURL: URL in contents {
            let destination: URL = appGroupCoinCurrently.appendingPathComponent(fileURL.lastPathComponent)
            if !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: fileURL, to: destination)
            }
        }
    }

    func load<T: Codable>(type: String) -> T? {
        guard let filePath = archiveUserFilePath(type) else { return nil }
        do {
            let data = try Data(contentsOf: filePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = (try decoder.decode([T].self, from: data)).first
            return result
        } catch {
            return nil
        }
    }

    func save<T: Codable>(type: String, data: T) {
        if let filePath = archiveUserFilePath(type) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let encodedData = (try? encoder.encode([data])), encodedData.count > 0 {
                try? encodedData.write(to: filePath, options: .atomic)
            }
        }
    }

    func purge() -> Bool {
        if let filePath = localStoragePath() {
            return deleteUserFile(filePath)
        }
        return false
    }

    func sync() {} // Does nothing since this storage manager is synchronous

    private func archiveUserFilePath(_ path: String) -> URL? {
        if let documentsDirectory = localStoragePath() {
            return documentsDirectory.appendingPathComponent(path)
        }
        return nil
    }

    private func localStoragePath() -> URL? {
        let fileManager: FileManager = FileManager.default
        if let groupRoot: URL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
            let path: URL = groupRoot.appendingPathComponent("coincurrently", isDirectory: true)
            if !fileManager.fileExists(atPath: path.path) {
                try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
            }
            Self.migrateLegacyCoinCurrentlyIfNeeded(appGroupCoinCurrently: path, fileManager: fileManager)
            return path
        }
        if let documentsDirectory: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path: URL = documentsDirectory.appendingPathComponent("coincurrently", isDirectory: true)
            if !fileManager.fileExists(atPath: path.path) {
                try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
            }
            return path
        }
        return nil
    }

    private func deleteUserFile(_ path: URL) -> Bool {
        do {
            try FileManager().removeItem(at: path)
            return true
        } catch {
            return false
        }
    }
}

protocol SaveAndLoadable {
    func save<T: Codable>(type: String, data: T)
    @discardableResult func load<T: Codable>(type: String) -> T?
    @discardableResult func purge() -> Bool
    @discardableResult func clear(type: Keyable) -> Bool
}

protocol Keyable {
    func key() -> String
}
