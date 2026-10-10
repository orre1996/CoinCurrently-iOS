import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CalculatorViewModel Tests")
struct CalculatorViewModelTests {

    @Test("setStartData sorts the cached toplist by rank")
    func setStartDataSortsToplist() async {
        let toplist = MockVMToplistRepository()
        await toplist.seedSmallToplist([
            Toplist(id: "ethereum", name: "Ethereum", market_cap_rank: 2),
            Toplist(id: "bitcoin", name: "Bitcoin", market_cap_rank: 1)
        ])
        let calculator = MockVMCalculatorRepository()
        await calculator.seedPrices([Cryptocurrency(id: "bitcoin", prices: ["usd": 100])])
        let viewModel = CalculatorViewModelImp(
            toplistRepository: toplist,
            calculatorRepository: calculator
        )

        await viewModel.setStartData()

        #expect(viewModel.calculatorList?.map(\.id) == ["bitcoin", "ethereum"])
        #expect(viewModel.calculatorPrices?.first?.id == "bitcoin")
    }

    @Test("getAmount converts input using the selected currency price")
    func getAmountConvertsInput() async {
        let viewModel = CalculatorViewModelImp(
            toplistRepository: MockVMToplistRepository(),
            calculatorRepository: MockVMCalculatorRepository()
        )
        viewModel.calculatorPrices = [Cryptocurrency(id: "bitcoin", prices: ["usd": 50])]

        let amount = viewModel.getAmount(
            for: "bitcoin",
            input: "100",
            currency: CurrencyModel(currency: "US Dollar", code: "USD", symbol: "$", locale: "en_US", suffix: false)
        )

        #expect(amount == 2)
    }

    @Test("getAmount returns nil when the coin is missing")
    func getAmountReturnsNilForMissingCoin() async {
        let viewModel = CalculatorViewModelImp(
            toplistRepository: MockVMToplistRepository(),
            calculatorRepository: MockVMCalculatorRepository()
        )

        #expect(viewModel.getAmount(for: "bitcoin", input: "100", currency: CurrencyModel()) == nil)
    }
}

private extension MockVMToplistRepository {
    func seedSmallToplist(_ coins: [Toplist]) {
        cachedSmallToplist = CachedData(data: coins, date: Date())
    }
}

private extension MockVMCalculatorRepository {
    func seedPrices(_ prices: [Cryptocurrency]) {
        cachedPrices = CachedData(data: prices, date: Date())
    }
}
