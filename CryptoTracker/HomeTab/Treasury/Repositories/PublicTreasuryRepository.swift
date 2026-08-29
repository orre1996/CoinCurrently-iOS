//
//  PublicTreasuryRepository.swift
//  CoinCurrently
//

import Foundation

protocol PublicTreasuryRepository: Actor {
    var cachedPublicTreasury: [String: CachedData<PublicTreasuryModel>] { get }

    func ensureCacheLoaded(entity: TreasuryEntity, coinId: String) async
    func getCachedTreasury(entity: TreasuryEntity, coinId: String) -> PublicTreasuryModel?
    func holderWithEntityId(_ holder: PublicTreasuryHolder, entity: TreasuryEntity) async -> PublicTreasuryHolder
    func entityId(for holder: PublicTreasuryHolder, entity: TreasuryEntity) async -> String?
    func getPublicTreasury(
        entity: TreasuryEntity,
        coinId: String,
        page: Int,
        perPage: Int
    ) async -> PublicTreasuryModel?
}

final actor PublicTreasuryRepositoryImp: PublicTreasuryRepository {
    static let shared = PublicTreasuryRepositoryImp()

    private let networkManager: NetworkManager
    private(set) var cachedPublicTreasury: [String: CachedData<PublicTreasuryModel>] = [:]
    private var cachedEntitiesList: [String: CachedData<[TreasuryEntityListItem]>] = [:]

    private var loadedCacheKeys = Set<String>()

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }

    func ensureCacheLoaded(entity: TreasuryEntity, coinId: String) async {
        let key = cacheKey(entity: entity, coinId: coinId)
        guard !loadedCacheKeys.contains(key) else { return }
        loadedCacheKeys.insert(key)

        await ensureEntitiesListLoaded(entity: entity)

        if let treasury: PublicTreasuryModel = await networkManager.getCached(
            endpoint: .publicTreasury(entity: entity, coinId: coinId)
        ) {
            let entities = cachedEntitiesList[entity.rawValue]?.data ?? []
            let mergedTreasury = applyEntityIds(to: treasury, entity: entity, entities: entities)
            cachedPublicTreasury[key] = CachedData(data: mergedTreasury, date: Date())
        }
    }

    func getCachedTreasury(entity: TreasuryEntity, coinId: String) -> PublicTreasuryModel? {
        cachedPublicTreasury[cacheKey(entity: entity, coinId: coinId)]?.data
    }

    func holderWithEntityId(
        _ holder: PublicTreasuryHolder,
        entity: TreasuryEntity
    ) async -> PublicTreasuryHolder {
        if let id = holder.id, !id.isEmpty {
            return holder
        }

        await ensureEntitiesListLoaded(entity: entity)
        let entities = cachedEntitiesList[entity.rawValue]?.data ?? []
        return mergeEntityId(holder, entities: entities)
    }

    func entityId(for holder: PublicTreasuryHolder, entity: TreasuryEntity) async -> String? {
        let resolvedHolder = await holderWithEntityId(holder, entity: entity)
        guard let id = resolvedHolder.id, !id.isEmpty else { return nil }
        return id
    }

    func getPublicTreasury(
        entity: TreasuryEntity,
        coinId: String,
        page: Int = 1,
        perPage: Int = 250
    ) async -> PublicTreasuryModel? {
        await ensureCacheLoaded(entity: entity, coinId: coinId)

        async let treasury: PublicTreasuryModel? = networkManager.get(
            endpoint: .publicTreasury(
                entity: entity,
                coinId: coinId,
                page: page,
                perPage: perPage
            )
        )
        async let entities = getEntitiesList(entity: entity, page: page, perPage: perPage)

        guard var treasury = await treasury else { return nil }

        if let entities = await entities {
            treasury = applyEntityIds(to: treasury, entity: entity, entities: entities)
        }

        cachedPublicTreasury[cacheKey(entity: entity, coinId: coinId)] = CachedData(data: treasury, date: Date())
        return treasury
    }

    private func getEntitiesList(
        entity: TreasuryEntity,
        page: Int,
        perPage: Int
    ) async -> [TreasuryEntityListItem]? {
        let entities: [TreasuryEntityListItem]? = await networkManager.get(
            endpoint: .entitiesList(entity: entity, page: page, perPage: perPage)
        )

        if let entities {
            cachedEntitiesList[entity.rawValue] = CachedData(data: entities, date: Date())
        }

        return entities
    }

    private func loadCachedEntitiesList(entity: TreasuryEntity) async {
        guard cachedEntitiesList[entity.rawValue] == nil else { return }

        if let entities: [TreasuryEntityListItem] = await networkManager.getCached(
            endpoint: .entitiesList(entity: entity)
        ) {
            cachedEntitiesList[entity.rawValue] = CachedData(data: entities, date: Date())
        }
    }

    private func ensureEntitiesListLoaded(entity: TreasuryEntity) async {
        if cachedEntitiesList[entity.rawValue] != nil {
            return
        }

        await loadCachedEntitiesList(entity: entity)

        if cachedEntitiesList[entity.rawValue] != nil {
            return
        }

        _ = await getEntitiesList(entity: entity, page: 1, perPage: 250)
    }

    private func applyEntityIds(
        to treasury: PublicTreasuryModel,
        entity: TreasuryEntity,
        entities: [TreasuryEntityListItem]
    ) -> PublicTreasuryModel {
        switch entity {
        case .companies:
            let companies = treasury.companies?.map { mergeEntityId($0, entities: entities) }
            return PublicTreasuryModel(
                total_holdings: treasury.total_holdings,
                total_value_usd: treasury.total_value_usd,
                market_cap_dominance: treasury.market_cap_dominance,
                companies: companies,
                governments: treasury.governments
            )

        case .governments:
            let governments = treasury.governments?.map { mergeEntityId($0, entities: entities) }
            return PublicTreasuryModel(
                total_holdings: treasury.total_holdings,
                total_value_usd: treasury.total_value_usd,
                market_cap_dominance: treasury.market_cap_dominance,
                companies: treasury.companies,
                governments: governments
            )
        }
    }

    private func mergeEntityId(
        _ holder: PublicTreasuryHolder,
        entities: [TreasuryEntityListItem]
    ) -> PublicTreasuryHolder {
        guard let matchedEntity = entities.first(where: { matches($0, holder: holder) }) else {
            return holder
        }

        return PublicTreasuryHolder(
            id: matchedEntity.id,
            name: holder.name,
            symbol: holder.symbol,
            country: holder.country,
            total_holdings: holder.total_holdings,
            total_entry_value_usd: holder.total_entry_value_usd,
            total_current_value_usd: holder.total_current_value_usd,
            percentage_of_total_supply: holder.percentage_of_total_supply
        )
    }

    private func matches(_ entity: TreasuryEntityListItem, holder: PublicTreasuryHolder) -> Bool {
        if let holderSymbol = normalizedSymbol(holder.symbol),
           let entitySymbol = normalizedSymbol(entity.symbol),
           holderSymbol == entitySymbol {
            return true
        }

        guard normalizedName(holder.name) == normalizedName(entity.name) else {
            return false
        }

        if let holderCountry = holder.country?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
           !holderCountry.isEmpty,
           let entityCountry = entity.country?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
           !entityCountry.isEmpty {
            return entityCountry == holderCountry
        }

        return true
    }

    private func normalizedName(_ name: String?) -> String {
        name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    private func normalizedSymbol(_ symbol: String?) -> String? {
        guard let symbol = symbol?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              !symbol.isEmpty else {
            return nil
        }

        return symbol
    }

    private func cacheKey(entity: TreasuryEntity, coinId: String) -> String {
        "\(entity.rawValue)-\(coinId)"
    }
}
