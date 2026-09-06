//
//  NFTDetailRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-08.
//

import Foundation
import UIKit

protocol NFTDetailRepository: Actor {
    var cachedNFTDetails: [String: CachedData<NFTDetail>] { get }
    var cachedNFTPrices: [String: CachedData<NFTPriceVolumeModel>] { get }
    var cachedNFTTickers: [String: CachedData<[NFTTicker]>] { get }
    
    func ensureCacheLoaded() async
    func loadCachedDataForNFT(id: String, days: String) async
    func getNFTDetail(id: String?) async -> NFTDetail?
    func getNFTPrices(id: String?, days: String) async -> NFTPriceVolumeModel?
    func getNFTTickers(id: String?) async -> [NFTTicker]?
    func getImage(url: String?) async -> UIImage?
}

final actor NFTDetailRepositoryImp: NFTDetailRepository {
    static let shared = NFTDetailRepositoryImp()

    private let networkManager: NetworkManager
    
    private(set) var cachedNFTDetails: [String: CachedData<NFTDetail>]
    private(set) var cachedNFTPrices: [String: CachedData<NFTPriceVolumeModel>]
    private(set) var cachedNFTTickers: [String: CachedData<[NFTTicker]>]

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedNFTPrices = [:]
        self.cachedNFTDetails = [:]
        self.cachedNFTTickers = [:]
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
    }

    func loadCachedDataForNFT(id: String, days: String) async {
        await ensureCacheLoaded()

        if let nftDetail: NFTDetail = await networkManager.getCached(endpoint: .nftDetail(id: id)) {
            cachedNFTDetails[id] = CachedData(data: nftDetail, date: Date())
        }

        if let nftPriceModel: NFTPriceVolumeModel = await networkManager.getCached(endpoint: .nftPriceVolume(id: id, days: days)) {
            cachedNFTPrices["\(id)-\(days)"] = CachedData(data: nftPriceModel, date: Date())
        }

        if let nftTicker: NFTTickerResponse = await networkManager.getCached(endpoint: .nftTickers(id: id)) {
            cachedNFTTickers[id] = CachedData(data: nftTicker.tickers, date: Date())
        }
    }

    func getNFTDetail(id: String?) async -> NFTDetail? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        let nftDetail: NFTDetail? = await networkManager.get(endpoint: .nftDetail(id: id))
        
        if let nftDetail {
            cachedNFTDetails[id] = CachedData(data: nftDetail, date: Date())
        }
        
        return nftDetail
    }
    
    func getNFTPrices(id: String?, days: String) async -> NFTPriceVolumeModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }
        
        let nftPriceModel: NFTPriceVolumeModel? = await networkManager.get(endpoint: .nftPriceVolume(id: id, days: days))

        if let nftPriceModel {
            cachedNFTPrices["\(id)-\(days)"] = CachedData(data: nftPriceModel, date: Date())
        }
        
        return nftPriceModel
    }
    
    func getNFTTickers(id: String?) async -> [NFTTicker]? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        let nftTicker: NFTTickerResponse? = await networkManager.get(endpoint: .nftTickers(id: id))
        
        if let nftTicker {
            cachedNFTTickers[id] = CachedData(data: nftTicker.tickers, date: Date())
        }
        
        return nftTicker?.tickers
    }
    
    func getImage(url: String?) async -> UIImage? {
        guard let url, let imageData: Data = await networkManager.get(endpoint: .image(url: url)) else { return nil }
        
        return UIImage(data: imageData)
    }
}
