//
//  CoinEntity.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/16/26.
//

import AppIntents
import CryptoKit
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum CoinImageCache {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var storage: [String: Data] = [:]
    private static let diskCacheFolderName = "CoinEntityImages"

    private static var diskCacheDirectory: URL? {
        guard let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: String.groupIdentifier
        ) else { return nil }

        let directory = base.appendingPathComponent(diskCacheFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func cacheFileURL(for urlString: String) -> URL? {
        let hash = SHA256.hash(data: Data(urlString.utf8))
        let fileName = hash.map { String(format: "%02x", $0) }.joined() + ".png"
        return diskCacheDirectory?.appendingPathComponent(fileName)
    }

    static func imageData(for urlString: String) -> Data? {
        lock.lock()
        if let cached = storage[urlString] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let fileURL = cacheFileURL(for: urlString),
              let data = try? Data(contentsOf: fileURL),
              normalizedPNGData(from: data) != nil else {
            return nil
        }

        lock.lock()
        storage[urlString] = data
        lock.unlock()
        return data
    }

    private static func store(_ data: Data, for urlString: String) {
        lock.lock()
        storage[urlString] = data
        lock.unlock()

        guard let fileURL = cacheFileURL(for: urlString) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func normalizedPNGData(from data: Data) -> Data? {
        #if canImport(UIKit)
        return UIImage(data: data)?.pngData()
        #else
        return data
        #endif
    }

    static func thumbnailPNGData(from data: Data, maxPixelSize: CGFloat = 48) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }

        let scale = min(1, maxPixelSize / longestSide)
        let target = CGSize(
            width: max(1, floor(image.size.width * scale)),
            height: max(1, floor(image.size.height * scale))
        )
        let renderer = UIGraphicsImageRenderer(size: target)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return thumbnail.pngData()
        #else
        return data
        #endif
    }

    static func downloadImageData(from urlString: String) async -> Data? {
        if let cached = imageData(for: urlString) {
            return cached
        }

        if let data: Data = await NetworkManagerImp.shared.get(endpoint: .image(url: urlString)),
           let pngData = normalizedPNGData(from: data) {
            store(pngData, for: urlString)
            return pngData
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let pngData = normalizedPNGData(from: data) else {
                return nil
            }
            store(pngData, for: urlString)
            return pngData
        } catch {
            return nil
        }
    }

    static func prefetch(urlStrings: [String]) async {
        let urls = Array(Set(urlStrings.filter { !$0.isEmpty }))
        guard !urls.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for urlString in urls where imageData(for: urlString) == nil {
                group.addTask {
                    _ = await downloadImageData(from: urlString)
                }
            }
        }
    }
}

struct CoinEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Coin")
    static let defaultQuery = CoinEntityQuery()

    var id: String
    var name: String
    var symbol: String
    var imageURL: String?

    var displayRepresentation: DisplayRepresentation {
        if let imageURL,
           let cachedData = CoinImageCache.imageData(for: imageURL),
           let thumbnail = CoinImageCache.thumbnailPNGData(from: cachedData) {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(symbol.uppercased())",
                image: DisplayRepresentation.Image(data: thumbnail)
            )
        }

        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(symbol.uppercased())"
        )
    }

    init(id: String, name: String, symbol: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.imageURL = imageURL
    }

    init?(toplist: Toplist) {
        guard let id = toplist.id, !id.isEmpty else { return nil }
        self.id = id
        self.name = toplist.name ?? id
        self.symbol = toplist.symbol ?? ""
        self.imageURL = toplist.image
    }
}

struct CoinEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CoinEntity.ID]) async throws -> [CoinEntity] {
        let available = await cachedCoins()
        return identifiers.map { id in
            available.first(where: { $0.id == id })
                ?? fallbackCoins.first(where: { $0.id == id })
                ?? CoinEntity(id: id, name: id, symbol: "")
        }
    }

    func suggestedEntities() async throws -> [CoinEntity] {
        var coins = await cachedCoins()

        if coins.count < fallbackCoins.count {
            appendEntities(fallbackCoins, to: &coins)
        }

        return await prefetchImages(for: Array(coins.prefix(25)))
    }

    func defaultResult() async -> CoinEntity? {
        nil
    }

    func entities(matching string: String) async throws -> [CoinEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        if let searchResult: SearchModel = await NetworkManagerImp.shared.get(endpoint: .search(query: query)) {
            let results = searchResult.coins?.prefix(25).compactMap { result -> CoinEntity? in
                guard let id = result.id else { return nil }
                return CoinEntity(
                    id: id,
                    name: result.name ?? id,
                    symbol: result.symbol ?? "",
                    imageURL: result.thumb
                )
            } ?? []

            if !results.isEmpty {
                return await prefetchImages(for: Array(results))
            }
        }

        let available = await loadAvailableCoins()
        let filtered = available.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.symbol.localizedCaseInsensitiveContains(query)
        }
        return await prefetchImages(for: filtered)
    }

    private func prefetchImages(for entities: [CoinEntity]) async -> [CoinEntity] {
        await CoinImageCache.prefetch(urlStrings: entities.compactMap(\.imageURL))
        return entities
    }

    private func cachedCoins() async -> [CoinEntity] {
        var coins: [CoinEntity] = []
        await ToplistRepositoryImp.shared.ensureCacheLoaded()

        if let smallToplist = await ToplistRepositoryImp.shared.cachedSmallToplist?.data {
            appendCoins(from: smallToplist, to: &coins)
        }

        if let favorites = await ToplistRepositoryImp.shared.cachedFavorites?.data {
            appendCoins(from: favorites, to: &coins)
        }

        if let widgetCoins: [Toplist] = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.widgets) {
            appendCoins(from: widgetCoins, to: &coins)
        }

        return coins
    }

    private func loadAvailableCoins() async -> [CoinEntity] {
        var coins: [CoinEntity] = []

        let widgetCoins: [Toplist]? = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.widgets)
        coins.append(contentsOf: widgetCoins?.compactMap(CoinEntity.init(toplist:)) ?? [])

        await ToplistRepositoryImp.shared.ensureCacheLoaded()

        if let smallToplist = await ToplistRepositoryImp.shared.getSmallToplist() {
            appendCoins(from: smallToplist, to: &coins)
        }

        if let favorites = await ToplistRepositoryImp.shared.getFavorites() {
            appendCoins(from: favorites, to: &coins)
        }

        if coins.isEmpty {
            coins = fallbackCoins
        }

        return coins
    }

    private var fallbackCoins: [CoinEntity] {
        [
            CoinEntity(id: "bitcoin", name: "Bitcoin", symbol: "btc"),
            CoinEntity(id: "ethereum", name: "Ethereum", symbol: "eth"),
            CoinEntity(id: "solana", name: "Solana", symbol: "sol"),
            CoinEntity(id: "cardano", name: "Cardano", symbol: "ada"),
            CoinEntity(id: "ripple", name: "XRP", symbol: "xrp"),
            CoinEntity(id: "dogecoin", name: "Dogecoin", symbol: "doge")
        ]
    }

    private func appendCoins(from toplist: [Toplist], to coins: inout [CoinEntity]) {
        for item in toplist {
            guard let entity = CoinEntity(toplist: item),
                  !coins.contains(where: { $0.id == entity.id }) else { continue }
            coins.append(entity)
        }
    }

    private func appendEntities(_ entities: [CoinEntity], to coins: inout [CoinEntity]) {
        for entity in entities where !coins.contains(where: { $0.id == entity.id }) {
            coins.append(entity)
        }
    }
}
