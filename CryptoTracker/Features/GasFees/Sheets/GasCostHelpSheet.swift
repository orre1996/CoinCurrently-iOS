//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI

struct GasCostHelpSheet: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var appLanguage = AppLanguagePreference.stored
    
    @ScaledMetric private var scale: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: Localization.string("Estimated Cost"),
                leadingIcon: .info
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    overviewView
                    
                    calculationView
                    
                    meaningView
                }
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            .foregroundColor(.onSurface)
            .font(.satoshiBold(22))
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var overviewView: some View {
        Text(Localization.string("These are approximate fees for common Ethereum transactions based on the current network gas price. Actual costs may vary depending on network activity and transaction complexity."))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiRegular(16))
            .lineSpacing(4)
    }
    
    private var calculationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.string("How estimates are calculated"))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text(Localization.string("Uses the latest ETH gas price (Gwei)."))
                    .accessibilityLabel(Localization.string("Uses the latest Ethereum gas price, Gwei."))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text(Localization.string("Applies typical gas usage for each action."))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text(Localization.string("Converts result to USD using current ETH price."))
                    .accessibilityLabel(Localization.string("Converts result to USD using current Ethereum price."))
            }
        }
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiRegular(16))
        .lineSpacing(4)
    }
    
    private var meaningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.string("What each action means"))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)

                Text(Localization.string("Swap: "))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text(Localization.string("Swapping tokens on a decentralized exchange."))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text(Localization.string("NFT Sale: "))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text(Localization.string("Listing or selling an NFT."))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)

                Text(Localization.string("Bridging: "))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text(Localization.string("Moving assets between networks."))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text(Localization.string("Borrowing: "))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text(Localization.string("Opening a lending position on a DeFi protocol."))
            }
        }
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiRegular(16))
        .lineSpacing(4)
    }
}

