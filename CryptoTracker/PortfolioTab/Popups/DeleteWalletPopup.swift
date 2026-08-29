//
//  DeleteWalletPopup.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/1/26.
//

import SwiftUI

struct DeleteWalletPopup: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    var walletName: String
    var close: (Bool) -> Void
    
    var body: some View {
        ZStack {
            Color.overlayBackground
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                header
                
                bodyText
                
                actionButtons
            }
            .cardBackground(
                backgroundColor: Color.surfaceContainerLow,
                cornerRadius: 16
            )
            .padding(24)
        }
    }
    
    private var header: some View {
        Text("Remove Wallet")
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(18))
    }
    
    private var bodyText: some View {
        Text("Remove “\(walletName)” from your portfolio?\nYou can re-import it at any time.")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiRegular(16))
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 12) {
            SecondaryButton(
                text: "Cancel",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    close(false)
                }
            )
            .frame(maxWidth: 400)
            
            PrimaryButton(
                text: "Remove",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    close(true)
                }
            )
            .frame(maxWidth: 400)
        }
    }
}
