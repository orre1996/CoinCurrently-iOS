import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("SearchViewModel Tests")
struct SearchViewModelTests {

    @Test("empty query clears the result without searching")
    func emptyQueryClearsResult() async {
        let viewModel = SearchViewModelImp(searchRepository: MockVMSearchRepository())
        viewModel.searchResult = SearchModel(coins: [SearchResult(id: "bitcoin", name: "Bitcoin")])
        viewModel.lastQuery = "bitcoin"

        await viewModel.getSearchResult(query: "")

        #expect(viewModel.searchResult == nil)
        #expect(viewModel.currentlySearching == false)
    }

    @Test("a failed search shows an error")
    func failedSearchShowsError() async {
        let viewModel = SearchViewModelImp(searchRepository: MockVMSearchRepository())

        await viewModel.getSearchResult(query: "bitcoin")

        #expect(viewModel.showError)
        #expect(viewModel.searchResult == nil)
        #expect(viewModel.lastQuery == "bitcoin")
    }

    @Test("a successful search stores the result")
    func successfulSearchStoresResult() async {
        let repo = MockVMSearchRepository()
        await repo.setResult(SearchModel(coins: [SearchResult(id: "bitcoin", name: "Bitcoin")]))
        let viewModel = SearchViewModelImp(searchRepository: repo)

        await viewModel.getSearchResult(query: "Bit")

        #expect(viewModel.searchResult?.coins?.first?.id == "bitcoin")
        #expect(viewModel.showError == false)
        #expect(viewModel.currentlySearching == false)
    }

    @Test("search history keeps the latest seven unique coins")
    func searchHistoryKeepsLatestSeven() async {
        let original: [String: [SearchResult]] = SettingsManager.shared.get(key: AppSettingKey.searchHistory) ?? [:]
        defer { SettingsManager.shared.set(data: original, key: AppSettingKey.searchHistory) }

        let viewModel = SearchViewModelImp(searchRepository: MockVMSearchRepository())
        let first = SearchResult(id: "bitcoin", name: "Bitcoin")
        viewModel.appendSearchHistory(newCoin: first, screenCase: .coins)
        viewModel.appendSearchHistory(newCoin: first, screenCase: .coins)

        for index in 1...7 {
            viewModel.appendSearchHistory(newCoin: SearchResult(id: "coin-\(index)", name: "Coin \(index)"), screenCase: .coins)
        }

        let history = viewModel.searchHistory[SearchCase.coins.rawValue] ?? []
        #expect(history.count == 7)
        #expect(history.first?.id == "coin-7")
        #expect(history.contains(where: { $0.id == "bitcoin" }) == false)
    }
}

private extension MockVMSearchRepository {
    func setResult(_ model: SearchModel) {
        result = model
    }
}
