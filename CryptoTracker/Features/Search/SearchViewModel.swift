//
//  SearchViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-05.
//

import Foundation
import Combine

@MainActor
protocol SearchViewModel {
    var searchResult: SearchModel? { get }
    var lastQuery: String { get }
    var currentlySearching: Bool { get }
    var searchHistory: [String: [SearchResult]] { get }
    var showError: Bool { get }

    func getSearchResult(query: String) async
    func appendSearchHistory(newCoin: SearchResult, screenCase: SearchCase)
}

@MainActor @Observable
final class SearchViewModelImp: SearchViewModel, ObservableObject {
    var searchResult: SearchModel?
    var lastQuery = ""
    var currentlySearching = false

    private(set) var searchHistory: [String: [SearchResult]] = SettingsManager.shared.get(key: AppSettingKey.searchHistory) ?? [:]
    private(set) var showError = false
    
    private let searchRepository: SearchRepository
    
    init(
        searchRepository: SearchRepository = SearchRepositoryImp.shared
    ) {
        self.searchRepository = searchRepository
    }

    func getSearchResult(query: String) async {
        guard lastQuery != query else { return }
        
        guard !query.isEmpty else {
            searchResult = nil
            return
        }
        
        lastQuery = query.lowercased()
        currentlySearching = true
        searchResult = nil
        
        let searchResult = await searchRepository.getSearchResult(query: query)

        currentlySearching = false

        if let searchResult {
            self.searchResult = searchResult
            showError = false
        } else {
            showError = true
        }
    }
    
    func appendSearchHistory(
        newCoin: SearchResult,
        screenCase: SearchCase
    ) {
        let key = screenCase.rawValue
        var history = searchHistory[key] ?? []
        history.removeAll(where: { $0.id == newCoin.id })
        history.insert(newCoin, at: 0)
        history = Array(history.prefix(7))
        searchHistory[key] = history
        SettingsManager.shared.set(data: searchHistory, key: AppSettingKey.searchHistory)
    }
}
