//
//  ExchangesViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-25.
//

import Foundation
import SwiftUI

@MainActor
protocol ExchangesViewModel {
    var exchanges: [ExchangeModel] { get }
    var selectedSortOption: SortOption { get set }
    var bitcoin: CurrencyDataModel? { get }
    var exchangesDownloading: Bool { get }

    func setStartData() async
    func setNewSortOption(newSortOption: SortOption) async
    func getExchanges() async
    func getBitcoin() async
}

@MainActor @Observable
final class ExchangesViewModelImp: ExchangesViewModel, ObservableObject {
    private(set) var exchanges = [ExchangeModel]()
    private(set) var bitcoin: CurrencyDataModel?
    private(set) var exchangesDownloading = false
    
    var selectedSortOption: SortOption = .volumeDesc
    
    private let exchangesRepository: ExchangesRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager
    
    init(
        exchangesRepository: ExchangesRepository = ExchangesRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.exchangesRepository = exchangesRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
        
        self.selectedSortOption = .trustScoreDesc
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await exchangesRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.exchangesSortOption.rawValue) ?? .trustScoreDesc
        if let exchanges = await exchangesRepository.cachedExchanges?.data {
            self.exchanges = sortToplist(
                exchanges: exchanges,
                newSortOption: selectedSortOption
            )
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.exchangesSortOption.rawValue, data: selectedSortOption)
        
        self.exchanges = sortToplist(
            exchanges: self.exchanges,
            newSortOption: selectedSortOption
        )
    }
    
    func getExchanges() async {
        if let exchanges = await exchangesRepository.getExchanges() {
            self.exchanges = sortToplist(
                exchanges: exchanges,
                newSortOption: selectedSortOption
            )
            
            if
                let secret: HiddenSecret = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message),
                secret.secret_number == "2"
            {
                self.exchanges.insert(
                    ExchangeModel(
                        name: "You found the secret message. Click here to join the raffle!",
                        url: secret.secret_url,
                        image: secret.secret_image,
                        trust_score: 10,
                        trade_volume_24h_btc: 1,
                    ), at: 23)
            }
        }
    }
    
    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
        }
    }
    
    private func sortToplist(
        exchanges: [ExchangeModel],
        newSortOption: SortOption
    ) -> [ExchangeModel] {
        switch newSortOption {
        case .nameDesc:
            return exchanges.sorted(by: { ($0.name?.trimmingCharacters(in: .whitespaces) ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedDescending })
        case .nameAsc:
            return exchanges.sorted(by: { ($0.name?.trimmingCharacters(in: .whitespaces) ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending })
        case .volumeDesc:
            return exchanges.sorted(by: { ($0.trade_volume_24h_btc ?? 0) > ($1.trade_volume_24h_btc ?? 0) })
        case .volumeAsc:
            return exchanges.sorted(by: { ($0.trade_volume_24h_btc ?? 0) < ($1.trade_volume_24h_btc ?? 0) })
        case .trustScoreDesc:
            return exchanges.sorted(by: { ($0.trust_score_rank ?? 0) < ($1.trust_score_rank ?? 0) })
        case .trustScoreAsc:
            return exchanges.sorted(by: { ($0.trust_score_rank ?? 0) > ($1.trust_score_rank ?? 0) })
        default:
            return exchanges
        }
    }
}
