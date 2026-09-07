import Foundation
import Testing
@testable import CoinCurrently

@Suite("Portfolio Pie Chart Layout Tests")
struct PortfolioPieChartLayoutTests {

    @Test("two coins never collapse into Other")
    func twoCoinsKeepIndividualSlices() {
        let slices = PortfolioPieChartLayout.slices(
            from: [
                (id: "bitcoin", symbol: "BTC", name: "Bitcoin", value: 99, color: nil),
                (id: "ethereum", symbol: "ETH", name: "Ethereum", value: 1, color: nil)
            ],
            totalValue: 100
        )

        #expect(slices.count == 2)
        #expect(!slices.contains { $0.id == PortfolioPieChartLayout.otherSliceId })
    }

    @Test("tiny holdings collapse into Other when there are more than two coins")
    func tinyHoldingsBecomeOther() {
        let slices = PortfolioPieChartLayout.slices(
            from: [
                (id: "bitcoin", symbol: "BTC", name: "Bitcoin", value: 90, color: nil),
                (id: "ethereum", symbol: "ETH", name: "Ethereum", value: 8, color: nil),
                (id: "solana", symbol: "SOL", name: "Solana", value: 2, color: nil)
            ],
            totalValue: 100
        )

        #expect(slices.contains { $0.id == PortfolioPieChartLayout.otherSliceId && $0.symbol == "OTHER" })
        #expect(slices.contains { $0.id == "bitcoin" })
        #expect(slices.contains { $0.id == "ethereum" })
        #expect(!slices.contains { $0.id == "solana" })
    }

    @Test("single holding is always 100 percent of the pie")
    func singleHoldingIsFullAllocation() {
        let slices = PortfolioPieChartLayout.slices(
            from: [
                (id: "bitcoin", symbol: "BTC", name: "Bitcoin", value: 80_731, color: nil)
            ],
            totalValue: 80_984.70
        )

        #expect(slices.count == 1)
        #expect(slices.first?.percentage == 1)
        #expect(slices.first?.symbol == "BTC")
    }
}
