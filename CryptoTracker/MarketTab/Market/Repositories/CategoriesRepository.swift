//
//  CategoriesRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import Foundation

protocol CategoriesRepository: Actor {
    var cachedCategories: [String: CachedData<[CryptoCategory]>] { get }
    
    func ensureCacheLoaded() async
    func getCategories(sortOption: SortOption) async -> [CryptoCategory]?
}

final actor CategoriesRepositoryImp: CategoriesRepository {
    static let shared = CategoriesRepositoryImp()

    private let networkManager: NetworkManager

    var cachedCategories: [String: CachedData<[CryptoCategory]>]

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedCategories = [:]
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        for sortOption in SortOption.sectorOptions {
            if let categories: [CryptoCategory] = await networkManager.getCached(endpoint: .allCategories(sortOption: sortOption)) {
                cachedCategories[sortOption.categoriesApiValue] = CachedData(data: categories, date: Date())
            }
        }
    }
    
    func getCategories(sortOption: SortOption) async -> [CryptoCategory]? {
        await ensureCacheLoaded()
        let categories: [CryptoCategory]? = await networkManager.get(endpoint: .allCategories(sortOption: sortOption))
        
        if let categories {
            cachedCategories[sortOption.categoriesApiValue] = CachedData(data: categories, date: Date())
        }
        
        return categories
    }
}
