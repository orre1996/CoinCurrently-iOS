import Testing
@testable import CoinCurrently

@Suite("CategoriesRepository Tests")
struct CategoriesRepositoryTests {

    @Test("getCategories returns data on network success")
    func getCategoriesReturnsData() async {
        let mockCategories = [CryptoCategory()]
        let mock = MockRepoNetworkManager(getResult: mockCategories)

        let repo = CategoriesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getCategories(sortOption: SortOption.mktCapDesc)
        #expect(result != nil)
        #expect(result?.count == 1)
    }

    @Test("getCategories returns nil when network fails")
    func getCategoriesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = CategoriesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getCategories(sortOption: SortOption.mktCapDesc)
        #expect(result == nil)
    }
}
