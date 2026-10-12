import Foundation
import Testing
@testable import CoinCurrently

@Suite("PublicTreasuryRepository Tests")
struct PublicTreasuryRepositoryTests {

    @Test("getPublicTreasury returns decoded data")
    func getPublicTreasuryReturnsData() async {
        let mockTreasury = PublicTreasuryModel(
            total_holdings: 1272129.02,
            total_value_usd: 97225044888.65,
            market_cap_dominance: 6.06,
            companies: [
                PublicTreasuryHolder(
                    id: nil,
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

        let mockEntities = [
            TreasuryEntityListItem(
                id: "strategy",
                symbol: "MSTR.US",
                name: "Strategy",
                country: "US"
            )
        ]

        let mock = MockTreasuryNetworkManager(
            treasuryResult: mockTreasury,
            entitiesResults: [.companies: mockEntities]
        )
        let repo = PublicTreasuryRepositoryImp(networkManager: mock)

        let result = await repo.getPublicTreasury(
            entity: .companies,
            coinId: TreasuryCoinId.bitcoin.rawValue
        )

        #expect(result?.total_holdings == 1272129.02)
        #expect(result?.holders.count == 1)
        #expect(result?.holders.first?.name == "Strategy")
        #expect(result?.holders.first?.id == "strategy")
        let companyListCalls = await mock.entitiesListCallCount(for: .companies)
        #expect(companyListCalls == 2)
    }

    @Test("entityId resolves id from entities list")
    func entityIdResolvesId() async {
        let holder = PublicTreasuryHolder(
            id: nil,
            name: "Texas",
            symbol: "",
            country: "US",
            total_holdings: 1000,
            total_entry_value_usd: nil,
            total_current_value_usd: nil,
            percentage_of_total_supply: nil
        )

        let mockEntities = [
            TreasuryEntityListItem(
                id: "texas",
                symbol: "",
                name: "Texas",
                country: "US"
            )
        ]

        let mock = MockTreasuryNetworkManager(
            entitiesResults: [.governments: mockEntities]
        )
        let repo = PublicTreasuryRepositoryImp(networkManager: mock)

        let treasuryId = await repo.entityId(for: holder, entity: .governments)

        #expect(treasuryId == "texas")
    }

    @Test("holderWithEntityId resolves id from entities list")
    func holderWithEntityIdResolvesId() async {
        let holder = PublicTreasuryHolder(
            id: nil,
            name: "Strategy",
            symbol: "MSTR.US",
            country: "US",
            total_holdings: 843738,
            total_entry_value_usd: 63870055699,
            total_current_value_usd: 64484706340.10,
            percentage_of_total_supply: 4.018
        )

        let mockEntities = [
            TreasuryEntityListItem(
                id: "strategy",
                symbol: "MSTR.US",
                name: "Strategy",
                country: "US"
            )
        ]

        let mock = MockTreasuryNetworkManager(
            entitiesResults: [.companies: mockEntities]
        )
        let repo = PublicTreasuryRepositoryImp(networkManager: mock)

        let resolved = await repo.holderWithEntityId(holder, entity: .companies)

        #expect(resolved.id == "strategy")
        let companyListCalls = await mock.entitiesListCallCount(for: .companies)
        #expect(companyListCalls == 1)
    }

    @Test("getPublicTreasury returns nil when network fails")
    func getPublicTreasuryReturnsNil() async {
        let mock = MockTreasuryNetworkManager(treasuryResult: nil)
        let repo = PublicTreasuryRepositoryImp(networkManager: mock)

        let result = await repo.getPublicTreasury(
            entity: .governments,
            coinId: TreasuryCoinId.ethereum.rawValue
        )

        #expect(result == nil)
    }
}

@Suite("Public Treasury Endpoint Tests")
struct PublicTreasuryEndpointTests {

    @Test("companies bitcoin treasury path")
    func companiesBitcoinPath() async {
        let path = await Endpoint.publicTreasury(entity: .companies, coinId: TreasuryCoinId.bitcoin.rawValue).pathComponent(hasBoughtPro: true)
        #expect(path == "\(serverBaseUrl)/crypto/api/v3/companies/public_treasury/bitcoin")
    }

    @Test("governments bitcoin treasury path")
    func governmentsBitcoinPath() async {
        let path = await Endpoint.publicTreasury(entity: .governments, coinId: TreasuryCoinId.bitcoin.rawValue).pathComponent(hasBoughtPro: true)
        #expect(path == "\(serverBaseUrl)/crypto/api/v3/governments/public_treasury/bitcoin")
    }

    @Test("public treasury query items include pagination")
    func publicTreasuryQueryItems() {
        let items = Endpoint.publicTreasury(entity: .companies, coinId: TreasuryCoinId.solana.rawValue, page: 2, perPage: 100).queryItems
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "per_page", value: "100")))
    }

    @Test("entities list path")
    func entitiesListPath() async {
        let path = await Endpoint.entitiesList(entity: .companies).pathComponent(hasBoughtPro: true)
        #expect(path == "\(serverBaseUrl)/crypto/api/v3/entities/list")
    }

    @Test("entities list query items include entity type")
    func entitiesListQueryItems() {
        let items = Endpoint.entitiesList(entity: .governments, page: 2, perPage: 100).queryItems
        #expect(items.contains(URLQueryItem(name: "entity_type", value: "government")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "per_page", value: "100")))
    }

    @Test("TreasuryEntityListItem decodes null symbol from API")
    func treasuryEntityListItemDecodesNullSymbol() throws {
        let json = """
        [
          {"id": "texas", "symbol": "", "name": "Texas", "country": "US"},
          {"id": "united-states", "symbol": null, "name": "United States", "country": "US"}
        ]
        """.data(using: .utf8)!

        let items = try JSONDecoder().decode([TreasuryEntityListItem].self, from: json)

        #expect(items.count == 2)
        #expect(items[0].symbol == "")
        #expect(items[1].symbol == nil)
    }
}

private actor MockTreasuryNetworkManager: NetworkManager {
    private let treasuryResult: PublicTreasuryModel?
    private let entitiesResults: [TreasuryEntity: [TreasuryEntityListItem]]
    private var entitiesListCalls: [TreasuryEntity: Int] = [:]

    init(
        treasuryResult: PublicTreasuryModel? = nil,
        entitiesResults: [TreasuryEntity: [TreasuryEntityListItem]] = [:]
    ) {
        self.treasuryResult = treasuryResult
        self.entitiesResults = entitiesResults
    }

    func entitiesListCallCount(for entity: TreasuryEntity) -> Int {
        entitiesListCalls[entity, default: 0]
    }

    func setCurrentScreen(_ screen: String) {}

    func getCached<T: Decodable>(endpoint: Endpoint) async -> T? {
        nil
    }

    func get<T: Decodable>(endpoint: Endpoint) async -> T? {
        switch endpoint {
        case .publicTreasury:
            return treasuryResult as? T

        case .entitiesList(let entity, _, _):
            entitiesListCalls[entity, default: 0] += 1
            return entitiesResults[entity] as? T

        default:
            return nil
        }
    }

    func getRaw(endpoint: Endpoint) async -> (data: Data, response: HTTPURLResponse)? {
        nil
    }

    func persistDecodedResponse<T: Encodable>(_ value: T, endpoint: Endpoint) async {}

    func post<G: Codable, T: Codable>(endpoint: Endpoint, bodyStruct: T) async -> (G?, Int) {
        (nil, 500)
    }
}
