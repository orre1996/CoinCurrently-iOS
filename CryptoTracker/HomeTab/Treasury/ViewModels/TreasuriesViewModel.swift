//
//  TreasuriesViewModel.swift
//  CoinCurrently
//

import Foundation
import SwiftUI

@MainActor
protocol TreasuriesViewModel {
    var treasury: PublicTreasuryModel? { get }
    var filteredTotalHoldings: Double? { get }
    var filteredMarketCapDominance: Double? { get }
    var holders: [TreasuryListItem] { get }
    var availableCoins: [Toplist] { get }
    var selectedCoin: Toplist? { get }
    var selectedEntityFilter: TreasuryEntityFilter { get set }
    var selectedCoinId: String { get set }
    var treasuriesDownloading: Bool { get }
    var bitcoin: CurrencyDataModel? { get }
    var multiplier: Double? { get }

    func setStartData() async
    func loadAvailableCoins() async
    func getTreasuries() async
    func getBitcoin() async
    func setEntityFilter(_ filter: TreasuryEntityFilter) async
    func setSelectedCoin(_ coin: Toplist) async
}

@MainActor @Observable
final class TreasuriesViewModelImp: TreasuriesViewModel, ObservableObject {
    private(set) var treasury: PublicTreasuryModel?
    private(set) var filteredTotalHoldings: Double?
    private(set) var filteredMarketCapDominance: Double?
    private(set) var holders = [TreasuryListItem]()
    private(set) var availableCoins = [Toplist]()
    private(set) var selectedCoin: Toplist?
    private(set) var treasuriesDownloading = false
    private(set) var bitcoin: CurrencyDataModel?
    private(set) var multiplier: Double?

    var selectedEntityFilter: TreasuryEntityFilter = .all
    var selectedCoinId: String = TreasuryCoinId.bitcoin.rawValue

    private var allHolders = [TreasuryListItem]()
    private var companiesTreasury: PublicTreasuryModel?
    private var governmentsTreasury: PublicTreasuryModel?

    private let publicTreasuryRepository: PublicTreasuryRepository
    private let toplistRepository: ToplistRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager

    init(
        publicTreasuryRepository: PublicTreasuryRepository = PublicTreasuryRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.publicTreasuryRepository = publicTreasuryRepository
        self.toplistRepository = toplistRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
    }

    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()

        selectedEntityFilter = await storageManager.load(type: AppSettingKey.treasuriesEntityFilter.rawValue) ?? .all

        if let savedCoinId: String = await storageManager.load(type: AppSettingKey.treasuriesCoinId.rawValue) {
            selectedCoinId = savedCoinId
        }

        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }

        await loadAvailableCoins()
        await loadCachedTreasuries()
    }

    func loadAvailableCoins() async {
        guard let smallToplist = await toplistRepository.getSmallToplist() else { return }

        availableCoins = smallToplist.filter { $0.id != nil }

        selectedCoin = availableCoins.first(where: { $0.id == selectedCoinId })
            ?? availableCoins.first

        if let selectedCoinId = selectedCoin?.id {
            self.selectedCoinId = selectedCoinId
        }
    }

    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }
    }

    func getTreasuries() async {
        async let companies = publicTreasuryRepository.getPublicTreasury(
            entity: .companies,
            coinId: selectedCoinId,
            page: 1,
            perPage: 250
        )
        
        async let governments = publicTreasuryRepository.getPublicTreasury(
            entity: .governments,
            coinId: selectedCoinId,
            page: 1,
            perPage: 250
        )

        applyMergedTreasury(
            companies: await companies,
            governments: await governments
        )
    }

    func setEntityFilter(_ filter: TreasuryEntityFilter) async {
        selectedEntityFilter = filter
        await storageManager.save(type: AppSettingKey.treasuriesEntityFilter.rawValue, data: selectedEntityFilter)
        applyEntityFilter()
    }

    func setSelectedCoin(_ coin: Toplist) async {
        guard let id = coin.id, id != selectedCoinId else { return }

        clearTreasuryData()

        selectedCoin = coin
        selectedCoinId = id
        await storageManager.save(type: AppSettingKey.treasuriesCoinId.rawValue, data: id)
        await getTreasuries()
    }

    private func clearTreasuryData() {
        treasury = nil
        companiesTreasury = nil
        governmentsTreasury = nil
        filteredTotalHoldings = nil
        filteredMarketCapDominance = nil
        holders = []
        allHolders = []
    }

    private func loadCachedTreasuries() async {
        await publicTreasuryRepository.ensureCacheLoaded(entity: .companies, coinId: selectedCoinId)
        await publicTreasuryRepository.ensureCacheLoaded(entity: .governments, coinId: selectedCoinId)

        applyMergedTreasury(
            companies: await publicTreasuryRepository.getCachedTreasury(entity: .companies, coinId: selectedCoinId),
            governments: await publicTreasuryRepository.getCachedTreasury(entity: .governments, coinId: selectedCoinId)
        )
    }

    private func applyMergedTreasury(
        companies: PublicTreasuryModel?,
        governments: PublicTreasuryModel?
    ) {
        companiesTreasury = companies
        governmentsTreasury = governments

        let companyHolders = companies?.companies ?? []
        let governmentHolders = governments?.governments ?? []

        allHolders = (companyHolders.map { TreasuryListItem(holder: $0, entity: .companies, coinId: selectedCoinId) }
            + governmentHolders.map { TreasuryListItem(holder: $0, entity: .governments, coinId: selectedCoinId) })
            .sorted { ($0.holder.total_current_value_usd ?? 0) > ($1.holder.total_current_value_usd ?? 0) }

        guard companies != nil || governments != nil else {
            treasury = nil
            applyEntityFilter()
            return
        }

        treasury = PublicTreasuryModel(
            total_holdings: (companies?.total_holdings ?? 0) + (governments?.total_holdings ?? 0),
            total_value_usd: (companies?.total_value_usd ?? 0) + (governments?.total_value_usd ?? 0),
            market_cap_dominance: (companies?.market_cap_dominance ?? 0) + (governments?.market_cap_dominance ?? 0),
            companies: companyHolders.isEmpty ? nil : companyHolders,
            governments: governmentHolders.isEmpty ? nil : governmentHolders
        )

        applyEntityFilter()
    }

    private func applyEntityFilter() {
        let hasLoadedData = companiesTreasury != nil || governmentsTreasury != nil

        switch selectedEntityFilter {
        case .all:
            holders = allHolders
            guard hasLoadedData else {
                filteredTotalHoldings = nil
                filteredMarketCapDominance = nil
                return
            }
            filteredTotalHoldings = (companiesTreasury?.total_holdings ?? 0) + (governmentsTreasury?.total_holdings ?? 0)
            filteredMarketCapDominance = (companiesTreasury?.market_cap_dominance ?? 0) + (governmentsTreasury?.market_cap_dominance ?? 0)
            
        case .companies:
            holders = allHolders.filter { $0.entity == .companies }
            guard hasLoadedData else {
                filteredTotalHoldings = nil
                filteredMarketCapDominance = nil
                return
            }
            filteredTotalHoldings = companiesTreasury?.total_holdings ?? 0
            filteredMarketCapDominance = companiesTreasury?.market_cap_dominance ?? 0
            
        case .governments:
            holders = allHolders.filter { $0.entity == .governments }
            guard hasLoadedData else {
                filteredTotalHoldings = nil
                filteredMarketCapDominance = nil
                return
            }
            filteredTotalHoldings = governmentsTreasury?.total_holdings ?? 0
            filteredMarketCapDominance = governmentsTreasury?.market_cap_dominance ?? 0
        }
    }

    private func calculatePriceMultiplier(from bitcoin: CurrencyDataModel) -> Double? {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let targetPrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code.uppercased()) ?? 0
        let basePrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: "USD") ?? 0

        guard basePrice > 0 else { return nil }
        return targetPrice / basePrice
    }
}
