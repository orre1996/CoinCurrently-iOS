//
//  DerivativeDetailViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-27.
//

import Foundation

@MainActor
protocol DerivativeDetailViewModel {
    var derativeDetail: Derivative? { get }
    var perpetualList: [DerivativeDetail] { get }
    var futuresList: [DerivativeDetail] { get }
    var bitcoin: CurrencyDataModel? { get }
    
    var multiplier: Double? { get set }

    func getDerativeDetail() async
    func getBitcoin() async
}

@MainActor @Observable
final class DerivativeDetailViewModelImp: DerivativeDetailViewModel {
    var derativeDetail: Derivative?
    var perpetualList = [DerivativeDetail]()
    var futuresList = [DerivativeDetail]()
    var bitcoin: CurrencyDataModel?
    var toplist: [Toplist]?
    
    var multiplier: Double?
    var selectedSortOption: SortOption = .mktCapDesc
    
    private let derivativeDetailsRepository: DerivativeDetailsRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let toplistRepository: ToplistRepository
    private let storageManager: CachedStorageManager
    
    init(
        derivative: Derivative,
        derivativeDetailsRepository: DerivativeDetailsRepository = DerivativeDetailsRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.derivativeDetailsRepository = derivativeDetailsRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.toplistRepository = toplistRepository
        self.storageManager = storageManager
        
        self.derativeDetail = derivative
        self.selectedSortOption = .mktCapDesc
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        await derivativeDetailsRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.derivativeDetailSortOption.rawValue) ?? .openInterestDesc
        
        if let toplist = await toplistRepository.cachedToplist[SortOption.mktCapDesc.toplistApiValue]?.data, !toplist.isEmpty {
            self.toplist = toplist
        }
        
        if let id = derativeDetail?.id, let data = await derivativeDetailsRepository.cachedDerivatives[id]?.data {
            self.derativeDetail = data
            setLists()
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
            setPriceMultiplier()
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.derivativeDetailSortOption.rawValue, data: selectedSortOption)
        setLists()
    }
    
    func getToplist() async {
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: nil
        ) {
            self.toplist = toplist
        }
    }
    
    func getDerativeDetail() async {
        guard let derivative = await derivativeDetailsRepository.getDerivativeDetail(id: derativeDetail?.id) else {
            return
        }
        
        derativeDetail = derivative
        setLists()
    }
    
    private func setLists() {        
        let perpetuals = derativeDetail?.tickers?.filter({ $0.contract_type == "perpetual" }).sorted(by: { ( $0.open_interest_usd ?? 0.0) > ($1.open_interest_usd ?? 0.0) }) ?? []
        
        perpetualList = sortToplist(
            derivatives: perpetuals,
            newSortOption: selectedSortOption
        )
        
        let futures = derativeDetail?.tickers?.filter({ $0.contract_type == "futures" }).sorted(by: { ($0.open_interest_usd ?? 0.0) > ($1.open_interest_usd ?? 0.0) }) ?? []
        
        futuresList = sortToplist(
            derivatives: futures,
            newSortOption: selectedSortOption
        )
        
        Task {
            if
                let secret: HiddenSecret = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message),
                secret.secret_number == "4"
            {
                self.futuresList.insert(
                    DerivativeDetail(
                        symbol: "You found the secret message. Click here to join the raffle!",
                        trade_url: secret.secret_url,
                        open_interest_usd: 12345,
                        converted_last: ConvertedLastString(btc: "12345", eth: "12345", usd: "12345")
                    ), at: 31)
            }
        }
    }
    
    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
            setPriceMultiplier()
        }
    }
    
    func setPriceMultiplier() {
        guard let bitcoin else {
            return
        }

        let code = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
        let target = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: code.uppercased()) ?? 0.0
        let base = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: "USD") ?? 0.0
        multiplier = target / base
    }
    
    private func sortToplist(
        derivatives: [DerivativeDetail],
        newSortOption: SortOption
    ) -> [DerivativeDetail] {
        switch newSortOption {
        case .openInterestDesc:
            return derivatives.sorted(by: { ($0.open_interest_usd ?? 0) > ($1.open_interest_usd ?? 0) })
        case .openInterestAsc:
            return derivatives.sorted(by: { ($0.open_interest_usd ?? 0) < ($1.open_interest_usd ?? 0) })
        case .priceDesc:
            return derivatives.sorted(by: { (Double($0.converted_last?.btc ?? "0") ?? 0) > (Double($1.converted_last?.btc ?? "0") ?? 0) })
        case .priceAsc:
            return derivatives.sorted(by: { (Double($0.converted_last?.btc ?? "0") ?? 0) < (Double($1.converted_last?.btc ?? "0") ?? 0) })
        default:
            return derivatives
        }
    }
}
