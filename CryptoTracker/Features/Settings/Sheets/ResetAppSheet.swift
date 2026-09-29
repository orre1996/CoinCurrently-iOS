//
//  ResetAppView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-08-03.
//

import SwiftUI

struct ResetAppSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let close: () -> ()
    
    @State var authViewModel = AuthenticationViewModelImp()
    @State private var deleteInProgress = false
    @State private var isScrollable = false
        
    @AccessibilityFocusState private var focusHeader

    var body: some View {
        ZStack {
            Color.overlayBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                AdaptiveScroll(isScrollable: isScrollable) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(Localization.string("Reset App?"))
                            .foregroundColor(.onSurface)
                            .font(.satoshiBold(22))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($focusHeader)
                        
                        Text(Localization.string("This will delete all app settings and saved data on this device. This action cannot be undone."))
                            .foregroundColor(.onSurfaceDim)
                            .font(.satoshiRegular(16))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                AdaptiveStack(
                    isHorizontal: !category.isAccessibilityCategory || verticalSizeClass == .compact,
                    spacing: 12
                ) {
                    if !deleteInProgress {
                        SecondaryButton(
                            text: Localization.string("Cancel"),
                            fullWidth: true,
                            opaqueBackground: true,
                            action: {
                                close()
                            }
                        )
                        .accessibilityHidden(deleteInProgress)
                    }
                    
                    PrimaryButton(
                        text: Localization.string("Reset App"),
                        isLoading: deleteInProgress,
                        fullWidth: true,
                        opaqueBackground: true
                    ) {
                        Task {
                            guard await !authViewModel.authenticate(toggling: true) else { return }
                            
                            deleteInProgress = true
                            
                            await FirebaseManagerImp.shared.removeUser()
                            AnalyticsManager.shared.log(
                                ResetApp(fromScreen: .settings)
                            )
                            exit(0)
                        }
                    }
                }
                .animation(.default, value: deleteInProgress)
            }
            .padding(24)
            .background(Color.surfaceContainerLow)
            .cornerRadius(16)
            .frame(minWidth: 0, maxWidth: 364, alignment: .center)
            .padding(24)
        }
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
}
