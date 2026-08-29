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
    
    @ScaledMetric private var scale: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: "Estimated Cost",
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
        .ignoresSafeArea(edges: .bottom)
    }

    private var overviewView: some View {
        Text("These are approximate fees for common Ethereum transactions based on the current network gas price. Actual costs may vary depending on network activity and transaction complexity.")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiRegular(16))
            .lineSpacing(4)
    }
    
    private var calculationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How estimates are calculated")
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text("Uses the latest ETH gas price (Gwei).")
                    .accessibilityLabel("Uses the latest Ethereum gas price, Gwei.")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text("Applies typical gas usage for each action.")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text("Converts result to USD using current ETH price.")
                    .accessibilityLabel("Converts result to USD using current Ethereum price.")
            }
        }
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiRegular(16))
        .lineSpacing(4)
    }
    
    private var meaningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What each action means")
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)

                Text("Swap: ")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text("Swapping tokens on a decentralized exchange.")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text("NFT Sale: ")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text("Listing or selling an NFT.")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)

                Text("Bridging: ")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text("Moving assets between networks.")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("·")
                    .accessibilityHidden(true)
                
                Text("Borrowing: ")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
                
                +
                
                Text("Opening a lending position on a DeFi protocol.")
            }
        }
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiRegular(16))
        .lineSpacing(4)
    }
}

