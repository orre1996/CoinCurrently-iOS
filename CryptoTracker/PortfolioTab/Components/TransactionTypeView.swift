//
//  TransactionTypeView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/19/25.
//

import SwiftUI

struct TransactionTypeView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let title: String
    let subtitle: String
    let image: Image
    var isMultiSelectEnabled = false
    var isSelected: Bool
    let viewTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            image
                .resizable()
                .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                .padding(8)
                .background(Color.surfaceContainer)
                .foregroundStyle(Color.onSurfaceDim)
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
                
                Text(subtitle)
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDimmer)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isMultiSelectEnabled {
                CheckboxView(isChecked: .constant(isSelected))
                    .disabled(true)
                    .accessibilityHidden(true)
            } else {
                Image.chevronRight
                    .resizable()
                    .foregroundStyle(Color.onSurfaceDim)
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                    .padding(8)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            viewTapped()
        }
    }
}
