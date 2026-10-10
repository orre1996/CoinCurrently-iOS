import Foundation
import Testing
@testable import CoinCurrently

@Suite("Portfolio Math Tests")
struct PortfolioMathTests {

    @Test("buy then mark-to-market is a 50 percent gain")
    func buyProfitLoss() {
        let pie = Pie(
            data: Toplist(id: "bitcoin", symbol: "btc", name: "Bitcoin"),
            transactions: [
                PortfolioTransaction(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    amount: 1,
                    pricePerCoin: 100,
                    fee: 0,
                    note: "",
                    transactionType: .buy,
                    currency: "usd"
                )
            ]
        )
        let prices = [Cryptocurrency(id: "bitcoin", prices: ["usd": 150])]

        #expect([pie].getProfitLossValue(coinPrices: prices, showCurrency: "usd") == 50)
        #expect([pie].getProfitLossPercent(coinPrices: prices, showCurrency: "usd") == 50)
        #expect([pie].getAllTransactions(of: "bitcoin").getAmount() == 1)
    }

    @Test("empty portfolio reports zero profit")
    func emptyPortfolioProfit() {
        #expect([Pie]().getProfitLossValue(coinPrices: [], showCurrency: "usd") == 0)
        #expect([Pie]().getProfitLossPercent(coinPrices: [], showCurrency: "usd") == 0)
    }

    @Test("default wallet name counts existing imports")
    func defaultWalletName() {
        let empty: [PortfolioModel] = []
        #expect(empty.defaultWalletName == "Wallet")

        let withImport = [
            PortfolioModel(
                id: "bitcoin",
                transactions: [],
                swaps: [],
                imports: [
                    AddressImport(address: "abc", balance: "1", blockChain: .btc)
                ]
            )
        ]
        #expect(withImport.defaultWalletName == "Wallet 1")
    }
}

@Suite("Portfolio Export Builder Tests")
struct PortfolioExportBuilderTests {

    private var samplePie: Pie {
        Pie(
            data: Toplist(id: "bitcoin", symbol: "btc", name: "Bitcoin"),
            transactions: [
                PortfolioTransaction(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    amount: 2,
                    pricePerCoin: 25_000,
                    fee: 10,
                    note: "DCA",
                    transactionType: .buy,
                    address: "bc1qtest",
                    currency: "usd"
                )
            ]
        )
    }

    @Test("native CSV includes header and buy row")
    func nativeCSV() {
        let csv = PortfolioExportBuilder.csv(from: [samplePie])
        let lines = csv.split(separator: "\n")

        #expect(lines.first == "Date (UTC),Coin,Type,Amount,Price per coin,Fee,Value traded,Currency,Note,Address")
        #expect(csv.contains("BTC"))
        #expect(csv.contains("Bought"))
        #expect(csv.contains("25000"))
        #expect(csv.contains("DCA"))
        #expect(csv.contains("bc1qtest"))
        #expect(csv.contains("2023-11-14 22:13:20"))
    }

    @Test("JSON export contains the coin id")
    func nativeJSON() throws {
        let json = try #require(PortfolioExportBuilder.json(from: [samplePie]))
        #expect(json.contains("\"coinId\" : \"bitcoin\""))
        #expect(json.contains("\"amount\" : 2"))
    }

    @Test("Koinly CSV keeps the tax header")
    func koinlyCSV() throws {
        let csv = try #require(PortfolioExportBuilder.content(for: .koinly, from: [samplePie]))
        #expect(csv.hasPrefix("Date,Sent Amount,Sent Currency,Received Amount,Received Currency,Fee Amount,Fee Currency,Description"))
        #expect(csv.contains("BTC"))
    }
}
