//
//  HomeViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-14.
//

import Foundation
import SwiftUI
import Combine
import StoreKit

@MainActor
protocol HomeViewModel {
    func setStartData() async
    func downloadData() async
    func getGlobalMarket() async
    func getGasFees() async
    func getFearGreed() async
    func favouriteButtonPressed(toplistItem: Toplist?) async
    
    func getList(filter: CarouselFilter) -> [Toplist]?
    func toplistSeeAll() async
    func premiumViewClosed(title: String)
    
    var globalMarket: GlobalMarketModel? { get }
    var trendingCoins: [Toplist]? { get }
    var newCoins: [Toplist]? { get }
    var fearGreed: FearGreed? { get }
    var gasFees: GasFees? { get }
    
    var selectedFilter: CarouselFilter? { get set }
    var toplist: [Toplist]? { get }
    var favoritesList: [Toplist] { get }
    var winnersList: [Toplist]? { get }
    var losersList: [Toplist]? { get }

    var informationMessage: String? { get }
    var informationKey: String? { get }
    var promotionTitle: String? { get }
    var promotionMessage: String? { get }
    var promotionMessageAccessible: String? { get }
    var offerTimeLeft: String? { get }
    var offerTimeLeftDate: Date? { get }
    
}

@Observable @MainActor
class HomeViewModelImp: HomeViewModel {
    private var homeListPreviewCount: Int {
        isPad ? 20 : 10
    }
    private var cancellable: Set<AnyCancellable> = []
    
    private let toplistRepository: ToplistRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let winnersLosersRepository: WinnersLosersRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let fearGreedRepository: FearGreedRepository
    private let gasFeesRepository: GasFeesRepository
    private let trendingRepository: TrendingRepository
    private let newCoinsRepository: NewCoinsRepository
    private let firebaseManger: FirebaseManager
    private let storeKitManager: StoreKitManager
    private let cachedStorageManager: CachedStorageManager
    private let settingsManager: SettingsManager
    private let analyticsManager: AnalyticsManager
    
    var selectedFilter: CarouselFilter? = .topCoins
    private var didApplyDefaultHomeFilter = false
    private var skipNextHomeFilterAnalytics = false
    var toplist: [Toplist]?
    var favoritesList = [Toplist]()
    var winnersList: [Toplist]?
    var losersList: [Toplist]?
    var globalMarket: GlobalMarketModel?
    var trendingCoins: [Toplist]?
    var newCoins: [Toplist]?
    var fearGreed: FearGreed?
    var gasFees: GasFees?
    
    // Promotions and Information
    var informationMessage: String?
    var informationKey: String?
    var promotionTitle: String?
    var promotionMessage: String?
    var promotionMessageAccessible: String?
    var offerTimeLeft: String?
    var offerTimeLeftDate: Date?
    
    private var timer: Timer?
    private var didClosePromotions = false
    private var didCloseWelcome = false
    private var showFreeTrial = false
    
    private(set) var scrollToTopActive = false
    
    init(
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        winnersLosersRepository: WinnersLosersRepository = WinnersLosersRepositoryImp.shared,
        globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        trendingRepository: TrendingRepository = TrendingRepositoryImp.shared,
        newCoinsRepository: NewCoinsRepository = NewCoinsRepositoryImp.shared,
        fearGreedRepository: FearGreedRepository = FearGreedRepositoryImp.shared,
        gasFeesRepository: GasFeesRepository = GasFeesRepositoryImp.shared,
        firebaseManger: FirebaseManager = FirebaseManagerImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        cachedStorageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared
    ) {
        self.toplistRepository = toplistRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.winnersLosersRepository = winnersLosersRepository
        self.globalMarketRepository = globalMarketRepository
        self.trendingRepository = trendingRepository
        self.newCoinsRepository = newCoinsRepository
        self.fearGreedRepository = fearGreedRepository
        self.gasFeesRepository = gasFeesRepository
        self.firebaseManger = firebaseManger
        self.storeKitManager = storeKitManager
        self.cachedStorageManager = cachedStorageManager
        self.settingsManager = settingsManager
        self.analyticsManager = analyticsManager
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        await winnersLosersRepository.ensureCacheLoaded()
        await globalMarketRepository.ensureCacheLoaded()
        await trendingRepository.ensureCacheLoaded()
        await newCoinsRepository.ensureCacheLoaded()
        await fearGreedRepository.ensureCacheLoaded()
        await gasFeesRepository.ensureCacheLoaded()
        
        // Toplist
         if let toplist = await toplistRepository.cachedSmallToplist?.data, !toplist.isEmpty {
             self.toplist = Array(toplist.prefix(homeListPreviewCount))
         } else if let toplist = await toplistRepository.cachedToplist[SortOption.mktCapDesc.toplistApiValue]?.data, !toplist.isEmpty {
             self.toplist = Array(toplist.prefix(homeListPreviewCount))
         }
         
         // Favorites
         if let favorites = await toplistRepository.cachedFavorites?.data {
             self.favoritesList = favorites.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
         }
         applyDefaultHomeFilterIfNeeded()
         
          let timeFrame = "7"
         
         // Winner coins
         if let winners = await winnersLosersRepository.cachedWinnersCoins[timeFrame]?.data, !winners.isEmpty {
             self.winnersList = Array(winners.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
         }
         
         // Loser coins
         if let losers = await winnersLosersRepository.cachedLosersCoins[timeFrame]?.data, !losers.isEmpty {
             self.losersList = Array(losers.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
         }
         
         // Global market
         if let globalMarket = await globalMarketRepository.cachedGlobalMarket?.data {
             self.globalMarket = globalMarket
         }
         
         // Trending
         if let trendingCoins = await trendingRepository.cachedTrendingCoins?.data, !trendingCoins.isEmpty {
             let orderedTrendingCoins = await orderedTrendingCoins(trendingCoins)
             self.trendingCoins = Array(orderedTrendingCoins.prefix(homeListPreviewCount))
         }

         // New coins
         if let newCoins = await newCoinsRepository.cachedNewCoins?.data, !newCoins.isEmpty {
             self.newCoins = Array(newCoins.prefix(homeListPreviewCount))
         }
         
         // Fear and Greed
         if let fearGreed = await fearGreedRepository.cachedFearGreed?.data {
             self.fearGreed = fearGreed
         }
         
         // Gas fees
         if let data = await gasFeesRepository.cachedGasFees?.data {
             self.gasFees = data
         }
        
        
        self.didClosePromotions = await cachedStorageManager.load(type: LocalStorageKeys.didClosePromotions) ?? false
        self.didCloseWelcome = await cachedStorageManager.load(type: LocalStorageKeys.didCloseWelcome) ?? false
        if SettingsManager.shared.get(key: AppSettingKey.hasClosedApp) ?? false {
            await setShowWelcomeMessage()
        }
        await setShowFreeTrial()

        await setFirebaseInformationMessage()
        
        let products = await storeKitManager.requestProducts()
        let isEligibleForTrial = await storeKitManager.isEligableForTrial(using: products)
        
        await setPremiumOffer(
            products: await storeKitManager.requestProducts(),
            isEligableForTrial: isEligibleForTrial,
            hasBoughtPro: await storeKitManager.currentSubscription != nil
        )
    }
    
    func getList(filter: CarouselFilter) -> [Toplist]? {
        switch filter {
        case .topCoins:
            return toplist
        case .favorites:
            return favoritesList
        case .trending:
            return trendingCoins
        case .timeframeWinners:
            return winnersList
        case .timeframeLosers:
            return losersList
        case .newlyListed:
            return newCoins
        default:
            return []
        }
    }
    
    func downloadData() async {
        switch selectedFilter ?? .topCoins {
        case .topCoins:
            await getToplist()
        case .favorites:
            await getFavorites()
        case .trending:
            await getTrendingCoins()
        case .timeframeWinners:
            await getWinners()
        case .timeframeLosers:
            await getLosers()
        case .newlyListed:
            await getNewCoins()
        default:
            return
        }
    }

    func toplistSeeAll() async {
        let newSort: SortOption?

        switch selectedFilter {
        case .topCoins:
            newSort = .mktCapDesc

        case .timeframeWinners:
            newSort = .priceChangeDesc

        case .timeframeLosers:
            newSort = .priceChangeAsc

        default:
            return
        }

        guard let newSort else {
            return
        }
        
        await cachedStorageManager.save(type: AppSettingKey.toplistSortOption.rawValue, data: newSort)
        NotificationCenter.default.post(
            name: .changeMarketPage,
            object: nil,
            userInfo: ["page": 0, "sortOption": newSort.rawValue]
        )
    }

    func premiumViewClosed(title: String) {
        if title == "Free trial" {
            Task { await cachedStorageManager.save(type: LocalStorageKeys.homeShowFreeTrial, data: false) }
            Task { await cachedStorageManager.save(type: LocalStorageKeys.homeNextFreeTrialDate, data: Date()) }
            showFreeTrial = false
        } else if title == "Limited Time Offer!" {
            Task { await cachedStorageManager.save(type: LocalStorageKeys.didClosePromotions, data: true) }
            didClosePromotions = true
        } else {
            Task { await cachedStorageManager.save(type: LocalStorageKeys.didCloseWelcome, data: true) }
            didCloseWelcome = true
        }

        withAnimation {
            promotionTitle = nil
        }
        
        promotionMessage = nil
        promotionMessageAccessible = nil
        offerTimeLeft = nil
        offerTimeLeftDate = nil
        
        timer?.invalidate()
        timer = nil
    }

    func informationClosed(message: String, key: String) {
        SettingsManager.shared.setKey(key: key)
        informationMessage = nil
    }

    // MARK: - Toplist

    func getToplist() async {
        if let toplist = await toplistRepository.getSmallToplist() {
            self.toplist = Array(toplist.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    func getFavorites() async {
        if let favorites = await toplistRepository.getFavorites() {
            self.favoritesList = favorites.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
            await setStartData()
        }
    }

    func getWinners() async {
        if let winners = await winnersLosersRepository.getWinners(priceChange: .sevenDays) {
            self.winnersList = Array(winners.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    func getLosers() async {
        if let losers = await winnersLosersRepository.getLosers(priceChange: .sevenDays) {
            self.losersList = Array(losers.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) < ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    func consumeSkipNextHomeFilterAnalytics() -> Bool {
        let skip = skipNextHomeFilterAnalytics
        skipNextHomeFilterAnalytics = false
        return skip
    }

    private func applyDefaultHomeFilterIfNeeded() {
        guard !didApplyDefaultHomeFilter else { return }
        didApplyDefaultHomeFilter = true
        let filter = CarouselFilter.defaultHomeFilter(hasFavorites: !favoritesList.isEmpty)
        guard filter != (selectedFilter ?? .topCoins) else { return }
        skipNextHomeFilterAnalytics = true
        selectedFilter = filter
    }

    func favouriteButtonPressed(toplistItem: Toplist?) async {
        guard let toplistItem else { return }

        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        
        if !hasActiveSubscription && !favoritesList.contains(where: { $0.id == toplistItem.id }) && favoritesList.count >= 2 {
            analyticsManager.log(
                BuyProOpened(fromScreen: .home, action: .Favorite)
            )
            showBuyPro()
            return
        }
        
        if favoritesList.contains(where: { $0.id == toplistItem.id }) {
            analyticsManager.log(FavoriteRemoved(coinName: toplistItem.name ?? "", fromScreen: .home, carouselFilter: selectedFilter))
        } else {
            analyticsManager.log(FavoriteAdded(coinName: toplistItem.name ?? "", fromScreen: .home, carouselFilter: selectedFilter))
        }
           
        favoritesList = await toplistRepository.favouriteButtonPressed(toplist: toplistItem).sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
    }
    
    // MARK: - Trending

    func getTrendingCoins() async {
        if let trendingCoins = await trendingRepository.getTrendingCoins() {
            let orderedTrendingCoins = await orderedTrendingCoins(trendingCoins)
            self.trendingCoins = Array(orderedTrendingCoins.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    // MARK: - New coins

    func getNewCoins() async {
        if let newCoins = await newCoinsRepository.getNewCoins() {
            self.newCoins = Array(newCoins.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    // MARK: - Global market

    func getGlobalMarket() async {
        if let globalMarket = await globalMarketRepository.getGlobalMarket() {
            self.globalMarket = globalMarket
        }
    }

    // MARK: - Fear and Greed
    
    func getFearGreed() async {
        if let fearGreed = await fearGreedRepository.getFearGreed() {
            self.fearGreed = fearGreed
        }
    }
    
    // MARK: - Gas fees

    func getGasFees() async {
        if let gasFees = await gasFeesRepository.getGasFees() {
            self.gasFees = gasFees
        }
    }

    // MARK: - Private functions

    private func orderedTrendingCoins(_ coins: [Toplist]) async -> [Toplist] {
        guard
            let trendingIds = await trendingRepository.cachedTrending?.data.coins?.compactMap({ $0.item?.id }),
            !trendingIds.isEmpty
        else {
            return coins
        }

        return trendingIds.compactMap { id in
            coins.first(where: { $0.id == id })
        }
    }

    private func setShowFreeTrial() async {
        let date: Date? = await cachedStorageManager.load(type: LocalStorageKeys.homeNextFreeTrialDate)

        if let date, date.moreThanAMonth() {
            await cachedStorageManager.save(type: LocalStorageKeys.homeShowFreeTrial, data: true)
        } else if date == nil {
            await cachedStorageManager.save(type: LocalStorageKeys.homeNextFreeTrialDate, data: Date.futureDate(byAddingDays: 7))
            await cachedStorageManager.save(type: LocalStorageKeys.homeShowFreeTrial, data: false)
        }

        showFreeTrial = await cachedStorageManager.load(type: LocalStorageKeys.homeShowFreeTrial) ?? false
    }
    
    private func setShowWelcomeMessage() async {
        var date: Date? = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate)

        if date == nil {
            date = Date.futureDate(byAddingDays: 3)
            await cachedStorageManager.save(type: LocalStorageKeys.homeWelcomeOfferDate, data: date)
        }

        offerTimeLeftDate = date

        guard let date, date > Date() else { return }

        setWelcomeTimerDate()
        await MainActor.run {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setWelcomeTimerDate), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func setWelcomeTimerDate() {
        Task { @MainActor in
            guard let endDate: Date = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate), endDate > Date() else {
                timer?.invalidate()
                timer = nil
                offerTimeLeft = nil
                didCloseWelcome = true
                await cachedStorageManager.save(type: LocalStorageKeys.didCloseWelcome, data: true)

                if promotionTitle == "Welcome Offer!" {
                    promotionTitle = nil
                    promotionMessage = nil
                }

                return
            }

            let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: endDate)
            offerTimeLeft = "Expires in \(components.day ?? 0)d \(components.hour ?? 0)h \(components.minute ?? 0)m \(components.second ?? 0)s"
        }
    }
    
    private func setPremiumOffer(products: [Product]?, isEligableForTrial: Bool, hasBoughtPro: Bool) async {
        guard !hasBoughtPro, isEligableForTrial, let products, !products.isEmpty else { return }

        let offerProduct = products.first(where: { $0.id == promotionalName })
        let welcomeProduct = products.first(where: { $0.id == welcomeName })

        let offer = offerProduct?.subscription?.introductoryOffer
        let welcomeOffer = welcomeProduct?.subscription?.introductoryOffer
        let welcomeEndDate: Date? = await cachedStorageManager.load(type: LocalStorageKeys.homeWelcomeOfferDate)

        if !didClosePromotions, let showOffer = await firebaseManger.getConfigBool(key: .showPromotionalOffer), showOffer, let offer {

            let currency = offerProduct?.getCurrency() ?? settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let priceAccessible = offer.price.doubleValue.currencyAccessible(currency: currency)

            let description = offer.period.unit.localizedDescription.lowercased()
            promotionTitle = "Limited Time Offer!"
            promotionMessage = formattedOfferMessage(period: offer.periodCount, description: description, price: offer.displayPrice)
            promotionMessageAccessible = formattedOfferMessage(period: offer.periodCount, description: description, price: priceAccessible)

        } else if !didCloseWelcome, let welcomeOffer, let endDate = welcomeEndDate, endDate > Date() {

            let currency = welcomeProduct?.getCurrency() ?? settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let priceAccessible = welcomeOffer.price.doubleValue.currencyAccessible(currency: currency)

            let description = welcomeOffer.period.unit.localizedDescription.lowercased()
            promotionTitle = "Welcome Offer!"
            promotionMessage = formattedOfferMessage(period: welcomeOffer.periodCount, description: description, price: welcomeOffer.displayPrice)
            promotionMessageAccessible = formattedOfferMessage(period: welcomeOffer.periodCount, description: description, price: priceAccessible)

        } else if showFreeTrial {
            promotionTitle = "Free trial"
            promotionMessage = "Try CoinCurrently Pro for free"
            promotionMessageAccessible = "Try CoinCurrently Pro for free"
        }
    }
    
    private func setFirebaseInformationMessage() async {
        guard let information = await firebaseManger.getFirebaseInformationMessage(),
              !SettingsManager.shared.getKeyExists(key: information.messageId) else { return }
        
        informationMessage = information.message
        informationKey = information.messageId
    }
    
    private func formattedOfferMessage(period: Int, description: String, price: String) -> String {
        "Get \(period) \(description) of CoinCurrently Pro for only \(price)!"
    }
}
