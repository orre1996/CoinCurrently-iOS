import Foundation
import Testing
@testable import CoinCurrently

@Suite("Toplist Holding Price Tests")
struct ToplistHoldingPriceTests {

    @Test("prefers live vs-currency, then current price, then sparkline")
    func fallbackOrder() {
        let coin = Toplist(
            id: "bitcoin",
            current_price: 80_000,
            sparkline_in_7d: Sparkline(price: [79_000, 80_984.70])
        )

        #expect(
            coin.holdingPrice(
                vsCurrencyPrices: ["usd": 80_731],
                currencyCode: "USD"
            ) == 80_731
        )
        #expect(coin.holdingPrice(vsCurrencyPrices: nil, currencyCode: "USD") == 80_000)
        #expect(
            Toplist(sparkline_in_7d: Sparkline(price: [80_984.70]))
                .holdingPrice(vsCurrencyPrices: nil, currencyCode: "USD") == 80_984.70
        )
        #expect(Toplist().holdingPrice(vsCurrencyPrices: [:], currencyCode: "USD") == 0)
    }
}
