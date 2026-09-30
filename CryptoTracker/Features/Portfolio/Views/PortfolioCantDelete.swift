//
//  PortfolioCantDelete.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-02-04.
//

import SwiftUI

struct PortfolioCantDelete: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let close: () -> Void
    
    var body: some View {
        ZStack {
            Color.overlayBackground.opacity(0.7)
                .ignoresSafeArea()
                .highPriorityGesture(DragGesture())
                .onTapGesture {
                    close()
                }
            
            VStack(spacing: 0) {
                headerView

                actionButton
            }
            .padding(16)
            .background(Color.onSurfaceDim)
            .cornerRadius(8)
            .multilineTextAlignment(.center)
            .foregroundColor(.onSurface)
            .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, alignment: .center)
            .padding(.horizontal, 16)
        }
    }
    
    private var headerView: some View {
        Text(Localization.string("You can't delete a transaction that would result in a negative amount."))
            .foregroundColor(.onSurface)
            .font(.poppinsRegular(14))
            .multilineTextAlignment(.center)
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var actionButton: some View {
        PrimaryButton(text: Localization.string("OK"), action: {
            close()
        })
        .padding(.top, 16)
    }
}
