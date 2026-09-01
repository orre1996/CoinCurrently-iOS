import Testing
@testable import CoinCurrently

@Suite("CryptoDetailRepository Tests")
struct CryptoDetailRepositoryTests {

    @Test("getCurrencyDetails returns nil for nil id")
    func getCurrencyDetailsWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = CryptoDetailRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager()
        )

        let result = await repo.getCurrencyDetails(id: nil)
        #expect(result == nil)
    }

    @Test("getCurrencyPrices returns nil for nil id")
    func getCurrencyPricesWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = CryptoDetailRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager()
        )

        let result = await repo.getCurrencyPrices(id: nil, chart: .aWeek)
        #expect(result == nil)
    }

    @Test("getCandleChart returns nil for nil id")
    func getCandleChartWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = CryptoDetailRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager()
        )

        let result = await repo.getCandleChart(id: nil, days: "7")
        #expect(result == nil)
    }

    @Test("addCurrencyToWidget appends coin")
    func addCurrencyToWidget() async {
        let mock = MockRepoNetworkManager()

        let repo = CryptoDetailRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager()
        )

        let coin = Toplist(id: "bitcoin_test", name: "Bitcoin")
        await repo.addCurrencyToWidget(toplist: coin)

        let widgets = await repo.widgetCurrencies
        #expect(widgets.count == 1)
        #expect(widgets.first?.id == "bitcoin_test")
    }

    @Test("removeWidgetCoin removes coin")
    func removeWidgetCoin() async {
        let mock = MockRepoNetworkManager()

        let repo = CryptoDetailRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager()
        )

        let coin = Toplist(id: "bitcoin_test", name: "Bitcoin")
        await repo.addCurrencyToWidget(toplist: coin)
        let remaining = await repo.removeWidgetCoin(coin: coin)

        #expect(remaining.isEmpty)
    }
}
