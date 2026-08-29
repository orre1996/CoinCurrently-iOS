//
//  WidgetListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import SwiftUI

struct WidgetListView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let currency: Toplist
    let deleteAction: () -> Void
    let selectAction: () -> Void
    let dragProvider: () -> NSItemProvider
    
    init(
        currency: Toplist,
        deleteAction: @escaping () -> Void,
        selectAction: @escaping () -> Void = {},
        dragProvider: @escaping () -> NSItemProvider = { NSItemProvider() }
    ) {
        self.currency = currency
        self.deleteAction = deleteAction
        self.selectAction = selectAction
        self.dragProvider = dragProvider
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.001)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(currency.name ?? "")
                .accessibilitySortPriority(1)
                .accessibilityHint("Swipe down to remove.")
                .accessibilityAction(named: "Remove") {
                    deleteAction()
                }
            
            HStack(spacing: 16) {
                Button(action: deleteAction) {
                    Image.remove
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .padding(12)
                }
                .accessibilityHidden(true)
                
                ShimmeringImage(
                    imageUrl: currency.image,
                    downloading: false,
                    size: 32 * min(scale, 1.5)
                )
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(currency.symbol?.uppercased() ?? "0000")
                        .font(.satoshiBold(16))
                        .foregroundStyle(Color.onSurface)
                        .accessibilityHidden(true)
                    
                    Text(currency.name ?? "0000")
                        .font(.satoshiBold(12))
                        .foregroundStyle(Color.onSurfaceDim)
                        .accessibilityHidden(true)
                }
                
                Spacer(minLength: 0)
                
                Button(action: selectAction) {
                    Image.list
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .padding(12)
                }
                .accessibilityLabel("Select")
                .accessibilitySortPriority(0)
                .onDrag(dragProvider)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .padding(.vertical, 16)
    }
}
