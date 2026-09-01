import Testing
@testable import CoinCurrently

@Suite("GasFeesRepository Tests")
struct GasFeesRepositoryTests {

    @Test("getGasFees returns nil when network fails")
    func getGasFeesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = GasFeesRepositoryImp(
            networkManager: mock,
            firebaseManager: MockFirebaseManager()
        )

        let result = await repo.getGasFees()
        #expect(result == nil)
    }

    @Test("getGasFeePrices returns nil when network fails")
    func getGasFeePricesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = GasFeesRepositoryImp(
            networkManager: mock,
            firebaseManager: MockFirebaseManager()
        )

        let result = await repo.getGasFeePrices()
        #expect(result == nil)
    }
}
