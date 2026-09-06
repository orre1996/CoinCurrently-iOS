//
//  SelectCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/13/25.
//

import SwiftUI

struct SelectCoinView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let toplist: Toplist?
    var isSector: Bool = false
    let isSelectable: Bool
    let isSelected: Bool
    let itemType: String
    let index: Int
    let totalCount: Int
    let onClick: () -> Void
    
    private var accessibilityLabelText: String {
        let name = toplist?.name ?? toplist?.symbol ?? ""
        
        if name.isEmpty {
            return "\(itemType) \(index + 1) of \(totalCount)"
        }
        
        return "\(itemType) \(index + 1) of \(totalCount), \(name)"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if isSelectable {
                Image.checkCircle
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .padding(8)
                    .foregroundStyle(Color.primary)
                    .opacity(isSelected ? 1 : 0)
            }
            
            if isSector {
                Image.sector
                    .resizable()
                    .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .padding(6)
                    .background(Color.surfaceContainer)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            } else if toplist == nil || toplist?.image != nil {
                ShimmeringImage(
                    imageUrl: toplist?.image,
                    downloading: toplist?.image == nil,
                    size: 28 * min(scale, 1.5)
                )
                .padding(.trailing, 8)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                if toplist == nil || toplist?.symbol != nil {
                    ShimmeringText(
                        text: toplist?.symbol?.uppercased() ?? "0000",
                        isDownloading: toplist?.symbol == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                }

                if toplist == nil || toplist?.name != nil {
                    ShimmeringText(
                        text: toplist?.name ?? "000000",
                        isDownloading: toplist?.name == nil
                    )
                    .foregroundStyle(toplist?.symbol == nil ? Color.onSurface : Color.onSurfaceDim)
                    .font(.satoshiBold(toplist?.symbol == nil ? 16 : 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(
            EdgeInsets(
                top: isSelectable ? 12 : 18,
                leading: isSelectable ? 4 : 24,
                bottom: isSelectable ? 12 : 18,
                trailing: isSelectable ? 12 : 24
            )
        )
        .background(isSelected ? Color.surfaceContainer : Color.clear)
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits([isSelected ? .isSelected : [], .isButton])
        .accessibilityLabel(accessibilityLabelText)
        .onTapGesture {
            onClick()
        }
    }
}
