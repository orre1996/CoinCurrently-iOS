import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CryptoDetailAlertsViewModel Tests")
struct CryptoDetailAlertsViewModelTests {

    @Test("load keeps alerts for the current coin and sorts newest first")
    func loadFiltersAndSortsAlerts() async {
        let repo = MockVMPriceAlertsRepository()
        await repo.setAlerts([
            sampleAlert(id: "old", coinId: "bitcoin", date: "2024-01-01T00:00:00.000Z"),
            sampleAlert(id: "other", coinId: "ethereum", date: "2024-06-01T00:00:00.000Z"),
            sampleAlert(id: "new", coinId: "bitcoin", date: "2024-08-01T00:00:00.000Z")
        ])
        let viewModel = CryptoDetailAlertsViewModel(
            priceAlertsRepository: repo,
        )

        await viewModel.load(coinId: "Bitcoin")

        #expect(viewModel.alerts?.map(\.id) == ["new", "old"])
        #expect(await viewModel.allAlertsCount() == 0)
    }

    @Test("addPriceAlert returns failure when creation fails")
    func addPriceAlertReturnsFailure() async {
        let repo = MockVMPriceAlertsRepository()
        await repo.setToken(true)
        let viewModel = CryptoDetailAlertsViewModel(
            priceAlertsRepository: repo,
        )

        let result = await viewModel.addPriceAlert(alertCoin: PostAlertCoin(
            coinId: "bitcoin",
            targetPrice: 10,
            direction: .below,
            resetThreshold: nil,
            preferredCurrency: "usd"
        ))

        #expect(result == .failure)
    }

    @Test("deleteAlert drops the alert before the request returns")
    func deleteAlertDropsLocally() async {
        let repo = MockVMPriceAlertsRepository()
        await repo.setAlerts([
            sampleAlert(id: "keep", coinId: "bitcoin", date: "2024-01-02T00:00:00.000Z"),
            sampleAlert(id: "drop", coinId: "bitcoin", date: "2024-01-01T00:00:00.000Z")
        ])
        await repo.setDeleted([sampleAlert(id: "keep", coinId: "bitcoin", date: "2024-01-02T00:00:00.000Z")])
        let viewModel = CryptoDetailAlertsViewModel(
            priceAlertsRepository: repo,
        )
        await viewModel.load(coinId: "bitcoin")

        await viewModel.deleteAlert(alert: sampleAlert(id: "drop", coinId: "bitcoin", date: "2024-01-01T00:00:00.000Z"))

        #expect(viewModel.alerts?.map(\.id) == ["keep"])
    }

    private func sampleAlert(id: String, coinId: String, date: String) -> AlertCoin {
        AlertCoin(
            id: id,
            resetThreshold: nil,
            direction: .above,
            coinId: coinId,
            targetPrice: 1,
            preferredCurrency: "usd",
            createdDate: date
        )
    }
}

private extension MockVMPriceAlertsRepository {
    func setAlerts(_ alerts: [AlertCoin]) {
        self.alerts = alerts
    }

    func setToken(_ available: Bool) {
        hasFCMToken = available
    }

    func setDeleted(_ alerts: [AlertCoin]) {
        deletedAlerts = alerts
    }
}
