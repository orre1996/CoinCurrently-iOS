//
//  TrendingViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-10.
//

import SwiftUI
import Combine

@MainActor
protocol TrendingViewModel {
    var trendingList: TrendingItems? { get }

    func setStartData() async
    func getTrendingCoins() async
    func getTrendingItems(searchCase: SearchCase) -> [Toplist]?
}

@MainActor @Observable
final class TrendingViewModelImp: TrendingViewModel {
    private var cancellable: Set<AnyCancellable> = []

    private let trendingRepository: TrendingRepository

    private(set) var trendingList: TrendingItems?

    init(trendingRepository: TrendingRepository = TrendingRepositoryImp.shared) {
        self.trendingRepository = trendingRepository
    }
    
    func setStartData() async {
        await trendingRepository.ensureCacheLoaded()
        
        if
            let trendingList = await trendingRepository.cachedTrending?.data,
            let coins = trendingList.coins,
            !coins.isEmpty
        {
            self.trendingList = trendingList
        }
    }

    func getTrendingCoins() async {
        if let trendingList = await trendingRepository.getTrendingList() {
            self.trendingList = trendingList
            
            if
                let secret: HiddenSecret = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message),
                secret.secret_number == "6",
                var list = self.trendingList
            {
                var coins = list.coins ?? []
                
                coins.insert(
                    TrendingCoin(
                        item: CoinItem(
                            id: secret.secret_url,
                            coin_id: nil,
                            name: "CoinCurrently",
                            symbol: "Secret message",
                            market_cap_rank: 0,
                            thumb: secret.secret_image,
                            small: secret.secret_image,
                            large: secret.secret_image,
                            slug: nil,
                            price_btc: nil,
                            score: nil,
                            data: nil
                        )
                    ),
                    at: min(4, coins.count)
                )
                
                list.coins = coins
                self.trendingList = list
            }
        }
    }
    
    func getTrendingItems(searchCase: SearchCase) -> [Toplist]? {
        switch searchCase {
        case .onlyCoins, .coins:
            return trendingList?.coins?.compactMap({ $0.item?.toToplist })
        case .nfts:
            return trendingList?.nfts?.compactMap({ $0.toToplist })
        case .categories:
            return trendingList?.categories?.compactMap({ $0.toToplist })
        case .exchanges:
            return []
        }
    }
}
