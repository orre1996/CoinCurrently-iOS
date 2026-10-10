import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("AddTransactionViewModel Tests")
struct AddTransactionViewModelTests {

    @Test("input is valid only for a positive amount and a short note")
    func inputValidation() async {
        let viewModel = makeViewModel(type: .buy, currency: sampleCurrency(symbol: "btc"))

        #expect(viewModel.isInputValid == false)
        viewModel.amount = 1.5
        viewModel.note = String(repeating: "a", count: 201)
        #expect(viewModel.isInputValid == false)
        viewModel.note = "dca"
        #expect(viewModel.isInputValid)
        #expect(viewModel.canImport)
    }

    @Test("import addresses need an address instead of an amount")
    func importAddressValidation() async {
        let viewModel = makeViewModel(type: .importAddress, currency: sampleCurrency(symbol: "eth"))
        viewModel.amount = 1

        #expect(viewModel.isInputValid == false)
        viewModel.address = "0xabc"
        #expect(viewModel.isInputValid)
    }

    @Test("adding a transaction creates a coin when the portfolio does not contain it")
    func addTransactionCreatesCoin() async {
        let portfolio = MockVMPortfolioRepository()
        let viewModel = AddTransactionViewModelImp(
            transactionType: .buy,
            currencyDetail: sampleCurrency(),
            transaction: nil,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            portfolioRepository: portfolio,
            storeKitManager: MockRepoStoreKitManager()
        )
        viewModel.amount = 2

        await viewModel.addTransaction()

        #expect(await portfolio.addCoinCount == 1)
        #expect(await portfolio.lastAddedId == "bitcoin")
    }

    @Test("editing uses the existing coin when the portfolio already has it")
    func addTransactionAppendsToExistingCoin() async {
        let portfolio = MockVMPortfolioRepository()
        await portfolio.setModels([
            PortfolioModel(id: "bitcoin", transactions: [], swaps: [], imports: [])
        ])
        let viewModel = AddTransactionViewModelImp(
            transactionType: .buy,
            currencyDetail: sampleCurrency(),
            transaction: nil,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            portfolioRepository: portfolio,
            storeKitManager: MockRepoStoreKitManager()
        )
        await viewModel.setStartData()
        viewModel.amount = 1

        await viewModel.addTransaction()

        #expect(viewModel.containsCoin)
        #expect(await portfolio.addTransactionCount == 1)
        #expect(await portfolio.addCoinCount == 0)
    }

    private func makeViewModel(type: PortfolioTransactionType, currency: CurrencyDataModel) -> AddTransactionViewModelImp {
        AddTransactionViewModelImp(
            transactionType: type,
            currencyDetail: currency,
            transaction: nil,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            portfolioRepository: MockVMPortfolioRepository(),
            storeKitManager: MockRepoStoreKitManager()
        )
    }
}

private extension MockVMPortfolioRepository {
    func setModels(_ models: [PortfolioModel]) {
        portfolioModels = models
    }
}
