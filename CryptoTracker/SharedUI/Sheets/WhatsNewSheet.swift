//
//  FearGreedHelpSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-25.
//

import SwiftUI


struct WhatsNewSection: Hashable {
    let title: String
    let icon: Image
    let bulletPoints: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}

struct WhatsNewSheet: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    @ScaledMetric private var scale: CGFloat = 1
    @State private var appLanguage = AppLanguagePreference.stored
    
    private let sections: [WhatsNewSection] = [
        WhatsNewSection(
            title: "Free",
            icon: Image(systemName: "gift"),
            bulletPoints: [
                "The paywall has been removed",
                "CoinCurrently is completely free, and every feature is included",
                "There is no subscription to buy, renew, or restore"
            ]
        ),
        WhatsNewSection(
            title: "Open source",
            icon: .repository,
            bulletPoints: [
                "The project is now open source, so you can read the code and see what the app does with your data",
                "Want to contribute? The iOS and Android repositories are linked under Source code in Settings"
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: Localization.string("What's New")
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(sections, id: \.self) {
                        whatsNewSectionView(section: $0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            
            VStack(spacing: 0) {
                Separator()
                    .padding(.horizontal, 16)
                
                PrimaryButton(
                    text: Localization.string("Explore"),
                    fullWidth: true,
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
            }
            .readSize {
                buttonsHeight = $0.height
            }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .environment(\.locale, appLanguage.resolve().locale)
    }
    
    private func whatsNewSectionView(section: WhatsNewSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 4) {
                section.icon
                    .resizable()
                    .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                    .foregroundStyle(Color.primary)
                
                Text(Localization.string(section.title))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
            }
            
            ForEach(section.bulletPoints, id: \.self) { point in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("·")
                    
                    Text(Localization.string(point))
                }
                .font(.satoshiRegular(16))
                .foregroundStyle(Color.onSurfaceDim)
            }
        }
    }
}

