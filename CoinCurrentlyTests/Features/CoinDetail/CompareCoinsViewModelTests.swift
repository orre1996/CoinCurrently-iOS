import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CompareCoinsViewModel Tests")
struct CompareCoinsViewModelTests {

    @Test("getMainCryptoInfo replaces the main coin")
    func getMainCryptoInfoReplacesMainCoin() async {
        let crypto = MockVMCryptoDetailRepository()
        await crypto.setDetails(sampleCurrency(id: "ethereum", symbol: "eth", name: "Ethereum"))
        let viewModel = makeViewModel(crypto: crypto)

        await viewModel.getMainCryptoInfo(id: "ethereum")

        #expect(viewModel.cryptoInfo?.name == "Ethereum")
    }

    @Test("getCurrencyPrices records missing series for both coins")
    func getCurrencyPricesRecordsMissingSeries() async {
        let viewModel = makeViewModel(crypto: MockVMCryptoDetailRepository())

        await viewModel.getCurrencyPrices(mainId: "bitcoin", compareId: "ethereum", chart: .aWeek)

        #expect(viewModel.showMainPriceError)
        #expect(viewModel.showComparePriceError)
    }

    @Test("getToplist stores comparable coins")
    func getToplistStoresComparableCoins() async {
        let toplist = MockVMToplistRepository()
        await toplist.setMarket([
            Toplist(id: "bitcoin", name: "Bitcoin", market_cap_rank: 1),
            Toplist(id: "ethereum", name: "Ethereum", market_cap_rank: 2)
        ])
        let viewModel = CompareCoinsViewModelImp(
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: toplist,
            settingsManager: SettingsManager.shared,
            storeKitManager: MockRepoStoreKitManager(),
            cryptoInfo: sampleCurrency(),
            priceVolumeModel: nil,
            compareId: "ethereum"
        )

        await viewModel.getToplist()

        #expect(viewModel.comparableCoins.map(\.id) == ["bitcoin", "ethereum"])
    }

    private func makeViewModel(crypto: MockVMCryptoDetailRepository) -> CompareCoinsViewModelImp {
        CompareCoinsViewModelImp(
            cryptoDetailRepository: crypto,
            toplistRepository: MockVMToplistRepository(),
            settingsManager: SettingsManager.shared,
            storeKitManager: MockRepoStoreKitManager(),
            cryptoInfo: sampleCurrency(),
            priceVolumeModel: nil,
            compareId: "ethereum"
        )
    }
}

private extension MockVMCryptoDetailRepository {
    func setDetails(_ details: CurrencyDataModel) {
        currencyDetails = details
    }
}

private extension MockVMToplistRepository {
    func setMarket(_ coins: [Toplist]) {
        marketToplist = coins
    }
}
