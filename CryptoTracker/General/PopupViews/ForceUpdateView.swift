//
//  forceUpdateView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-10-09.
//

import SwiftUI

struct ForceUpdateView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var isScrollable = false
    
    @AccessibilityFocusState private var focusHeader
    
    @State private var bodyHeight: CGFloat = 0
    @State private var buttonHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.overlayBackground
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        
                        bodyText
                    }
                    .readSize {
                        bodyHeight = $0.height
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                
                PrimaryButton(
                    text: "Go to App Store",
                    action: {
                        if let url = URL(string: "itms-apps://apple.com/app/id1543974454") {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: "https://apps.apple.com/se/app/coincurrently/id1543974454#?platform=iphone"){
                            UIApplication.shared.open(url)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .readSize {
                    buttonHeight = $0.height
                }
            }
            .frame(maxHeight: bodyHeight + buttonHeight + 24)
            .cardBackground(
                backgroundColor: Color.surfaceContainerLow
            )
            .padding(24)
        }
    }
    
    private var header: some View {
        Text("There is a new required version")
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(18))
    }
    
    private var bodyText: some View {
        Text("Head over to App Store and download the latest version to continue using the app.")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiRegular(16))
    }
}
