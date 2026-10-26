import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CryptoDetailViewModel Tests")
struct CryptoDetailViewModelTests {

    @Test("getMainCryptoInfo stores the fetched coin")
    func getMainCryptoInfoStoresCoin() async {
        let crypto = MockVMCryptoDetailRepository()
        await crypto.setDetails(sampleCurrency(id: "ethereum", symbol: "eth", name: "Ethereum"))
        let viewModel = makeViewModel(crypto: crypto)

        await viewModel.getMainCryptoInfo(id: "ethereum")

        #expect(viewModel.cryptoInfo?.id == "ethereum")
        #expect(viewModel.cryptoInfo?.name == "Ethereum")
    }

    @Test("missing prices mark the chart as failed")
    func missingPricesMarkChartFailed() async {
        let viewModel = makeViewModel(crypto: MockVMCryptoDetailRepository())

        await viewModel.getMainCurrencyPrices(id: "bitcoin", chart: .aDay)

        #expect(viewModel.priceVolumeModel == nil)
        #expect(viewModel.showMainPriceError)
    }

    @Test("newMainCoin clears the previous coin before loading")
    func newMainCoinClearsPreviousCoin() async {
        let viewModel = makeViewModel(crypto: MockVMCryptoDetailRepository())

        await viewModel.newMainCoin(id: "ethereum")

        #expect(viewModel.cryptoInfo == nil)
        #expect(viewModel.mainReloading == false)
        #expect(viewModel.prices.isEmpty)
    }

    private func makeViewModel(crypto: MockVMCryptoDetailRepository) -> CryptoDetailViewModelImp {
        CryptoDetailViewModelImp(
            cryptoInfo: sampleCurrency(),
            cryptoDetailRepository: crypto,
            toplistRepository: MockVMToplistRepository(),
            globalMarketRepository: MockVMGlobalMarketRepository(),
            storageManager: emptyStorageManager(),
            analyticsManager: AnalyticsManager.shared,
            settingsManager: SettingsManager.shared
        )
    }
}

private extension MockVMCryptoDetailRepository {
    func setDetails(_ details: CurrencyDataModel) {
        currencyDetails = details
    }
}
