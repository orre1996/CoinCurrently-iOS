//
//  DragHandle.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2/2/26.
//

import SwiftUI

struct DragHandle: View {
    @Environment(\.presentationMode) private var presentationMode
    
    let title: String
    var accessibilityTitle: String? = nil
    var leadingIcon: Image? = nil
    var bottomPadding: CGFloat = 24
    
    @ScaledMetric private var scale: CGFloat = 1
    @AccessibilityFocusState private var focusHeader
    
    private var resolvedAccessibilityTitle: String {
        accessibilityTitle ?? title
    }

    var body: some View {
        VStack(spacing: 0) {
            DragHandler()
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 0,
                        bottom: 12,
                        trailing: 0
                    )
                )
            
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    if let leadingIcon {
                        leadingIcon
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24 * min(1.5, scale), height: 24 * min(1.5, scale))
                            .foregroundStyle(Color.onSurfaceDimmer)
                    }
                    
                    Text(title)
                        .font(.satoshiBold(22))
                        .foregroundStyle(Color.onSurfaceDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(leadingIcon == nil ? resolvedAccessibilityTitle : "\(resolvedAccessibilityTitle). info")
                .accessibilityFocused($focusHeader)

                CloseButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: bottomPadding,
                    trailing: 16
                )
            )
        }
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
}
