//
//  BannedView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-08-27.
//

import SwiftUI

struct BannedView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var isScrollable = false
    
    var body: some View {
        
        GeometryReader { reader in
            
            ZStack {
                
                Color.overlayBackground.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    AdaptiveScroll(isScrollable: isScrollable) {
                        
                        VStack(spacing: 0) {
                            
                            Text("Device is banned")
                                .foregroundColor(.onSurface)
                                .font(.poppinsSemibold(16))
                                .padding(.horizontal, 16)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("This device has been flagged for inappropriate use. Contact support for more information.")
                                .foregroundColor(.onSurface)
                                .font(.poppinsRegular(14))
                                .padding(.horizontal, 16)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 16)
                .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, minHeight: 0, alignment: .center)
                .background(Color.surfaceContainerLow)
                .cornerRadius(8)
                .padding(16)
                .readSize {
                    isScrollable = $0.height >= reader.size.height - safeAreaInsets.resolvedTop - safeAreaInsets.resolvedBottom
                }
            }
        }
        .onAppDidBecomeActive {
            isScrollable = false
        }
        .onRotate { _ in
            asyncMain(delay: 0.2) {
                isScrollable = false
            }
        }
    }
}
