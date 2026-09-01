//
//  SiriNavigationManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-06-01.
//

import Foundation

#if IS_APP
@MainActor
enum SiriNavigationManager {
    private static weak var navigationViewModel: NavigationViewModel?
    private static var pendingDestination: String?
    
    static func register(_ viewModel: NavigationViewModel) {
        navigationViewModel = viewModel
    }
    
    static func navigate(to destination: String) {
        guard let viewModel = navigationViewModel, viewModel.allStartingDataDownloaded else {
            pendingDestination = destination
            return
        }
        
        viewModel.deepLink(url: destination)
    }
    
    static func consumePending(with viewModel: NavigationViewModel) {
        guard let destination = pendingDestination else { return }
        pendingDestination = nil
        viewModel.deepLink(url: destination)
    }
}
#endif
