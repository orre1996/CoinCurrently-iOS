//
//  SingleSelectView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/24/26.
//

import SwiftUI

enum ImageCase {
    case nothing
    case image(String?)
    case fixed(Image)
    case text(String)
}

struct SingleSelectView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let title: String
    var accessibilityTitle: String? = nil
    let subtitle: String?
    let imageCase: ImageCase
    let isSelected: Bool
    var canNavigate = false
    let didSelectOption: () -> Void
    
    private var accessibilityLabelText: String {
        if let accessibilityTitle {
            return accessibilityTitle
        }
        
        if let subtitle, !subtitle.isEmpty {
            return "\(title). \(subtitle)"
        }
        
        return title
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image.checkCircle
                .resizable()
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .foregroundStyle(Color.primary)
                .opacity(isSelected  ? 1 : 0)
                .padding(12)
                .accessibilityHidden(true)
            
            if case let .image(imageUrl) = imageCase {
                ShimmeringImage(
                    imageUrl: imageUrl,
                    downloading: imageUrl == nil,
                    size: 32 * min(scale, 1.5)
                )
                .padding(.trailing, 4)
                .accessibilityHidden(true)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.satoshiBold(12))
                        .foregroundStyle(Color.onSurfaceDimmer)
                }
            }
            .padding(.trailing, canNavigate ? 0 : 12)
            
            if canNavigate {
                Spacer(minLength: 0)
                
                Image.chevronRight
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(12)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.surfaceContainer : Color.clear)
        .cornerRadius(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            didSelectOption()
        }
    }
}
