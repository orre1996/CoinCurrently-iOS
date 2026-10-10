import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("FearGreedViewModel Tests")
struct FearGreedViewModelTests {

    @Test("setStartData loads the cached index and builds a week of prices")
    func setStartDataBuildsPrices() async {
        let repo = MockVMFearGreedRepository()
        await repo.seed(fearGreed(values: ["10", "20", "30"]))
        let viewModel = FearGreedViewModelImp(fearGreedRepository: repo)
        viewModel.setTimeChart(.aWeek)

        await viewModel.setStartData()

        #expect(viewModel.fearGreed?.data?.count == 3)
        #expect(viewModel.prices.suffix(2).map { Int($0) } == [0, 100])
        #expect(viewModel.prices.count == 5)
    }

    @Test("getFearGreed stores the fetched index")
    func getFearGreedStoresIndex() async {
        let repo = MockVMFearGreedRepository()
        await repo.setFetched(fearGreed(values: ["55"]))
        let viewModel = FearGreedViewModelImp(fearGreedRepository: repo)

        await viewModel.getFearGreed()

        #expect(viewModel.fearGreed?.data?.first?.value == "55")
    }

    @Test("historic accessibility text names today and earlier periods")
    func historicAccessibilityText() async {
        let viewModel = FearGreedViewModelImp(fearGreedRepository: MockVMFearGreedRepository())

        let today = viewModel.getHistoricTextAccessible(at: 0, value: "42")
        let yesterday = viewModel.getHistoricTextAccessible(at: 1, value: "40")

        #expect(today.contains("42"))
        #expect(yesterday.contains("40"))
    }

    private func fearGreed(values: [String]) -> FearGreed {
        FearGreed(
            data: values.map {
                FearGreedItem(value: $0, value_classification: "Fear", timestamp: "1700000000", time_until_update: "0")
            }
        )
    }
}

private extension MockVMFearGreedRepository {
    func seed(_ value: FearGreed) {
        cachedFearGreed = CachedData(data: value, date: Date())
    }

    func setFetched(_ value: FearGreed) {
        fearGreed = value
    }
}
