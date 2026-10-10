import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("ExchangesViewModel Tests")
struct ExchangesViewModelTests {

    @Test("setStartData sorts cached exchanges by trust score rank")
    func setStartDataSortsByTrustScore() async {
        let repo = MockVMExchangesRepository()
        await repo.seed([
            ExchangeModel(name: "Second", trust_score_rank: 2, trade_volume_24h_btc: 10),
            ExchangeModel(name: "First", trust_score_rank: 1, trade_volume_24h_btc: 5)
        ])
        let viewModel = ExchangesViewModelImp(
            exchangesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.setStartData()

        #expect(viewModel.selectedSortOption == .trustScoreDesc)
        #expect(viewModel.exchanges.map(\.name) == ["First", "Second"])
    }

    @Test("setNewSortOption reorders by volume")
    func setNewSortOptionReordersByVolume() async {
        let repo = MockVMExchangesRepository()
        await repo.setFetched([
            ExchangeModel(name: "Small", trade_volume_24h_btc: 1),
            ExchangeModel(name: "Large", trade_volume_24h_btc: 9)
        ])
        let viewModel = ExchangesViewModelImp(
            exchangesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )
        await viewModel.getExchanges()

        await viewModel.setNewSortOption(newSortOption: .volumeDesc)

        #expect(viewModel.exchanges.map(\.name) == ["Large", "Small"])
    }
}

private extension MockVMExchangesRepository {
    func seed(_ exchanges: [ExchangeModel]) {
        cachedExchanges = CachedData(data: exchanges, date: Date())
    }

    func setFetched(_ exchanges: [ExchangeModel]) {
        self.exchanges = exchanges
    }
}
