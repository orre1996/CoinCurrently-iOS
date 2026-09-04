import Foundation
import Testing
@testable import CoinCurrently

@Suite("Currency Formatter Tests")
struct CurrencyFormatterTests {
    private let usd = CurrencyModel()

    @Test("exact style never abbreviates")
    func exactDoesNotAbbreviate() {
        #expect(1_500.0.formatted(style: .exact(currency: usd)).contains("K") == false)
        #expect(1_500_000.0.formatted(style: .exact(currency: usd)).contains("M") == false)
    }

    @Test("compact from thousand uses K then M")
    func compactFromThousand() {
        let fifteenHundred = 1_500.0.formatted(style: .compact(from: .thousand, currency: usd))
        #expect(fifteenHundred.contains("K"))

        let twoMillion = 2_000_000.0.formatted(style: .compact(from: .thousand, currency: usd))
        #expect(twoMillion.contains("M"))
    }

    @Test("compact from million leaves thousands unabbreviated")
    func compactFromMillion() {
        let fifteenHundred = 1_500.0.formatted(style: .compact(from: .million, currency: usd))
        #expect(fifteenHundred.contains("K") == false)

        let twoMillion = 2_000_000.0.formatted(style: .compact(from: .million, currency: usd))
        #expect(twoMillion.contains("M"))
    }

    @Test("compact from ten thousand leaves 1500 unabbreviated")
    func compactFromTenThousand() {
        let fifteenHundred = 1_500.0.formatted(style: .compact(from: .tenThousand, currency: usd))
        #expect(fifteenHundred.contains("K") == false)

        let fifteenThousand = 15_000.0.formatted(style: .compact(from: .tenThousand, currency: usd))
        #expect(fifteenThousand.contains("K"))
    }

    @Test("infinite values report overloaded")
    func infiniteIsOverloaded() {
        #expect(Double.infinity.formatted(style: .exact(currency: usd)) == "Overloaded")
        #expect(Double.infinity.formatted(style: .portfolioAmount()) == "Overloaded")
    }

    @Test("portfolio amount uses decimal grouping without a currency symbol")
    func portfolioAmountHasNoCurrencySymbol() {
        let formatted = 1_500.0.formatted(style: .portfolioAmount())
        #expect(formatted.contains("K"))
        #expect(formatted.contains("$") == false)
    }

    @Test("suffix currencies put the symbol after the compact unit")
    func suffixCurrency() {
        let sek = CurrencyModel(
            currency: "Swedish krona",
            code: "SEK",
            symbol: "kr",
            locale: "sv_SE",
            suffix: true,
            voiceOverName: "crowns"
        )
        let formatted = 2_000_000.0.formatted(style: .compact(from: .thousand, currency: sek))
        #expect(formatted.contains("M"))
        #expect(formatted.hasSuffix(" kr") || formatted.contains(" kr"))
    }
}
