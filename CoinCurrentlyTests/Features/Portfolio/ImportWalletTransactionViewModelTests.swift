import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("ImportWalletTransactionViewModel Tests")
struct ImportWalletTransactionViewModelTests {

    @Test("getToplist keeps only supported chain coins")
    func getToplistKeepsChainCoins() async {
        let toplist = MockVMToplistRepository()
        await toplist.setMarket([
            Toplist(id: "bitcoin", name: "Bitcoin"),
            Toplist(id: "dogecoin", name: "Dogecoin"),
            Toplist(id: "cardano", name: "Cardano")
        ])
        let viewModel = ImportWalletTransactionViewModelImp(
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: toplist,
            portfolioRepository: MockVMPortfolioRepository()
        )

        await viewModel.getToplist()

        #expect(viewModel.chainCoins?.map(\.id) == ["bitcoin", "dogecoin"])
    }

    @Test("import fails when coin details are missing")
    func importFailsWithoutCoinDetails() async {
        let viewModel = ImportWalletTransactionViewModelImp(
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: MockVMToplistRepository(),
            portfolioRepository: MockVMPortfolioRepository()
        )
        viewModel.address = "bc1q"

        let imported = await viewModel.importWallet()

        #expect(imported == false)
        #expect(viewModel.showImportError)
        #expect(viewModel.isImporting == false)
    }

    @Test("import succeeds when the portfolio returns data")
    func importSucceeds() async {
        let crypto = MockVMCryptoDetailRepository()
        await crypto.setDetails(sampleCurrency())
        let portfolio = MockVMPortfolioRepository()
        await portfolio.setImport(
            CachedPortfolioPies(data: [], otherCoins: [], date: Date()),
            [Cryptocurrency(id: "bitcoin", prices: ["usd": 1])]
        )
        let viewModel = ImportWalletTransactionViewModelImp(
            cryptoDetailRepository: crypto,
            toplistRepository: MockVMToplistRepository(),
            portfolioRepository: portfolio
        )
        viewModel.address = "bc1q"

        let imported = await viewModel.importWallet()

        #expect(imported)
        #expect(viewModel.showImportError == false)
    }
}

private extension MockVMToplistRepository {
    func setMarket(_ coins: [Toplist]) {
        marketToplist = coins
    }
}

private extension MockVMCryptoDetailRepository {
    func setDetails(_ details: CurrencyDataModel) {
        currencyDetails = details
    }
}

private extension MockVMPortfolioRepository {
    func setImport(_ pies: CachedPortfolioPies, _ prices: [Cryptocurrency]) {
        importResult = (pies, prices)
    }
}
