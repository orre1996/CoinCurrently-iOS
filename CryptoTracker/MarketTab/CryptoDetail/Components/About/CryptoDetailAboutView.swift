//
//  CryptoDetailAboutView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-12.
//

import SwiftUI

struct CryptoDetailAboutView: View {
    let description: Description?
    let links: Links?
    
    @Binding var newsUrl: String?
    
    private var sections: [DetailAboutSection] {
        var result: [DetailAboutSection] = []
        
        if let description = description?.en, !description.isEmpty {
            result.append(DetailAboutSection(
                title: "Description",
                contents: [description],
                icons: []
            ))
        }
        
        if let links {
            if !links.officialWebsites.isEmpty {
                result.append(DetailAboutSection(
                    title: "Official Websites",
                    contents: links.officialWebsites,
                    icons: Array(repeating: .website, count: links.officialWebsites.count)
                ))
            }
            
            if let whitepaper = links.whitepaper, !whitepaper.isEmpty {
                result.append(DetailAboutSection(
                    title: "Whitepaper",
                    contents: [whitepaper],
                    icons: [.whitepaper]
                ))
            }
            
            if !links.socialMediaUrls.isEmpty {
                result.append(DetailAboutSection(
                    title: "Communities",
                    contents: links.socialMediaUrls,
                    icons: links.socialMediaIcons
                ))
            }
            
            if !links.repositoryUrls.isEmpty {
                result.append(DetailAboutSection(
                    title: "Official Repositories",
                    contents: links.repositoryUrls,
                    icons: Array(repeating: .repository, count: links.repositoryUrls.count)
                ))
            }
            
            if let blockChainUrls = links.blockchain_site?.map({ $0 ?? "" }).filter({ !$0.isEmpty }), !blockChainUrls.isEmpty {
                result.append(DetailAboutSection(
                    title: "Related Websites",
                    contents: blockChainUrls,
                    icons: Array(repeating: .website, count: blockChainUrls.count)
                ))
            }
        }
        
        return result
    }
    
    private var isLoading: Bool {
        links == nil
    }
    
    var body: some View {
        DetailAboutView(
            sections: sections,
            isLoading: isLoading,
            emptyStateMessage: "When information about this coin appears, it'll show up here.",
            fromScreen: .cryptoDetail,
            newsUrl: $newsUrl
        )
    }
}
