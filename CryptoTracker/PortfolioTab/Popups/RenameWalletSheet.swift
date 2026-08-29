//
//  RenameWalletSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 11/2/25.
//

import SwiftUI

struct RenameWalletSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    @State private var walletName = ""
    
    let initialName: String
    let renameWallet: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Rename Wallet")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    TextInputField(
                        input: $walletName,
                        placeholder: "Enter name (Optional)",
                        accessibilityValue: walletName.isEmpty ? "Enter wallet name, optional" : walletName,
                        inputDidChange: { },
                        onCommit: { }
                    )
                    .padding(.vertical, 24)
                }
                .padding(.horizontal, 16)
                .readSize {
                    contentHeight = $0.height
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0) {
                Separator()
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 16,
                            bottom: 0,
                            trailing: 16
                        )
                    )

                actionButtons
            }
            .readSize {
                buttonsHeight = $0.height
            }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            walletName = initialName
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 8) {
            SecondaryButton(
                text: "Close",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    presentationMode.wrappedValue.dismiss()
                }
            )

            PrimaryButton(
                text: "Save",
                isEnabled: !walletName.isEmpty && initialName != walletName,
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    renameWallet(walletName)
                }
            )
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
}
