import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("DerivativesViewModel Tests")
struct DerivativesViewModelTests {

    @Test("setStartData loads the cached list for the stored sort")
    func setStartDataLoadsCache() async {
        let repo = MockVMDerivativesRepository()
        await repo.seed(.openInterestDesc, [Derivative(name: "Binance", id: "binance")])
        let viewModel = DerivativesViewModelImp(
            derivativesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.setStartData()

        #expect(viewModel.selectedSortOption == .openInterestDesc)
        #expect(viewModel.derivatives.first?.id == "binance")
    }

    @Test("getDerivatives replaces the list and clears it when the sort changes")
    func getDerivativesReplacesList() async {
        let repo = MockVMDerivativesRepository()
        await repo.setFetched([Derivative(name: "Bybit", id: "bybit")])
        let viewModel = DerivativesViewModelImp(
            derivativesRepository: repo,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getDerivatives(newSortOption: .volumeDesc)

        #expect(viewModel.selectedSortOption == .volumeDesc)
        #expect(viewModel.derivatives.map(\.id) == ["bybit"])
    }
}

private extension MockVMDerivativesRepository {
    func seed(_ sort: SortOption, _ items: [Derivative]) {
        cachedDerivatives[sort.derivativesApiValue] = CachedData(data: items, date: Date())
    }

    func setFetched(_ items: [Derivative]) {
        derivatives = items
    }
}
