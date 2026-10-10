import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("NFTsViewModel Tests")
struct NFTsViewModelTests {

    @Test("getNftToplist sorts by floor price")
    func getNftToplistSortsByFloorPrice() async {
        let repo = MockVMNFTRepository()
        await repo.setToplist([
            NFTToplist(name: "Low", floor_price: FloorPrice(native_currency: nil, usd: 1)),
            NFTToplist(name: "High", floor_price: FloorPrice(native_currency: nil, usd: 9))
        ])
        let viewModel = NFTsViewModelImp(
            nftRepository: repo,
            globalMarketRepository: MockVMGlobalMarketRepository(),
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getNftToplist(
            newPlatform: NFTPlatform(id: "ethereum", name: "Ethereum"),
            newSortOption: .floorPriceDesc
        )

        #expect(viewModel.nftToplist.map(\.name) == ["High", "Low"])
        #expect(viewModel.selectedSortOption == .floorPriceDesc)
    }

    @Test("getChainSymbol maps a native currency id to its symbol")
    func getChainSymbolMapsId() async {
        let market = MockVMGlobalMarketRepository()
        await market.setCoins([CoinsListModel(id: "ethereum", symbol: "eth", name: "Ethereum")])
        let viewModel = NFTsViewModelImp(
            nftRepository: MockVMNFTRepository(),
            globalMarketRepository: market,
            cryptoDetailRepository: sampleBitcoinRepository(),
            storageManager: emptyStorageManager()
        )

        await viewModel.getAllCoins()

        #expect(viewModel.getChainSymbol(for: "ethereum")?.symbol.contains("ETH") == true)
        #expect(viewModel.getChainSymbol(for: nil) == nil)
    }
}

private extension MockVMNFTRepository {
    func setToplist(_ items: [NFTToplist]) {
        toplist = items
    }
}

private extension MockVMGlobalMarketRepository {
    func setCoins(_ coins: [CoinsListModel]) {
        self.coins = coins
    }
}
