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
            title: "Languages",
            icon: .languages,
            bulletPoints: [
                "The app can be translated to 36 languages"
            ]
        ),
        WhatsNewSection(
            title: "Referrals",
            icon: .referral,
            bulletPoints: [
                "Invite your friends & family and get rewarded"
            ]
        ),
        WhatsNewSection(
            title: "Widgets",
            icon: .widget,
            bulletPoints: [
                "Widgets have a new, fresh look",
                "Everything about widgets has moved to the Home Screen, where they are now modified"
            ]
        ),
        WhatsNewSection(
            title: "Heatmap",
            icon: .heatmap,
            bulletPoints: [
                "See the market as a color-coded heatmap",
                "Browse favorites, your portfolio, or the toplist"
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

