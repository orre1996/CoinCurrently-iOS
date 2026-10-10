import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("GlobalMarketViewModel Tests")
struct GlobalMarketViewModelTests {

    @Test("setStartData loads the cached market and chart prices")
    func setStartDataLoadsCache() async {
        let repo = MockVMGlobalMarketRepository()
        await repo.seed(
            market: GlobalMarketModel(data: nil),
            chart: GlobalMarketChartData(
                market_cap: [[1, 100], [2, 150]],
                volume: [[1, 10], [2, 40]]
            )
        )
        let viewModel = GlobalMarketViewModelImp(globalMarketRepository: repo)
        viewModel.selectedChartType = .mktCap

        await viewModel.setStartData()

        #expect(viewModel.globalMarket != nil)
        #expect(viewModel.prices == [100, 150])
        #expect(viewModel.showMainPriceError == false)
    }

    @Test("setPrices follows the selected chart type")
    func setPricesFollowsChartType() async {
        let viewModel = GlobalMarketViewModelImp(globalMarketRepository: MockVMGlobalMarketRepository())
        viewModel.globalMarketChart = GlobalMarketChartData(
            market_cap: [[1, 100], [2, 80]],
            volume: [[1, 5], [2, 9]]
        )
        viewModel.selectedChartType = .volume

        viewModel.setPrices()
        viewModel.setTimestamps()

        #expect(viewModel.getPrices() == [5, 9])
        #expect(viewModel.getTimestamps() == [1, 2])
        #expect(viewModel.changePercent != nil)
    }

    @Test("refresh records an error when the chart is missing")
    func refreshRecordsError() async {
        let viewModel = GlobalMarketViewModelImp(globalMarketRepository: MockVMGlobalMarketRepository())

        await viewModel.refresh(newDays: "7", newTimeChart: .aWeek)

        #expect(viewModel.showMainPriceError)
        #expect(viewModel.reloading == false)
        #expect(viewModel.selectedTimeFrame == .aWeek)
    }
}

private extension MockVMGlobalMarketRepository {
    func seed(market: GlobalMarketModel, chart: GlobalMarketChartData) {
        cachedGlobalMarket = CachedData(data: market, date: Date())
        cachedGlobalChart = CachedData(
            data: GlobalMarketChartModel(market_cap_chart: chart),
            date: Date()
        )
    }
}
