import Testing
@testable import CoinCurrently

@Suite("TreasuriesViewModel Tests")
struct TreasuriesViewModelTests {

    @Test("setStartData loads cached treasury for both entities")
    func setStartDataLoadsCachedTreasury() async {
        let companiesTreasury = PublicTreasuryModel(
            total_holdings: 1000,
            total_value_usd: 50000000,
            market_cap_dominance: 5.0,
            companies: [
                PublicTreasuryHolder(
                    id: "strategy",
                    name: "Strategy",
                    symbol: "MSTR.US",
                    country: "US",
                    total_holdings: 843738,
                    total_entry_value_usd: 63870055699,
                    total_current_value_usd: 64484706340.10,
                    percentage_of_total_supply: 4.018
                )
            ],
            governments: nil
        )

        let mockRepo = MockPublicTreasuryRepository(cachedTreasuries: [
            .companies: companiesTreasury
        ])
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: mockRepo,
            toplistRepository: MockTreasuryToplistRepository()
        )

        await viewModel.setStartData()

        #expect(viewModel.treasury?.total_holdings == 1000)
        #expect(viewModel.holders.count == 1)
        #expect(viewModel.holders.first?.holder.name == "Strategy")
        #expect(viewModel.holders.first?.entity == .companies)
    }

    @Test("getTreasuries merges companies and governments into one list")
    func getTreasuriesMergesBothEntities() async {
        let companiesTreasury = PublicTreasuryModel(
            total_holdings: 1000,
            total_value_usd: 50000000,
            market_cap_dominance: 5.0,
            companies: [
                PublicTreasuryHolder(
                    id: "strategy",
                    name: "Strategy",
                    symbol: "MSTR.US",
                    country: "US",
                    total_holdings: 843738,
                    total_entry_value_usd: 63870055699,
                    total_current_value_usd: 64484706340.10,
                    percentage_of_total_supply: 4.018
                )
            ],
            governments: nil
        )
        let governmentsTreasury = PublicTreasuryModel(
            total_holdings: 2000,
            total_value_usd: 100000000,
            market_cap_dominance: 5.0,
            companies: nil,
            governments: [
                PublicTreasuryHolder(
                    id: "usa",
                    name: "USA",
                    symbol: nil,
                    country: "US",
                    total_holdings: 207189,
                    total_entry_value_usd: 0,
                    total_current_value_usd: 70000000000,
                    percentage_of_total_supply: 0.98
                )
            ]
        )

        let mockRepo = MockPublicTreasuryRepository(fetchResults: [
            .companies: companiesTreasury,
            .governments: governmentsTreasury
        ])
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: mockRepo,
            toplistRepository: MockTreasuryToplistRepository()
        )

        await viewModel.getTreasuries()

        #expect(viewModel.treasury?.total_holdings == 3000)
        #expect(viewModel.treasury?.total_value_usd == 150000000)
        #expect(viewModel.holders.count == 2)
        #expect(viewModel.holders.first?.holder.name == "USA")
        #expect(viewModel.holders.first?.entity == .governments)
        #expect(viewModel.holders.last?.holder.name == "Strategy")
        #expect(viewModel.holders.last?.entity == .companies)
    }

    @Test("setEntityFilter filters merged holders")
    func setEntityFilterFiltersHolders() async {
        let companiesTreasury = PublicTreasuryModel(
            total_holdings: 1000,
            total_value_usd: 50000000,
            market_cap_dominance: 5.0,
            companies: [
                PublicTreasuryHolder(
                    id: "strategy",
                    name: "Strategy",
                    symbol: "MSTR.US",
                    country: "US",
                    total_holdings: 843738,
                    total_entry_value_usd: 63870055699,
                    total_current_value_usd: 64484706340.10,
                    percentage_of_total_supply: 4.018
                )
            ],
            governments: nil
        )
        let governmentsTreasury = PublicTreasuryModel(
            total_holdings: 2000,
            total_value_usd: 100000000,
            market_cap_dominance: 5.0,
            companies: nil,
            governments: [
                PublicTreasuryHolder(
                    id: "usa",
                    name: "USA",
                    symbol: nil,
                    country: "US",
                    total_holdings: 207189,
                    total_entry_value_usd: 0,
                    total_current_value_usd: 70000000000,
                    percentage_of_total_supply: 0.98
                )
            ]
        )

        let mockRepo = MockPublicTreasuryRepository(fetchResults: [
            .companies: companiesTreasury,
            .governments: governmentsTreasury
        ])
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: mockRepo,
            toplistRepository: MockTreasuryToplistRepository()
        )

        await viewModel.getTreasuries()
        await viewModel.setEntityFilter(.companies)

        #expect(viewModel.holders.count == 1)
        #expect(viewModel.holders.first?.holder.name == "Strategy")
    }

    @Test("setEntityFilter filters summary totals")
    func setEntityFilterFiltersSummaryTotals() async {
        let companiesTreasury = PublicTreasuryModel(
            total_holdings: 1000,
            total_value_usd: 50000000,
            market_cap_dominance: 4.0,
            companies: [
                PublicTreasuryHolder(
                    id: "strategy",
                    name: "Strategy",
                    symbol: "MSTR.US",
                    country: "US",
                    total_holdings: 843738,
                    total_entry_value_usd: 63870055699,
                    total_current_value_usd: 64484706340.10,
                    percentage_of_total_supply: 4.018
                )
            ],
            governments: nil
        )
        let governmentsTreasury = PublicTreasuryModel(
            total_holdings: 2000,
            total_value_usd: 100000000,
            market_cap_dominance: 2.0,
            companies: nil,
            governments: [
                PublicTreasuryHolder(
                    id: "usa",
                    name: "USA",
                    symbol: nil,
                    country: "US",
                    total_holdings: 207189,
                    total_entry_value_usd: 0,
                    total_current_value_usd: 70000000000,
                    percentage_of_total_supply: 0.98
                )
            ]
        )

        let mockRepo = MockPublicTreasuryRepository(fetchResults: [
            .companies: companiesTreasury,
            .governments: governmentsTreasury
        ])
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: mockRepo,
            toplistRepository: MockTreasuryToplistRepository()
        )

        await viewModel.getTreasuries()

        #expect(viewModel.filteredTotalHoldings == 3000)
        #expect(viewModel.filteredMarketCapDominance == 6.0)

        await viewModel.setEntityFilter(.companies)

        #expect(viewModel.filteredTotalHoldings == 1000)
        #expect(viewModel.filteredMarketCapDominance == 4.0)

        await viewModel.setEntityFilter(.governments)

        #expect(viewModel.filteredTotalHoldings == 2000)
        #expect(viewModel.filteredMarketCapDominance == 2.0)
    }

    @Test("setSelectedCoin clears holders before fetching new coin data")
    func setSelectedCoinClearsHolders() async {
        let companiesTreasury = PublicTreasuryModel(
            total_holdings: 1000,
            total_value_usd: 50000000,
            market_cap_dominance: 5.0,
            companies: [
                PublicTreasuryHolder(
                    id: "strategy",
                    name: "Strategy",
                    symbol: "MSTR.US",
                    country: "US",
                    total_holdings: 843738,
                    total_entry_value_usd: 63870055699,
                    total_current_value_usd: 64484706340.10,
                    percentage_of_total_supply: 4.018
                )
            ],
            governments: nil
        )

        let mockRepo = MockPublicTreasuryRepository(fetchResults: [
            .companies: companiesTreasury
        ])
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: mockRepo,
            toplistRepository: MockTreasuryToplistRepository(
                smallToplist: [
                    Toplist(id: "bitcoin", name: "Bitcoin", symbol: "btc"),
                    Toplist(id: "ethereum", name: "Ethereum", symbol: "eth")
                ]
            )
        )

        await viewModel.loadAvailableCoins()
        await viewModel.getTreasuries()
        #expect(viewModel.holders.count == 1)

        let fetchTask = Task {
            await viewModel.setSelectedCoin(Toplist(id: "ethereum", name: "Ethereum", symbol: "eth"))
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(viewModel.holders.isEmpty)

        await fetchTask.value
        #expect(viewModel.selectedCoinId == "ethereum")
    }

    @Test("loadAvailableCoins uses full smallToplist")
    func loadAvailableCoinsUsesFullSmallToplist() async {
        let viewModel = TreasuriesViewModelImp(
            publicTreasuryRepository: MockPublicTreasuryRepository(),
            toplistRepository: MockTreasuryToplistRepository(
                smallToplist: [
                    Toplist(id: "bitcoin", name: "Bitcoin", symbol: "btc"),
                    Toplist(id: "ethereum", name: "Ethereum", symbol: "eth"),
                    Toplist(id: "dogecoin", name: "Dogecoin", symbol: "doge")
                ]
            )
        )

        await viewModel.loadAvailableCoins()

        #expect(viewModel.availableCoins.count == 3)
        #expect(viewModel.availableCoins.map(\.id) == ["bitcoin", "ethereum", "dogecoin"])
        #expect(viewModel.selectedCoin?.name == "Bitcoin")
    }
}

private actor MockPublicTreasuryRepository: PublicTreasuryRepository {
    var cachedPublicTreasury: [String: CachedData<PublicTreasuryModel>] = [:]

    private let fetchResults: [TreasuryEntity: PublicTreasuryModel]

    init(
        cachedTreasuries: [TreasuryEntity: PublicTreasuryModel] = [:],
        fetchResults: [TreasuryEntity: PublicTreasuryModel] = [:]
    ) {
        self.fetchResults = fetchResults

        cachedTreasuries.forEach { entity, treasury in
            cachedPublicTreasury["\(entity.rawValue)-bitcoin"] = CachedData(data: treasury, date: Date())
        }
    }

    func ensureCacheLoaded(entity: TreasuryEntity, coinId: String) async {}

    func getCachedTreasury(entity: TreasuryEntity, coinId: String) -> PublicTreasuryModel? {
        cachedPublicTreasury["\(entity.rawValue)-\(coinId)"]?.data
    }

    func holderWithEntityId(
        _ holder: PublicTreasuryHolder,
        entity: TreasuryEntity
    ) async -> PublicTreasuryHolder {
        holder
    }

    func entityId(for holder: PublicTreasuryHolder, entity: TreasuryEntity) async -> String? {
        holder.id
    }

    func getPublicTreasury(
        entity: TreasuryEntity,
        coinId: String,
        page: Int,
        perPage: Int
    ) async -> PublicTreasuryModel? {
        fetchResults[entity]
    }
}

private actor MockTreasuryToplistRepository: ToplistRepository {
    var cachedFavorites: CachedData<[Toplist]>?
    var cachedSmallToplist: CachedData<[Toplist]>?
    var cachedToplist: [String: CachedData<[Toplist]>] = [:]

    private let smallToplist: [Toplist]?

    init(smallToplist: [Toplist]? = nil) {
        self.smallToplist = smallToplist
    }

    func ensureCacheLoaded() async {}
    func ensureFavoritesLoaded() async {}
    func migrateFavorites() async {}
    func getSmallToplist() async -> [Toplist]? { smallToplist }
    func getMarketToplist(sortOption: SortOption, priceChange: PriceChange, platformId: String?) async -> [Toplist]? { nil }
    func getFavorites() async -> [Toplist]? { nil }
    func favouriteButtonPressed(toplist: Toplist) async -> [Toplist] { [] }
    func updateFromToplist(coins: [Toplist]) async {}
    func refreshForCurrencyChange(sortOption: SortOption, priceChange: PriceChange) async {}
    func getCoin(id: String) async -> Toplist? {
        smallToplist?.first(where: { $0.id == id })
    }
}
