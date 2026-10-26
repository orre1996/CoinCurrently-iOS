import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("AddSwapTransactionViewModel Tests")
struct AddSwapTransactionViewModelTests {

    @Test("input requires both amounts and a short note")
    func inputValidation() async {
        let viewModel = makeViewModel()

        #expect(viewModel.isInputValid == false)
        viewModel.fromAmount = 1
        viewModel.toAmount = 2
        #expect(viewModel.isInputValid)
        viewModel.note = String(repeating: "n", count: 201)
        #expect(viewModel.isInputValid == false)
    }

    @Test("current price follows the selected currency")
    func currentPriceFollowsCurrency() async {
        let viewModel = makeViewModel()
        viewModel.selectedCurrency = CurrencyModel()

        #expect(viewModel.currentPrice == 50_000)
    }

    @Test("a new swap adds the destination coin")
    func newSwapAddsDestinationCoin() async {
        let portfolio = MockVMPortfolioRepository()
        let crypto = MockVMCryptoDetailRepository()
        await crypto.setDetails(sampleCurrency(id: "ethereum", symbol: "eth", name: "Ethereum"))
        let viewModel = AddSwapTransactionViewModelImp(
            transactionType: .swap,
            currencyDetail: sampleCurrency(),
            transaction: nil,
            cryptoDetailRepository: crypto,
            portfolioRepository: portfolio,
        )
        viewModel.fromAmount = 1
        viewModel.toAmount = 15

        await viewModel.addTransaction()

        #expect(await portfolio.addCoinCount == 1)
        #expect(await portfolio.lastAddedId == "ethereum")
    }

    private func makeViewModel() -> AddSwapTransactionViewModelImp {
        AddSwapTransactionViewModelImp(
            transactionType: .swap,
            currencyDetail: sampleCurrency(),
            transaction: nil,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            portfolioRepository: MockVMPortfolioRepository(),
        )
    }
}

private extension MockVMCryptoDetailRepository {
    func setDetails(_ details: CurrencyDataModel) {
        currencyDetails = details
    }
}
