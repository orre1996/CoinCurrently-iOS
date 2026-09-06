//
//  NFTDetailViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-08.
//

import SwiftUI
import Combine

@MainActor
protocol NFTDetailViewModel: ChartHoverHosting {
    var nftDetailInfo: NFTDetail { get set }
    var priceVolumeModel: NFTPriceVolumeModel? { get set }
    var currentCurrency: CurrencyDataModel? { get set }
    var bitcoin: CurrencyDataModel? { get set }
    var nftTickers: [NFTTicker]? { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var currentChartType: ChartTypes { get set }
    var isChartFiat: Bool { get set }
    var news: [NewsItem] { get set }
    var showNewsError: Bool { get set }
    var multiplier: Double? { get set }
    var selectedCurrency: CurrencyModel { get set }
    var showMainPriceError: Bool { get set }
    var prices: [Double] { get set }
    var prices24h: [Double] { get set }
    var onlyPrices: [Double] { get set }
    var timeStamps: [Double] { get set }
    var mainReloading: Bool { get set }
    var currentDays: String { get set }
    var mainGraphStats: [String?] { get }
    var graphColor: Color { get }
    var changePercent: Double? { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var selectedSortOption: SortOption { get set }
    var exchangeMarketItems: [ExchangeMarketItem]? { get set }
    var currencyLogo: UIImage? { get }

    func setStartData() async
    func setSelectedCurrency() async
    func getCurrentCurrency() async
    func getBitcoin() async
    func getDetail() async
    func getTickers() async
    func getMainCurrencyPrices(days: String) async
    func getNews() async
    func refresh(newDays: String?, newTimeChart: TimeCharts?,  getNews: Bool, getTickers: Bool) async
    func setChartType(type: ChartTypes)
    func getPricesRangePrefix(priceVolume: NFTPriceVolumeModel?) -> Int
    func toggleCurrencyType() async
    func getPrices(onlyPrices: Bool) -> [Double]
    func getOnlyPrices() -> [Double]
    func setPrices()
    func setOnlyPrices()
    func getPriceInChart(prices: [Double], at index: Int) -> String?
    func getTimestamps() -> [Double]
    func setTimestamps()
    func getChangePercent(onlyPrices: Bool) -> Double?
    func point(at index: Int, rect: CGSize) -> CGPoint
    func updateHoverStats(touches: [CGPoint])
    func setPriceMultiplier()
    func setNewSortOption(newSortOption: SortOption) async
}

@MainActor @Observable
final class NFTDetailViewModelImp: NFTDetailViewModel, ChartHoverHosting {
    private let nftDetailsRepository: NFTDetailRepository
    private let nftsRepository: NFTRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let newsRepository: NewsRepository
    private let globalRepository: GlobalMarketRepository
    private let storageManager: CachedStorageManager
    private let storeKitManager: StoreKitManager

    var nftDetailInfo: NFTDetail
    var priceVolumeModel: NFTPriceVolumeModel?
    var currentCurrency: CurrencyDataModel?
    var bitcoin: CurrencyDataModel?
    var nftTickers: [NFTTicker]?
    
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear)
    var currentChartType: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .price
    var isChartFiat = false
    
    var news = [NewsItem]()
    var showNewsError = false
    
    var multiplier: Double?
    var selectedCurrency = CurrencyModel(currency: "", code: "", symbol: "", locale: "", suffix: true)
    var showMainPriceError = false
    
    var prices = [Double]()
    var prices24h = [Double]()
    var onlyPrices = [Double]()
    var timeStamps = [Double]()

    var selectedSortOption: SortOption = .priceDesc
    var exchangeMarketItems: [ExchangeMarketItem]? = nil
    
    var hover = ChartHoverState()
    var currencyLogo: UIImage?

    init(
        nftToplist: NFTToplist,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        nftDetailsRepository: NFTDetailRepository = NFTDetailRepositoryImp.shared,
        nftsRepository: NFTRepository = NFTRepositoryImp.shared,
        globalRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) {
        self.nftDetailInfo = nftToplist.toNFTDetail
        self.cryptoDetailRepository = cryptoDetailRepository
        self.newsRepository = newsRepository
        self.nftDetailsRepository = nftDetailsRepository
        self.nftsRepository = nftsRepository
        self.globalRepository = globalRepository
        self.storageManager = storageManager
        self.storeKitManager = storeKitManager
        
        self.isChartFiat = false
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await nftDetailsRepository.ensureCacheLoaded()
        await nftsRepository.ensureCacheLoaded()
        await globalRepository.ensureCacheLoaded()
        
        isChartFiat = await storageManager.load(type: AppSettingKey.isNFTChartFiat.rawValue) ?? false
        selectedSortOption = await storageManager.load(type: AppSettingKey.nftDetailSortOption.rawValue) ?? .priceDesc
        let name = nftDetailInfo.name
        let id = nftDetailInfo.id ?? ""
        
        if !id.isEmpty {
            await nftDetailsRepository.loadCachedDataForNFT(id: id, days: currentDays)
        }
        if let nativeCurrencyId = nftDetailInfo.native_currency, !nativeCurrencyId.isEmpty {
            await cryptoDetailRepository.loadCachedDataForCoin(id: nativeCurrencyId, chart: selectedTimeFrame)
        }
        
        if let currency = await cryptoDetailRepository.cachedCryptoDetail[nftDetailInfo.native_currency ?? ""]?.data {
            self.currentCurrency = currency
        }
        
        if let prices = await nftDetailsRepository.cachedNFTPrices["\(id)-\(currentDays)"]?.data {
            self.priceVolumeModel = prices
        }
        
        if let nftTickers = await nftDetailsRepository.cachedNFTTickers[id]?.data {
            self.nftTickers = nftTickers
        }
        updateExchangeMarketItems()

        if let news = await newsRepository.cachedNews[NewsType.exchange(id: String(name?.split(separator: " ").first ?? ""))] {
            self.news = news.data.data
        }

        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
            self.setPriceMultiplier()
        }
        
        await setSelectedCurrency()
    }
    
    func setSelectedCurrency() async {
        let fiatCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        selectedCurrency = isChartFiat ? fiatCurrency : await nativeChartCurrency()
        hover.valueStyle = .currency(threshold: .million, currency: selectedCurrency)
    }
    
    private func nativeChartCurrency() async -> CurrencyModel {
        if let symbol = nftDetailInfo.native_currency_symbol?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            let spelledSymbol = symbol.uppercased().map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol,
                symbol: symbol,
                locale: "",
                suffix: true
            )
        }
        
        if let nativeCurrency = nftDetailInfo.native_currency, !nativeCurrency.isEmpty {
            return CurrencyModel(
                currency: nativeCurrency,
                code: nativeCurrency,
                symbol: "",
                locale: "",
                suffix: true
            )
        }
        
        let nftSymbol = await globalRepository.cachedCoinList?.data.first(where: {
            $0.id?.lowercased() == nftDetailInfo.native_currency?.lowercased() ?? ""
                || $0.name?.lowercased() == nftDetailInfo.native_currency?.lowercased() ?? ""
        })?.symbol?.uppercased() ?? ""
        
        let spelledSymbol = nftSymbol.map { String($0) }.joined(separator: " ")
        return CurrencyModel(
            currency: spelledSymbol.isEmpty ? nftSymbol : spelledSymbol,
            code: nftSymbol,
            symbol: nftSymbol,
            locale: "",
            suffix: true
        )
    }
    
    func getCurrentCurrency() async {
        guard let platforms = await nftsRepository.getNFTPlatforms() else {
            return
        }

        let nativeId = platforms.first(where: { $0.id == nftDetailInfo.asset_platform_id })?.native_coin_id
        
        if let currency = await cryptoDetailRepository.getCurrencyDetails(id: nativeId) {
            self.currentCurrency = currency
        }
    }
    
    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
            self.setPriceMultiplier()
        }
    }
    
    func getDetail() async {
        if let nftDetail = await nftDetailsRepository.getNFTDetail(id: nftDetailInfo.id) {
            nftDetailInfo = nftDetail
            await setSelectedCurrency()
            
            guard let image = await cryptoDetailRepository.getImage(url: nftDetail.image?.small) else { return }
            currencyLogo = image
        }
    }
    
    func getTickers() async {
        if let nftTickers = await nftDetailsRepository.getNFTTickers(id: nftDetailInfo.id) {
            self.nftTickers = nftTickers
            updateExchangeMarketItems()
        }
    }
    
    func getMainCurrencyPrices(days: String) async {
        priceVolumeModel = await nftDetailsRepository.getNFTPrices(id: nftDetailInfo.id, days: days)

        showMainPriceError = priceVolumeModel == nil
    }
    
    func getNews() async {
        guard let id = nftDetailInfo.name?.split(separator: " ").first?.description else { return }
        
        showNewsError = false

        if let news = await newsRepository.getNews(type: .exchange(id: id), count: 25), !news.isEmpty {
            self.news = news
        } else {
            showNewsError = true
        }
    }
    
    func refresh(
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil,
        getNews: Bool = false,
        getTickers: Bool = false
    ) async {
        mainReloading = true
        
        let days = newDays ?? self.currentDays
        let chart = newTimeChart ?? self.selectedTimeFrame
        
        await withTaskGroup(of: Void.self) { group in
            if getNews {
                group.addTask { await self.getNews() }
            }
            
            if getTickers {
                group.addTask { await self.getTickers() }
            }

            group.addTask {
                await self.getDetail()
                await self.getCurrentCurrency()
            }
            group.addTask { await self.getMainCurrencyPrices(days: days) }
            group.addTask { await self.getBitcoin() }
        }
        
        self.currentDays = days
        selectedTimeFrame = chart
        
        setPrices()
        setOnlyPrices()
        setTimestamps()
        
        mainReloading = false
    }
    
    func setChartType(type: ChartTypes) {
        currentChartType = type
        SettingsManager.shared.set(data: currentChartType, key: AppSettingKey.graphType)

        setPrices()
    }

    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.nftDetailSortOption.rawValue, data: selectedSortOption)
        updateExchangeMarketItems()
    }

    private func updateExchangeMarketItems() {
        guard let nftTickers else {
            exchangeMarketItems = nil
            return
        }
        let items = nftTickers.map { ExchangeMarketItem.from($0) }
        exchangeMarketItems = items.sorted(by: selectedSortOption)
    }

    func getPricesRangePrefix(priceVolume: NFTPriceVolumeModel?) -> Int {
        switch selectedTimeFrame {
            case .anHour:
                return (priceVolume?.floor_price_usd?.count ?? 0) / 24

            default:
                return (priceVolume?.floor_price_usd?.count ?? 0)
        }
    }

    var mainReloading = false
    
    var currentDays = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear).days

    func toggleCurrencyType() async {
        isChartFiat.toggle()
        await storageManager.save(type: AppSettingKey.isNFTChartFiat.rawValue, data: isChartFiat)

        AnalyticsManager.shared.log(
            ChartFiatNativeModeChanged(fromScreen: .nftDetail, isChartFiat: isChartFiat)
        )

        await setSelectedCurrency()
        setTimestamps()
        setPrices()
        setOnlyPrices()
    }
    
    func getPrices(onlyPrices: Bool = false) -> [Double] {
        return prices
    }
    
    func getOnlyPrices() -> [Double] {
        return onlyPrices
    }
    
    func setPrices() {
        var prices = [Double]()
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        let multiplier = isChartFiat ? (multiplier ?? 1) : 1
        
        if currentChartType == .price {
            prices = (isChartFiat ? priceVolumeModel?.floor_price_usd : priceVolumeModel?.floor_price_native)?.prefix(prefix).map {
                ($0.price ?? 0.0) * multiplier
            } ?? []
        } else if currentChartType == .volume {
            prices = (isChartFiat ? priceVolumeModel?.h24_volume_usd : priceVolumeModel?.h24_volume_native)?.prefix(prefix).map {
                ($0.price ?? 0.0) * multiplier
            } ?? []
            
        } else {
            prices = (isChartFiat ? priceVolumeModel?.market_cap_usd : priceVolumeModel?.market_cap_native)?.prefix(prefix).map {
                ($0.price ?? 0.0) * multiplier
            } ?? []
        }
        
        self.prices = prices
    }
    
    func setOnlyPrices() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        let multiplier = isChartFiat ? (multiplier ?? 1) : 1

        onlyPrices = (isChartFiat ? priceVolumeModel?.floor_price_usd : priceVolumeModel?.floor_price_native)?.prefix(prefix).map {
            ($0.price ?? 0.0) * multiplier
        } ?? []
    }

    var mainGraphStats: [String?] {
        return (0..<6).map({ getPriceInChart(prices: getPrices(), at: $0) })
    }

    func getPriceInChart(prices: [Double], at index: Int) -> String? {
        guard !showMainPriceError,
              let minPrice = prices.min(),
              let maxPrice = prices.max() else {
                  return nil
              }
        
        let step = (maxPrice - minPrice) / 5
        let value = minPrice + (step * Double(index))
        
        return value.formatCurrency(currency: CurrencyModel.empty)
    }
    
    func getTimestamps() -> [Double] {
        return timeStamps
    }
    
    func setTimestamps() {
        var timeStamps = [Double]()
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        
        if currentChartType == .price {
            timeStamps = (isChartFiat ? priceVolumeModel?.floor_price_usd : priceVolumeModel?.floor_price_native)?.prefix(prefix).map {
                $0.timestamp ?? 0.0
            } ?? []
        } else if currentChartType == .volume {
            timeStamps = (isChartFiat ? priceVolumeModel?.h24_volume_usd : priceVolumeModel?.h24_volume_native)?.prefix(prefix).map {
                $0.timestamp ?? 0.0
            } ?? []
        } else {
            timeStamps = (isChartFiat ? priceVolumeModel?.market_cap_usd : priceVolumeModel?.market_cap_native)?.prefix(prefix).map {
                $0.timestamp ?? 0.0
            } ?? []
        }
        
        self.timeStamps = timeStamps
    }
    
    func getChangePercent(onlyPrices: Bool) -> Double? {
        let prices = onlyPrices ? getOnlyPrices() : getPrices()
        let first = prices.last ?? 0.0
        let second = prices.first ?? 0.0
        let temp = first - second
        let change = 100.0 * Double(temp / second)
        
        if change.isNaN {
            return nil
        }
        
        return change
    }

    var graphColor: Color {
        hover.graphColor(idle: changePercent?.changeColor ?? .onSurfaceDim)
    }
    
    var changePercent: Double? {
        guard let first = getPrices().first,
              let last = getPrices().last else {
            return nil
        }
        
        return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
    }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(prices: getPrices())
    }
    
    var hoverPricePosition: CGFloat {
        hover.priceLabelX(prices: getPrices())
    }
    
    var mainDragIndex: [Int] {
        hover.linearDragIndices(priceCount: getPrices().count, timestamps: getTimestamps())
    }
    
    var dragPositions: [CGPoint] {
        hover.linearDragPositions(priceCount: getPrices().count, timestamps: getTimestamps()) { index, size in
            point(at: index, rect: size)
        }
    }

    func point(at index: Int, rect: CGSize) -> CGPoint {
        return calculatePoint(
            at: index,
            rect: rect,
            timestamps: getTimestamps(),
            prices: getPrices()
        )
    }
    
    func updateHoverStats(touches: [CGPoint]) {
        hover.updateLinear(
            touches: touches,
            prices: getPrices(),
            dates: getTimestamps(),
            timeChart: selectedTimeFrame,
            canUpdate: !mainReloading
        )
    }
    
    private func calculatePoint(
        at index: Int,
        rect: CGSize,
        timestamps: [Double],
        prices: [Double],
        adjustXByHalfPixel: Bool = true
    ) -> CGPoint {
        let normalizedPrices = prices.normalized
        let pointValue = normalizedPrices[safely: index] ?? 0

        let denominator = Double(normalizedPrices.count - 1)
        let x = rect.width * Double(index) / denominator
        let y = (1 - pointValue) * rect.height
        
        return CGPoint(
            x: adjustXByHalfPixel ? x - 0.5 : x,
            y: y.isNaN ? 0.5 * rect.height : y
        )
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
    
    func shareDetails() {
    #if IS_APP
        // Create snapshot image of share view
        let image = NFTDetailShareView(viewModel: self)
            .frame(width: 380, height: 370)
            .offset(y: -24)
            .snapshot
        
        guard let iosURL = URL(string: "https://tinyurl.com/ygznuo76"),
              let androidURL = URL(string: "https://tinyurl.com/yz5w8ozj") else { return }
        
        let text = """
        Track \(nftDetailInfo.name ?? "") and other NFTs in real time with CoinCurrently.
        Download the app for free.
        iOS: \(iosURL)
        Android: \(androidURL)
        """
        
        let activityItemSource = ActivityControllerItemSource(title: "CoinCurrently", text: text)
        let activityViewController = UIActivityViewController(activityItems: [image, activityItemSource], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activityType, completed, _, _ in
            let typeKey = activityType?.rawValue ?? "none"
            AnalyticsManager.shared.log(
                AppShareActivityCompleted(
                    fromScreen: .nftDetail,
                    activityType: typeKey,
                    completed: completed
                )
            )
        }
        
        if let popover = activityViewController.popoverPresentationController,
           let rootView = UIApplication.shared.window?.rootViewController?.view {
            popover.sourceView = rootView
            popover.sourceRect = CGRect.zero
            popover.permittedArrowDirections = []
        }
        
        UIApplication.shared.window?.rootViewController?.present(activityViewController, animated: true)
    #endif
    }
}
