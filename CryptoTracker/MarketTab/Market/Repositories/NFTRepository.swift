//
//  NFTRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-29.
//

import Foundation
import Combine

protocol NFTRepository: Actor {
    var cachedToplist: [String: CachedData<[NFTToplist]>] { get }
    var cachedPlatforms: CachedData<[NFTPlatform]>? { get }
    var toplistSubject: PassthroughSubject<Result<[NFTToplist], Error>, Error> { get }
    
    func ensureCacheLoaded() async
    func getToplist(platform: NFTPlatform, sortOption: SortOption) async -> [NFTToplist]?
    func getNFTPlatforms() async -> [NFTPlatform]?
}

final actor NFTRepositoryImp: NFTRepository {
    static let shared = NFTRepositoryImp()
    
    private let networkManager: NetworkManager
    
    var cachedToplist: [String: CachedData<[NFTToplist]>]
    var cachedPlatforms: CachedData<[NFTPlatform]>?
    
    let toplistSubject = PassthroughSubject<Result<[NFTToplist], Error>, Error>()
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedToplist = [:]
        self.cachedPlatforms = nil
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        if let platforms: [NFTPlatform] = await networkManager.getCached(endpoint: .nftPlatforms) {
            cachedPlatforms = CachedData(data: platforms, date: Date())
            for platform in [NFTPlatform(id: "all", name: "All Chains", image: nil)] + platforms {
                for sortOption in SortOption.nftOptions {
                    if let toplist: [NFTToplist] = await networkManager.getCached(
                        endpoint: .nftToplist(platform: platform, sortOption: sortOption)
                    ) {
                        cachedToplist["\(sortOption.nftApiValue)-\(platform.id ?? "")"] = CachedData(data: toplist, date: Date())
                    }
                }
            }
        }
    }
    
    func getToplist(platform: NFTPlatform, sortOption: SortOption) async -> [NFTToplist]? {
        await ensureCacheLoaded()
        let nftToplist: [NFTToplist]? = await networkManager.get(
            endpoint: .nftToplist(platform: platform, sortOption: sortOption)
        )
        
        if let nftToplist {
            cachedToplist["\(sortOption.nftApiValue)-\(platform.id ?? "")"] = CachedData(data: nftToplist, date: Date())
        }
        
        return nftToplist
    }
    
    func getNFTPlatforms() async -> [NFTPlatform]? {
        await ensureCacheLoaded()
        let nftPlatforms: [NFTPlatform]? = await networkManager.get(endpoint: .nftPlatforms)
        
        if let nftPlatforms {
            cachedPlatforms = CachedData(data: nftPlatforms, date: Date())
        }
        
        return nftPlatforms
    }
}
