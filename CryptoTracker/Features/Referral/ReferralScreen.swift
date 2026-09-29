//
//  ReferralScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/30/26.
//

import SwiftUI
import UIKit

struct ReferralScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel: ReferralViewModel
    
    init(referralCode: String = "") {
        _viewModel = State(
            initialValue: ReferralViewModel(redeemCodeInput: referralCode)
        )
    }
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        referralCodeSection(reader: reader)
                        
                        redeemCodeSection
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarTitle(Localization.string("Referral Program"))
        .task {
            await viewModel.setStartData()
            
            await withTaskGroup { group in
                group.addTask { await viewModel.loadReferralCode() }
                group.addTask { await viewModel.getUser() }
                
                if !viewModel.redeemCodeInput.isEmpty && viewModel.redeemCodeInput.count == 10 {
                    group.addTask { await viewModel.redeemCode() }
                }
            }
        }
        .refreshable {
            await withTaskGroup { group in
                group.addTask { await viewModel.loadReferralCode() }
                group.addTask { await viewModel.getUser() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup { group in
                        group.addTask { await viewModel.loadReferralCode() }
                        group.addTask { await viewModel.getUser() }
                    }
                }
            default:
                break
            }
        }
    }
    
    private func referralCodeSection(reader: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Your referral code"))
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurface)
            
            ShimmeringText(
                text: Localization.format("%d/3 towards earnings 6 months of CoinCurrently Pro. Thereafter 1 month per referral.", viewModel.currentReferrals),
                isDownloading: viewModel.user == nil
            )
            .font(.satoshiMedium(16))
            .foregroundStyle(Color.onSurfaceDim)
            
            ZStack {
                if let referralQRImage = viewModel.referralQRImage {
                    Image(uiImage: referralQRImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: (reader.size.width / 3) * 2, height: (reader.size.width / 3) * 2)
                } else {
                    ShimmeringImage(
                        imageUrl: nil,
                        downloading: viewModel.isLoadingReferralCode,
                        size: (reader.size.width / 3) * 2
                    )
                }
            }
            .frame(width: (reader.size.width / 3) * 2, height: (reader.size.width / 3) * 2)
            .accessibilityLabel(Localization.string("Referral QR code"))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            
            VStack(spacing: 8) {
                ShimmeringText(
                    text: viewModel.referralCode ?? "000000000000",
                    isDownloading: viewModel.referralCode == nil && viewModel.isLoadingReferralCode
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
                .font(.satoshiBold(26))
                
                HStack(spacing: 8) {
                    SecondaryButton(
                        text: Localization.string("Copy link"),
                        isEnabled: viewModel.referralLink != nil,
                        fullWidth: true,
                        action: copyReferralLink
                    )
                    .frame(maxWidth: 400)
                    
                    PrimaryButton(
                        text: Localization.string("Share"),
                        isEnabled: viewModel.referralLink != nil,
                        fullWidth: true
                    ) {
                        shareReferralLink()
                    }
                    .frame(maxWidth: 400)
                }
                .padding(.top, 8)
            }
            .cardBackground()
        }
    }
    
    private var redeemCodeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Redeem a code"))
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurface)
            
            Text(Localization.string("Redeem a code and get 7 days of CoinCurrently Pro for free"))
                .font(.satoshiMedium(16))
                .foregroundStyle(Color.onSurfaceDim)
            
            VStack(spacing: 16) {
                TextInputField(
                    input: $viewModel.redeemCodeInput,
                    placeholder: "Enter referral code",
                    accessibilityValue: viewModel.redeemCodeInput.isEmpty ? Localization.string("Enter referral code") : viewModel.redeemCodeInput,
                    leadingIcon: nil,
                    isSearchField: false,
                    outlineColor: [viewModel.showError ? Color.trendDown : Color.outlineVariant],
                    inputDidChange: {},
                    onCommit: {
                        Task {
                            await viewModel.redeemCode()
                        }
                    }
                )
                
                if viewModel.redeemSucceeded {
                    Text(Localization.string("Referral code redeemed successfully."))
                        .font(.satoshiMedium(14))
                        .foregroundStyle(Color.trendUp)
                } else if let errorMessage = viewModel.redeemErrorMessage {
                    Text(errorMessage)
                        .font(.satoshiMedium(14))
                        .foregroundStyle(Color.trendDown)
                }
                
                PrimaryButton(
                    text: Localization.string("Redeem Code"),
                    isEnabled: !viewModel.redeemCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isRedeemingCode,
                    isLoading: viewModel.isRedeemingCode
                ) {
                    Task {
                        await viewModel.redeemCode()
                    }
                }
            }
            .cardBackground()
            .padding(.top, 12)
        }
    }
    
    private func copyReferralLink() {
        guard let link = viewModel.referralLink else {
            return
        }
        
        UIPasteboard.general.string = link
        navigationViewModel.showSnackbar(
            message: Localization.string("Referral link copied to clipboard."),
            buttonTitle: "",
            snackBarType: .success,
            buttonCallback: {}
        )
    }
    
    private func shareReferralLink() {
        guard let link = viewModel.referralLink else { return }
        
        let text = [
            Localization.string("Join me on CoinCurrently and track crypto in real time!"),
            link
        ].joined(separator: "\n")
        
        let activityViewController = UIActivityViewController(
            activityItems: [ActivityControllerItemSource(title: "CoinCurrently", text: text)],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController,
           let rootView = UIApplication.shared.window?.rootViewController?.view {
            popover.sourceView = rootView
            popover.sourceRect = CGRect.zero
            popover.permittedArrowDirections = []
        }
        
        UIApplication.shared.window?.rootViewController?.present(activityViewController, animated: true)
    }
}
