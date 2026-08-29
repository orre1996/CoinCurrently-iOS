//
//  NFTDetailAboutView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-12.
//

import SwiftUI

struct NFTDetailAboutView: View {
    let nftDetail: NFTDetail?
    
    @Binding var newsUrl: String?
    
    private var sections: [DetailAboutSection] {
        guard let nftDetail else { return [] }
        
        var result: [DetailAboutSection] = []
        
        if let description = nftDetail.description, !description.isEmpty {
            result.append(DetailAboutSection(
                title: "Description",
                contents: [description],
                icons: []
            ))
        }
        
        if !nftDetail.officialWebsites.isEmpty {
            result.append(DetailAboutSection(
                title: "Official Websites",
                contents: nftDetail.officialWebsites,
                icons: Array(repeating: .website, count: nftDetail.officialWebsites.count)
            ))
        }
        
        if !nftDetail.socialMediaUrls.isEmpty {
            result.append(DetailAboutSection(
                title: "Communities",
                contents: nftDetail.socialMediaUrls,
                icons: nftDetail.socialMediaIcons
            ))
        }
        
        if !nftDetail.explorerUrls.isEmpty {
            result.append(DetailAboutSection(
                title: "Explorers",
                contents: nftDetail.explorerUrls,
                icons: nftDetail.explorerIcons
            ))
        }
        
        return result
    }
    
    private var isLoading: Bool {
        nftDetail == nil
    }
    
    var body: some View {
        DetailAboutView(
            sections: sections,
            isLoading: isLoading,
            emptyStateMessage: "When information about this NFT collection appears, it'll show up here.",
            fromScreen: .nftDetail,
            newsUrl: $newsUrl
        )
    }
}
