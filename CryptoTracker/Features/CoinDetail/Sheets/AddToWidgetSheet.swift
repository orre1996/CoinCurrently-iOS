//
//  AddToWidgetSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/25/25.
//

import SwiftUI

struct AddToWidgetSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State var headerHeight: CGFloat = 0
    @State var contentHeight: CGFloat = 0
    @State var buttonsHeight: CGFloat = 0
    
    let widgetsCount: Int
    let deepLinkToWidget: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Add to Widget")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    bodyView
                        .fixedSize(horizontal: false, vertical: true)
                }
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
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0) {
                Separator()
                    .padding(.horizontal, 16)
                
                progressView
                    .padding(
                        EdgeInsets(
                            top: 24,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
                
                Separator()
                    .padding(.horizontal, 16)
                
                actionButtons
            }
            .readSize {
                buttonsHeight = $0.height
            }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("This coin will be added to your CoinCurrently widget. You can add up to 8 coins.")
            
            Text("If you haven’t added the widget yet, long-press your home screen, tap +, and select CoinCurrently.")
            
            Text("Manage the coins displayed on your widget anytime in ")
            
            +
            
            Text("Settings > My Widgets.")
                .font(.satoshiBold(16))
            
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color.onSurfaceDim)
        .font(.satoshiMedium(16))
    }
    
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Coins Added")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDim)
                
                Spacer(minLength: 0)
                
                Text("\(widgetsCount)")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurface)
                
                +
                
                Text(" of 8")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDimmer)
            }
            
            CustomProgressBarView(
                progress: (Double(widgetsCount) / 8.0),
                foregroundColor: .primary
            )
            
            Text("Coin added to your widgets.")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
    
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 12) {
            SecondaryButton(
                text: "Close",
                minWidth: 140,
                opaqueBackground: true,
                action: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            PrimaryButton(
                text: "Manage Widgets",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    presentationMode.wrappedValue.dismiss()
                    
                    asyncMain(delay: 0.4) {
                        deepLinkToWidget()
                    }
                }
            )
            .layoutPriority(1)
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 16,
                trailing: 16
            )
        )
    }
}
