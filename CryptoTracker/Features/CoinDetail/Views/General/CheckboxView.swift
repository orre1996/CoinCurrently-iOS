//
//  CheckboxView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-08.
//

import SwiftUI

struct CheckboxView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    var trailingText: String? = nil
    @Binding var isChecked: Bool
    var size: CGFloat = 18
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }, label: {
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isChecked ? Color.clear : Color.outline, lineWidth: 4)
                    
                    if isChecked {
                        Image.check
                            .resizable()
                            .foregroundStyle(Color.surface)
                            .padding(2)
                            .frame(width: size * min(scale, 1.5), height: size * min(scale, 1.5))
                    }
                }
                .frame(width: size * min(scale, 1.5), height: size * min(scale, 1.5))
                .background(isChecked ? Color.primary : Color.clear)
                .cornerRadius(2)
                .padding(16)
                
                if let trailingText {
                    Text(trailingText)
                        .foregroundStyle(Color.onSurfaceDim)
                        .font(.satoshiMedium(14))
                        .multilineTextAlignment(.leading)
                }
            }
        })
        .accessibilityElement(children: .combine)
        .accessibilityValue(isChecked ? "On" : "Off")
    }
}
