//
//  EstimateGasFeeCost.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/28/25.
//

import SwiftUI

struct EstimateGasFeeCost: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let swapCost: String?
    let accessibleSwapCost: String?
    let nftCost: String?
    let accessibleNftCost: String?
    let bridgingCost: String?
    let accessibleBridgingCost: String?
    let borrowingCost: String?
    let accessibleBorrowingCost: String?
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(spacing: 16) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                gasFeeCostView(
                    title: "For Swap",
                    value: swapCost,
                    accessibleValue: accessibleSwapCost
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                gasFeeCostView(
                    title: "For NFT Sale",
                    value: nftCost,
                    accessibleValue: accessibleNftCost
                )
            }
            
            Separator()
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
                gasFeeCostView(
                    title: "For Bridging",
                    value: bridgingCost,
                    accessibleValue: accessibleBridgingCost
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                gasFeeCostView(
                    title: "For Borrowing",
                    value: borrowingCost,
                    accessibleValue: accessibleBorrowingCost
                )
            }
        }
        .cardBackground()
    }
    
    private func gasFeeCostView(
        title: String,
        value: String?,
        accessibleValue: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityLabel("Estimated cost \(title)")
            
            NewShimmeringText(
                text: value ?? "000000",
                isDownloading: value == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            .accessibilityLabel(accessibleValue ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
