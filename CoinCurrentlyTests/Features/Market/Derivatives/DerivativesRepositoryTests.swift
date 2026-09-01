import Testing
@testable import CoinCurrently

@Suite("DerivativesRepository Tests")
struct DerivativesRepositoryTests {

    @Test("getDerivatives returns data on network success")
    func getDerivativesReturnsData() async {
        let mockDerivatives = [Derivative()]
        let mock = MockRepoNetworkManager(getResult: mockDerivatives)

        let repo = DerivativesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getDerivatives()
        #expect(result != nil)
        #expect(result?.count == 1)
    }

    @Test("getDerivatives returns nil when network fails")
    func getDerivativesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = DerivativesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getDerivatives()
        #expect(result == nil)
    }
}
