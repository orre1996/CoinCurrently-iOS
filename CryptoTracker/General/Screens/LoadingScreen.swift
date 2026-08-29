//
//  LoadingScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-07.
//

import SwiftUI

struct LoadingScreen: View {
    var isAllDataDownloaded: Bool = false
    var showUnlockButton: Bool = false
    var showAuthenticationError: Bool = false
    var authenticateUser: () async -> Void = { }
    
    @State private var showActivityIndicator = false

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()

                Image.bannerTransparent
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 64)
                    .accessibilityHidden(true)
                
                ZStack {
                    if !isAllDataDownloaded && showActivityIndicator {
                        ActivityIndicator(color: .onSurface)
                            .opacity(!isAllDataDownloaded ? 1 : 0)
                            .accessibilityLabel("Loading")
                    }
                    
                    if showUnlockButton {
                        Button("Unlock app") {
                            Task {
                                await authenticateUser()
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                }
                .frame(minHeight: 36)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Privacy by Default")
                    .foregroundStyle(Color.onSurface)
                    .font(.system(size: 18, weight: .bold))
                    .padding(.bottom, 40)
            }
            .ignoresSafeArea()

            if showAuthenticationError {
                AuthenticationError()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            withAnimation {
                showActivityIndicator = true
            }
        }
    }
}
