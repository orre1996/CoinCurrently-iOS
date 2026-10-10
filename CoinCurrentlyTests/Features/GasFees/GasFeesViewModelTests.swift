import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("GasFeesViewModel Tests")
struct GasFeesViewModelTests {

    @Test("setStartData loads fees and ethereum from cache")
    func setStartDataLoadsCache() async {
        let gas = MockVMGasFeesRepository()
        await gas.seed(fees: sampleFees(price: "20"), prices: sampleFees(price: "15"))
        let toplist = MockVMToplistRepository()
        await toplist.seedSmall([
            Toplist(id: "bitcoin", name: "Bitcoin"),
            Toplist(id: "ethereum", name: "Ethereum", current_price: 2_000)
        ])
        let viewModel = GasFeesViewModelImp(
            gasFeesRepository: gas,
            toplistRepository: toplist,
            cryptoDetailRepository: MockVMCryptoDetailRepository()
        )

        await viewModel.setStartData()

        #expect(viewModel.gasFees?.gasFeeData?.first?.proposeGasPrice == "20")
        #expect(viewModel.ethereum?.id == "ethereum")
        #expect(viewModel.prices.count == 3)
    }

    @Test("getGasPrice multiplies gwei, gas units, and the eth price")
    func getGasPriceMultipliesCost() async {
        let viewModel = GasFeesViewModelImp(
            gasFeesRepository: MockVMGasFeesRepository(),
            toplistRepository: MockVMToplistRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository()
        )
        viewModel.gasFees = sampleFees(price: "1")
        viewModel.ethereum = Toplist(id: "ethereum", current_price: 1_000_000_000)

        let cost = viewModel.getGasPrice(for: .swap, accessible: false)
        let average = viewModel.getCurrentTextAccessible(at: 1, value: "12")
        let high = viewModel.getCurrentTextAccessible(at: 2, value: "12")

        #expect(cost != nil)
        #expect(viewModel.normalizedPosition(for: 0) == 0)
        #expect(viewModel.normalizedPosition(for: 100) == 1)
        #expect(average.isEmpty == false)
        #expect(average != high)
    }

    private func sampleFees(price: String) -> GasFees {
        GasFees(gasFeeData: [
            GasResult(
                lastBlock: "1",
                sK_Date: "2024-01-01T00:00:00.000Z",
                safeGasPrice: price,
                proposeGasPrice: price,
                fastGasPrice: price,
                suggestBaseFee: price,
                gasUsedRatio: "0.5"
            )
        ])
    }
}

private extension MockVMGasFeesRepository {
    func seed(fees: GasFees, prices: GasFees) {
        cachedGasFees = CachedData(data: fees, date: Date())
        cachedGasFeePrices = CachedData(data: prices, date: Date())
    }
}

private extension MockVMToplistRepository {
    func seedSmall(_ coins: [Toplist]) {
        cachedSmallToplist = CachedData(data: coins, date: Date())
    }
}
