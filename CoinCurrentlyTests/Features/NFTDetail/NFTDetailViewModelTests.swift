import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("NFTDetailViewModel Tests")
struct NFTDetailViewModelTests {

    @Test("price prefix uses the full series outside the one hour chart")
    func pricePrefixUsesFullSeries() async {
        let viewModel = NFTDetailViewModelImp(
            nftToplist: NFTToplist(id: "punks", name: "CryptoPunks"),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            newsRepository: MockVMNewsRepository(),
            nftDetailsRepository: MockVMNFTDetailRepository(),
            nftsRepository: MockVMNFTRepository(),
            globalRepository: MockVMGlobalMarketRepository(),
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager()
        )

        #expect(viewModel.getPricesRangePrefix(priceVolume: nil) == 0)
    }

    @Test("getDetail stores the fetched collection")
    func getDetailStoresCollection() async {
        let repo = MockVMNFTDetailRepository()
        await repo.setDetail(testDecode(#"{"id":"punks","name":"CryptoPunks"}"#))
        let viewModel = NFTDetailViewModelImp(
            nftToplist: NFTToplist(id: "punks", name: "CryptoPunks"),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            newsRepository: MockVMNewsRepository(),
            nftDetailsRepository: repo,
            nftsRepository: MockVMNFTRepository(),
            globalRepository: MockVMGlobalMarketRepository(),
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager()
        )

        await viewModel.getDetail()

        #expect(viewModel.nftDetailInfo.name == "CryptoPunks")
    }
}

private extension MockVMNFTDetailRepository {
    func setDetail(_ detail: NFTDetail) {
        self.detail = detail
    }
}
