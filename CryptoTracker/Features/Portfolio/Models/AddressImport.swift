//
//  AddressImport.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-05-23.
//

import Foundation

struct AddressImport: Codable, PortfolioEvent {
    var id: UUID = UUID()
    var date: Date = Date()
    var walletName: String?
    var coinId: String?
    let address: String
    let balance: String
    let tokenInfos: [TokenInfo]?
    let blockChain: Chain
    
    private enum CodingKeys: String, CodingKey {
        case id, date, walletName, coinId, address, balance, tokenInfos, blockChain
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        walletName: String? = nil,
        coinId: String? = nil,
        address: String,
        balance: String,
        tokenInfos: [TokenInfo]? = nil,
        blockChain: Chain
    ) {
        self.id = id
        self.date = date
        self.walletName = walletName
        self.coinId = coinId
        self.address = address
        self.balance = balance
        self.tokenInfos = tokenInfos
        self.blockChain = blockChain
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.walletName = try container.decodeIfPresent(String.self, forKey: .walletName)
        self.coinId = try container.decodeIfPresent(String.self, forKey: .coinId)
        self.address = try container.decode(String.self, forKey: .address)
        self.balance = try container.decode(String.self, forKey: .balance)
        self.tokenInfos = try? container.decode([TokenInfo].self, forKey: .tokenInfos)
        self.blockChain = try container.decodeIfPresent(Chain.self, forKey: .blockChain) ?? .btc
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(walletName, forKey: .walletName)
        try container.encode(coinId, forKey: .coinId)
        try container.encode(address, forKey: .address)
        try container.encode(balance, forKey: .balance)
        try container.encodeIfPresent(tokenInfos, forKey: .tokenInfos)
        try container.encode(blockChain.rawValue, forKey: .blockChain)
    }
}

extension AddressImport {
    var allIds: [String] {
        return [coinId ?? ""] + (tokenInfos?.compactMap { $0.tokenId } ?? [])
    }
    
    var importTransaction: PortfolioTransaction? {
        guard let balance = Double(balance) else {
            return nil
        }
        
        return PortfolioTransaction(
            id: id,
            date: date,
            amount: balance,
            pricePerCoin: nil,
            fee: 0,
            note: "",
            transactionType: .importAddress,
            currency: (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
        )
    }
    
    func copy(
        with name: String?,
        blockChain: Chain,
        date: Date?,
        coinId: String
    ) -> AddressImport {
        return AddressImport(
            id: id,
            date: date ?? Date(),
            walletName: name,
            coinId: coinId,
            address: address,
            balance: balance,
            tokenInfos: tokenInfos,
            blockChain: blockChain
        )
    }
    
    func copy(with date: Date) -> AddressImport {
        return AddressImport(
            id: id,
            date: date,
            walletName: walletName,
            coinId: coinId,
            address: address,
            balance: balance,
            tokenInfos: tokenInfos,
            blockChain: blockChain
        )
    }
    
    var toTokenInfo: TokenInfo? {
        return TokenInfo(
            accountHash: "",
            balance: balance,
            tokenHash: "",
            tokenSymbol: "",
            tokenId: ""
        )
    }
    
    func totalValue(mainId: String?, prices: [Cryptocurrency]?) -> Double? {
        guard
            let mainId,
            let prices,
            let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? .´default´
        else {
            return nil
        }

        var total: Double = 0
        
        if
            let priceEntry = prices.first(where: { $0.id == mainId })?.prices,
            let tokenPrice = priceEntry[currency.code.lowercased()],
            let balance = Double(balance)
        {
            total += balance * tokenPrice
        }

        for token in tokenInfos ?? [] {
            guard
                let priceEntry = prices.first(where: { $0.id == token.tokenId })?.prices,
                let tokenPrice = priceEntry[currency.code.lowercased()],
                let tokenBalance = Double(token.balance)
            else {
                continue
            }

            total += tokenBalance * tokenPrice
        }

        return total
    }
    
    var accessibilityAddressDescription: String {
        let formattedAddress = address.uppercased()
        let firstFour = String(formattedAddress.prefix(4))
        let lastFour = String(formattedAddress.suffix(4))
        return "first 4 in address \(firstFour), last 4 in address \(lastFour)"
    }
}


struct TokenInfo: Codable, Equatable, Hashable {
    let accountHash: String
    let balance: String
    let tokenHash: String
    let tokenSymbol: String
    let tokenId: String?
}

extension TokenInfo {
    func toAddressImport(with date: Date) -> AddressImport{
        return AddressImport(
            date: date,
            coinId: tokenId,
            address: tokenHash,
            balance: balance,
            tokenInfos: nil,
            blockChain: Chain.token
        )
    }
}
