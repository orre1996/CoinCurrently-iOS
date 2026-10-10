import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("DerivativeDetailViewModel Tests")
struct DerivativeDetailViewModelTests {

    @Test("sort option splits perpetuals and futures")
    func sortOptionSplitsContracts() async {
        let viewModel = DerivativeDetailViewModelImp(
            derivative: Derivative(
                name: "Binance",
                id: "binance",
                tickers: [
                    DerivativeDetail(symbol: "BTC-PERP-HIGH", contract_type: "perpetual", open_interest_usd: 30),
                    DerivativeDetail(symbol: "BTC-PERP-LOW", contract_type: "perpetual", open_interest_usd: 10),
                    DerivativeDetail(symbol: "BTC-FUT", contract_type: "futures", open_interest_usd: 5)
                ]
            ),
            derivativeDetailsRepository: MockVMDerivativeDetailsRepository(),
            cryptoDetailRepository: sampleBitcoinRepository(),
            toplistRepository: MockVMToplistRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.setNewSortOption(newSortOption: .openInterestAsc)

        #expect(viewModel.perpetualList.map(\.symbol) == ["BTC-PERP-LOW", "BTC-PERP-HIGH"])
        #expect(viewModel.futuresList.map(\.symbol) == ["BTC-FUT"])
        #expect(viewModel.selectedSortOption == .openInterestAsc)
    }

    @Test("getDerativeDetail replaces the loaded exchange")
    func getDerivativeDetailReplacesExchange() async {
        let repo = MockVMDerivativeDetailsRepository()
        await repo.setDetail(Derivative(name: "Bybit", id: "bybit", tickers: []))
        let viewModel = DerivativeDetailViewModelImp(
            derivative: Derivative(name: "Binance", id: "binance"),
            derivativeDetailsRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            toplistRepository: MockVMToplistRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getDerativeDetail()

        #expect(viewModel.derativeDetail?.name == "Bybit")
    }
}

private extension MockVMDerivativeDetailsRepository {
    func setDetail(_ derivative: Derivative) {
        detail = derivative
    }
}
