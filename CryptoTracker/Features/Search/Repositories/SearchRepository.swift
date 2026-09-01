//
//  SearchRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-05.
//

import Foundation

protocol SearchRepository: Actor {
    var cachedSearches: [String: CachedData<SearchModel>] { get }
    
    func ensureCacheLoaded() async
    func getSearchResult(query: String) async -> SearchModel?
}

final actor SearchRepositoryImp: SearchRepository {
    @MainActor static let shared = SearchRepositoryImp()
    
    private let networkManager: NetworkManager
    
    private(set) var cachedSearches: [String: CachedData<SearchModel>]
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedSearches = [:]
    }
    
    func ensureCacheLoaded() async {}
    
    func getSearchResult(query: String) async -> SearchModel? {
        let searchResult: SearchModel? = await networkManager.get(endpoint: .search(query: query))

        if let searchResult {
            cachedSearches[query] = CachedData(data: searchResult, date: Date())
        }
        
        return searchResult
    }
}
