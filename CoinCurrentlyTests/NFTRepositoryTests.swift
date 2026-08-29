import Testing
@testable import CoinCurrently

@Suite("NFTRepository Tests")
struct NFTRepositoryTests {

    @Test("getToplist returns data on network success")
    func getToplistReturnsData() async {
        let mockToplist = [NFTToplist()]
        let mock = MockRepoNetworkManager(getResult: mockToplist)

        let repo = NFTRepositoryImp(
            networkManager: mock
        )

        let platform = NFTPlatform(id: "ethereum", name: "Ethereum")
        let result = await repo.getToplist(platform: platform, sortOption: SortOption.mktCapDesc)
        #expect(result != nil)
        #expect(result?.count == 1)
    }

    @Test("getToplist returns nil when network fails")
    func getToplistReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NFTRepositoryImp(
            networkManager: mock
        )

        let platform = NFTPlatform(id: "ethereum", name: "Ethereum")
        let result = await repo.getToplist(platform: platform, sortOption: SortOption.mktCapDesc)
        #expect(result == nil)
    }

    @Test("getNFTPlatforms returns nil when network fails")
    func getNFTPlatformsReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NFTRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNFTPlatforms()
        #expect(result == nil)
    }
}
