import Testing
@testable import CoinCurrently

@Suite("NFTDetailRepository Tests")
struct NFTDetailRepositoryTests {

    @Test("getNFTDetail returns nil for nil id")
    func getNFTDetailWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = NFTDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNFTDetail(id: nil)
        #expect(result == nil)
    }

    @Test("getNFTPrices returns nil for nil id")
    func getNFTPricesWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = NFTDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNFTPrices(id: nil, days: "7")
        #expect(result == nil)
    }

    @Test("getNFTTickers returns nil for nil id")
    func getNFTTickersWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = NFTDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNFTTickers(id: nil)
        #expect(result == nil)
    }
}
