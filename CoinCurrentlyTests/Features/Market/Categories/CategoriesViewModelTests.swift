import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CategoriesViewModel Tests")
struct CategoriesViewModelTests {

    @Test("setStartData loads cached categories")
    func setStartDataLoadsCache() async {
        let repo = MockVMCategoriesRepository()
        await repo.seed(.mktCapDesc, [CryptoCategory(id: "defi", name: "DeFi")])
        let viewModel = CategoriesViewModelImp(
            categoriesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.setStartData()

        #expect(viewModel.categories.first?.name == "DeFi")
    }

    @Test("getCategories sorts names when asked")
    func getCategoriesSortsNames() async {
        let repo = MockVMCategoriesRepository()
        await repo.setFetched([
            CryptoCategory(name: "Zebra"),
            CryptoCategory(name: "Alpha")
        ])
        let viewModel = CategoriesViewModelImp(
            categoriesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getCategories(newSortOption: .nameAsc)

        #expect(viewModel.categories.map(\.name) == ["Alpha", "Zebra"])
        #expect(viewModel.selectedSortOption == .nameAsc)
    }
}

private extension MockVMCategoriesRepository {
    func seed(_ sort: SortOption, _ categories: [CryptoCategory]) {
        cachedCategories[sort.categoriesApiValue] = CachedData(data: categories, date: Date())
    }

    func setFetched(_ items: [CryptoCategory]) {
        categories = items
    }
}
