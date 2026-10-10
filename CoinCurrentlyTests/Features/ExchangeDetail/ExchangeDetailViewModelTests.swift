import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("ExchangeDetailViewModel Tests")
struct ExchangeDetailViewModelTests {

    @Test("link helpers prefix bare social handles")
    func linkHelpersPrefixHandles() {
        let viewModel = makeViewModel(Exchange(
            name: "Binance",
            facebook_url: "binance",
            reddit_url: "r/binance"
        ))

        #expect(viewModel.getTelegramUrl(link: "binance") == "https://www.t.me/binance")
        #expect(viewModel.getTelegramUrl(link: "https://www.t.me/binance") == "https://www.t.me/binance")
        #expect(viewModel.getRedditUrl() == "https://www.reddit.comr/binance")
        #expect(viewModel.getFacebookUrl() == "https://www.facebook.com/binance")
        #expect(viewModel.isAllLinksEmpty() == false)
    }

    @Test("an exchange with no links reports them empty")
    func emptyLinks() {
        let viewModel = makeViewModel(Exchange())

        #expect(viewModel.isAllLinksEmpty())
    }

    @Test("getExchangeData stores the fetched exchange")
    func getExchangeDataStoresExchange() async {
        let repo = MockVMExchangeDetailsRepository()
        await repo.setDetail(Exchange(id: "binance", name: "Binance"))
        let viewModel = ExchangeDetailViewModelImp(
            exchangeDetail: Exchange(id: "binance", name: "Old"),
            exchangeDetailsRepository: repo,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            newsRepository: MockVMNewsRepository(),
            toplistRepository: MockVMToplistRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getExchangeData(id: "binance")

        #expect(viewModel.exchangeInfo.name == "Binance")
    }

    private func makeViewModel(_ exchange: Exchange) -> ExchangeDetailViewModelImp {
        ExchangeDetailViewModelImp(
            exchangeDetail: exchange,
            exchangeDetailsRepository: MockVMExchangeDetailsRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            newsRepository: MockVMNewsRepository(),
            toplistRepository: MockVMToplistRepository(),
            storageManager: emptyStorageManager()
        )
    }
}

private extension MockVMExchangeDetailsRepository {
    func setDetail(_ exchange: Exchange) {
        detail = exchange
    }
}
