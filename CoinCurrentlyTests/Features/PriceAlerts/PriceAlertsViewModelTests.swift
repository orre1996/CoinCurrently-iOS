import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("PriceAlertsViewModel Tests")
struct PriceAlertsViewModelTests {

    @Test("setGroups orders coins by market cap rank")
    func setGroupsOrdersByRank() async {
        let alerts = MockVMPriceAlertsRepository()
        await alerts.setCachedAlerts([
            sampleAlert(id: "b", coinId: "ethereum"),
            sampleAlert(id: "a", coinId: "bitcoin")
        ])
        let toplist = MockVMToplistRepository()
        await toplist.seedSmall([
            Toplist(id: "ethereum", market_cap_rank: 2),
            Toplist(id: "bitcoin", market_cap_rank: 1)
        ])
        let viewModel = PriceAlertsViewModelImp(
            priceAlertsRepository: alerts,
            toplistRepository: toplist,
            cryptoDetailRepository: MockVMCryptoDetailRepository()
        )

        await viewModel.setStartData()

        #expect(viewModel.groups == ["bitcoin", "ethereum"])
        #expect(viewModel.getCoin(id: "bitcoin")?.id == "bitcoin")
    }

    @Test("addPriceAlert fails closed when the push token is missing")
    func addPriceAlertFailsWithoutToken() async {
        let alerts = MockVMPriceAlertsRepository()
        await alerts.setToken(false)
        let viewModel = PriceAlertsViewModelImp(
            priceAlertsRepository: alerts,
            toplistRepository: MockVMToplistRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository()
        )

        let result = await viewModel.addPriceAlert(alertCoin: PostAlertCoin(
            coinId: "bitcoin",
            targetPrice: 100,
            direction: .above,
            resetThreshold: nil,
            preferredCurrency: "usd"
        ))

        #expect(result == .fcmTokenUnavailable)
    }

    @Test("deleteAlert replaces the list with the repository result")
    func deleteAlertReplacesList() async {
        let alerts = MockVMPriceAlertsRepository()
        await alerts.setDeleted([sampleAlert(id: "kept", coinId: "bitcoin")])
        let viewModel = PriceAlertsViewModelImp(
            priceAlertsRepository: alerts,
            toplistRepository: MockVMToplistRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository()
        )

        await viewModel.deleteAlert(alert: sampleAlert(id: "gone", coinId: "bitcoin"))

        #expect(viewModel.alerts?.map(\.id) == ["kept"])
    }

    private func sampleAlert(id: String, coinId: String) -> AlertCoin {
        AlertCoin(
            id: id,
            resetThreshold: nil,
            direction: .above,
            coinId: coinId,
            targetPrice: 100,
            preferredCurrency: "usd",
            createdDate: "2024-01-01T00:00:00.000Z"
        )
    }
}

private extension MockVMPriceAlertsRepository {
    func setCachedAlerts(_ alerts: [AlertCoin]) {
        cachedPriceAlerts = CachedData(data: alerts, date: Date())
    }

    func setToken(_ available: Bool) {
        hasFCMToken = available
    }

    func setDeleted(_ alerts: [AlertCoin]) {
        deletedAlerts = alerts
    }
}

private extension MockVMToplistRepository {
    func seedSmall(_ coins: [Toplist]) {
        cachedSmallToplist = CachedData(data: coins, date: Date())
    }
}
