//
//  CustomProgressBarView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/23/25.
//

import SwiftUI

struct CustomProgressBarView: View {
    let progress: Double?
    var offset: Double = 0
    let foregroundColor: Color
    var backgroundColor: Color = Color.surfaceContainerLowest
    var height: CGFloat = 8
    var capsuleShaped: Bool = true
    var downloading: Bool = false
    
    @State private var progressBarWidth: CGFloat = 1
    
    var body: some View {
        backgroundColor
            .frame(height: height)
            .readSize {
                progressBarWidth = $0.width
            }
            .overlay(alignment: .leading) {
                (downloading ? Color.shimmeringBackground : foregroundColor)
                    .frame(maxWidth: downloading ? progressBarWidth : min(progressBarWidth, (progress ?? 0) * progressBarWidth))
                    .if(capsuleShaped) { view in
                        view.clipShape(Capsule())
                    }
                    .padding(.leading, offset * progressBarWidth)
            }
            .clipShape(Capsule())
        
    }
}
