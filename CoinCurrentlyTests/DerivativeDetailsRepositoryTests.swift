import Testing
@testable import CoinCurrently

@Suite("DerivativeDetailsRepository Tests")
struct DerivativeDetailsRepositoryTests {

    @Test("getDerivativeDetail returns nil for nil id")
    func getDerivativeDetailWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = DerivativeDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getDerivativeDetail(id: nil)
        #expect(result == nil)
    }

    @Test("getExchangeImage returns nil for nil url")
    func getExchangeImageWithNilUrl() async {
        let mock = MockRepoNetworkManager()

        let repo = DerivativeDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getExchangeImage(imageUrl: nil)
        #expect(result == nil)
    }
}
