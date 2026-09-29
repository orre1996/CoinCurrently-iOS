//
//  HeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-09.
//

import SwiftUI

struct HeaderViewNavigated: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Binding var presentationMode: PresentationMode
    
    let title: String
    var downloading = false
    var downloadingData = false
    var smallSpace: Bool = true
    var accessibilityTitle: String? = nil
    var tabBarItems: [AnyView] = []
    
    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Button(action: {
                    presentationMode.dismiss()
                }) {
                    Image.chevronLeft
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.onSurface)
                }
                .frame(width: 40, height: 40)
                .accessibilitySortPriority(5)
                .accessibilityLabel(Localization.string("Navigate back"))
                
                Spacer()
                
                ForEach(0..<tabBarItems.count, id: \.self) { index in
                    if let item = tabBarItems[safely: index] {
                        item
                            .accessibilitySortPriority(Double(tabBarItems.count - index))
                    }
                }
            }
            
            ShimmeringText(
                text: title,
                isDownloading: downloading
            )
            .font(verticalSizeClass == .compact ? .satoshiBold(26) : .satoshiBold(32))
            .foregroundStyle(Color.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, smallSpace ? 56 : 96)
                .accessibilitySortPriority(4)
                .accessibilityLabel(accessibilityTitle ?? title)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
        .frame(height: verticalSizeClass == .compact ? 40 : 52)
        .foregroundColor(.onSurface)
        .accessibilityElement(children: .contain)
    }
}
