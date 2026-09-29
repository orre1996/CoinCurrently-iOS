//
//  AuthenticationError.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-10-02.
//

import SwiftUI

struct AuthenticationError: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var isScrollable = false
    
    var body: some View {
        
        GeometryReader { reader in
            
            ZStack {
                
                Color.overlayBackground
                    .opacity(0.7)
                    .ignoresSafeArea()
                    .highPriorityGesture(DragGesture())
                
                VStack(spacing: 0) {
                    
                    AdaptiveScroll(isScrollable: isScrollable) {
                        
                        VStack(spacing: 0) {
                            
                            Text(Localization.string("Something went wrong."))
                                .foregroundColor(.onSurface)
                                .font(.poppinsSemibold(16))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 16)
                            
                            Text(Localization.string("Is Face ID disabled in your settings?"))
                                .foregroundColor(.onSurface)
                                .font(.poppinsRegular(14))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                        }
                    }
                    
                    Button(Localization.string("Go to settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 100)
                    .foregroundColor(.primary)
                    .font(.poppinsRegular(16))
                    .cornerRadius(8)
                    .padding(.top, 16)
                    
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                .background(Color.surfaceContainerLow)
                .cornerRadius(8)
                .multilineTextAlignment(.center)
                .foregroundColor(.onSurface)
                .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, alignment: .center)
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .readSize {
                    isScrollable = $0.height > reader.size.height
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
