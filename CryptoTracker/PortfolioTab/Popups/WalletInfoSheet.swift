//
//  RenameWalletSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 11/2/25.
//

import SwiftUI

struct WalletInfoSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var showSnackbar = false
        
    @ScaledMetric private var scale: CGFloat = 1

    let wallet: AddressImport
    let coin: Toplist
    let syncedDate: Date?
    
    private var coinName: String {
        coin.name ?? coin.symbol ?? ""
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }

    @ViewBuilder
    private func statView(
        title: String,
        titleAccessible: String? = nil,
        value: String,
        valueAccessible: String? = nil
    ) -> some View {
        let accessibleTitle = titleAccessible ?? title
        
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(valueAccessible != nil)
            
            Text(value)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityHidden(valueAccessible != nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .if(valueAccessible != nil) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(accessibleTitle): \(valueAccessible ?? "")")
        }
        .if(valueAccessible == nil) { view in
            view.accessibilityElement(children: .combine)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                DragHandle(title: "Wallet Details")
                    .readSize {
                        headerHeight = $0.height
                    }
                
                Separator()
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 16) {
                        if isHorizontal {
                            statRow {
                                importedDateView
                            } right: {
                                lastSyncedDateView
                            }
                            
                            statRow {
                                networkView
                            } right: {
                                addressView
                            }
                        } else {
                            importedDateView
                            statSeparator
                            lastSyncedDateView
                            statSeparator
                            networkView
                            statSeparator
                            addressView
                        }
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
            }
            .ignoresSafeArea(edges: .bottom)

            SnackbarView(
                showSnackBar: $showSnackbar,
                message: .constant("Wallet address copied!"),
                buttonTitle: .constant(""),
                type: .success,
                isTabbarHidden: true,
                isOverlayShowing: false,
                isPresented: .constant(false),
                reportedHeight: .constant(0),
                overlayPressed: { },
                buttonAction: { }
            )
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
    }
    
    private var statSeparator: some View {
        Separator()
            .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func statRow<Left: View, Right: View>(
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            left()
            right()
        }
    }
    
    private var importedDateView: some View {
        statView(
            title: "Date Imported",
            value: wallet.date.formatted(date: .abbreviated, time: .omitted),
            valueAccessible: wallet.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        )
    }
    
    private var lastSyncedDateView: some View {
        let synced = syncedDate ?? Date()
        
        return statView(
            title: "Last Synced",
            value: synced.formatted(date: .abbreviated, time: .shortened),
            valueAccessible: synced.formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute())
        )
    }
    
    private var networkView: some View {
        statView(
            title: "Network",
            value: "\(coin.symbol?.uppercased() ?? "") Mainnet",
            valueAccessible: "\(coinName) Mainnet"
        )
    }
    
    private var addressView: some View {
        HStack(spacing: 4) {
            statView(
                title: "Wallet Address",
                value: "\(wallet.address.uppercased().prefix(5))...\(wallet.address.uppercased().suffix(5))",
                valueAccessible: wallet.accessibilityAddressDescription
            )

            Button(action: {
                AnalyticsManager.shared.log(
                    WalletAddressCopied(fromScreen: .walletDetails)
                )
                UIPasteboard.general.string = wallet.address
                showSnackbar.toggle()
            }, label: {
                (Image.copy)
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(12)
            })
            .accessibilityLabel("Copy wallet address")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
