//
//  WalletDetailsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 12/17/25.
//

import SwiftUI

struct WalletDetailsScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    @State private var viewModel: WalletDetailsViewModelImp
    @State private var showRenameSheet = false
    @State private var showDeletePopup = false
    @State private var showWalletInfo = false
    
    init(
        wallet: AddressImport,
        coin: Toplist
    ) {
        _viewModel = State(wrappedValue: WalletDetailsViewModelImp(
            wallet: wallet,
            coin: coin
        ))
    }
    
    let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel.´default´
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.surface
                .ignoresSafeArea()
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    walletTotals
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 12,
                                trailing: 16
                            )
                        )
                    
                    changeView
                        .padding(.horizontal, 16)
                    
                    Separator()
                        .padding(.vertical, 32)
                    
                    coinsList
                        .padding(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 32,
                                trailing: 16
                            )
                        )
                }
                .padding(.top, 16)
            }
            .ignoresSafeArea(edges: .bottom)
            
            if showDeletePopup {
                DeleteWalletPopup(
                    walletName: viewModel.wallet.walletName ?? "",
                    close: {
                        showDeletePopup = false
                        
                        if $0 {
                            AnalyticsManager.shared.log(
                                WalletDeleted(fromScreen: .walletDetails)
                            )
                            Task {
                                await viewModel.deleteWallet()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                )
            }
        }
        .navigationBarTitle(viewModel.wallet.walletName ?? "", displayMode: .inline)
        .toolbar {
            toolbarMenuButton
        }
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getAllPortfolioCurrencies() }
                group.addTask { await viewModel.getCoins() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getAllPortfolioCurrencies() }
                        group.addTask { await viewModel.getCoins() }
                    }
                }
            default:
                break
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameWalletSheet(
                initialName: viewModel.wallet.walletName ?? "",
                renameWallet: { newName in
                    AnalyticsManager.shared.log(
                        WalletRenamed(fromScreen: .walletDetails)
                    )
                    Task {
                        await viewModel.renameWallet(newName: newName)
                    }
                }
            )
        }
        .sheet(isPresented: $showWalletInfo) {
            WalletInfoSheet(
                wallet: viewModel.wallet,
                coin: viewModel.coin,
                syncedDate: viewModel.syncedDate,
            )
        }
    }
    
    private var toolbarMenuButton: some View {
        Menu {
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .walletDetails, sheet: .renameWallet)
                )
               showRenameSheet = true
            }, label: {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image.edit
                        Text("Rename Wallet")
                    }
                }
                .foregroundStyle(Color.onSurface)
            })
            
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .walletDetails, sheet: .deleteWallet)
                )
                showDeletePopup = true
            }, label: {
                HStack(spacing: 8) {
                    Image.delete
                    Text("Remove Wallet")
                }
            })
        } label: {
            Button(action: {
                
            }, label: {
                Image.more
                    .resizable()
                    .frame(width: 24 * min(scale, 1.25), height: 24 * min(scale, 1.25), alignment: .center)
                    .foregroundStyle(Color.onSurface)
            })
        }
        .accessibilityLabel("More options")
    }
    
    private var walletTotals: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wallet Value")
                    .font(.satoshiBold(18))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityHidden(true)
                
                HStack(spacing: 4) {
                    let totalValue = viewModel.totalValue?.formatCurrency(
                        threshold: FormattingThreshold.million
                    ) ?? ""
                    
                    Text(viewModel.hideData ? String.stars : totalValue)
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(36))
                    .accessibilityLabel("Wallet value: \(viewModel.hideData ? String.stars : totalValue)")
                    
                    (viewModel.hideData ? Image.unhide : Image.hide)
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .padding(12)
                        .onTapGesture {
                            viewModel.toggleHideData()
                            if viewModel.hideData {
                                AnalyticsManager.shared.log(PortfolioDataHide(fromScreen: .walletDetails))
                            } else {
                                AnalyticsManager.shared.log(PortfolioDataShow(fromScreen: .walletDetails))
                            }
                        }
                        .accessibilityLabel("\(viewModel.hideData ? "show" : "hide") wallet data")
                }
            }
            
            Spacer(minLength: 0)
            
            Button(action: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .walletDetails, sheet: .walletInfo)
                )
                showWalletInfo = true
            }, label: {
                Image.info
                    .resizable()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(8)
            })
            .accessibilityLabel("Wallet details")
        }
    }
    
    private var changeView: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            valueChangeView
            
            lastSyncedView
        }
    }
    
    @ViewBuilder
    private var valueChangeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Value Change (7d)")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            if viewModel.hideData {
                Text(String.stars)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDim)
            } else {
                OverflowLayout(spacing: 4) {
                    PriceChangeValueView(
                        change: viewModel.changeValue,
                        size: .small,
                        accessibleTimeframe: "7 days",
                        isDownloading: viewModel.changePercent == nil
                    )
                    
                    let formattedChange = (viewModel.changePercent ?? 0).formatted(
                        isHorizontal
                        ? .number.notation(.compactName).precision(.fractionLength(2))
                        : .number.precision(.fractionLength(2))
                    ).changeWithSymbol
                    
                    ShimmeringText(
                        text: "(\(formattedChange)%)",
                        isDownloading: viewModel.changePercent == nil
                    )
                    .foregroundStyle(viewModel.changePercent?.changeColor ?? Color.onSurfaceDim)
                    .font(.satoshiBold(14))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(valueChangeAccessibilityLabel)
    }
    
    @ViewBuilder
    private var lastSyncedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Synced")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(true)
            
            Text((viewModel.syncedDate ?? Date()).formatted(date: .abbreviated, time: .shortened))
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lastSyncedAccessibilityLabel)
    }
    
    private var valueChangeAccessibilityLabel: String {
        walletChangeAccessibilityLabel(
            title: "7 days value change",
            value: viewModel.changeValue,
            percent: viewModel.changePercent
        )
    }
    
    private var lastSyncedAccessibilityLabel: String {
        let synced = viewModel.syncedDate ?? Date()
        let accessibleDate = synced.formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute())
        return "Last Synced: \(accessibleDate)"
    }
    
    private func walletChangeAccessibilityLabel(
        title: String,
        value: Double?,
        percent: Double?
    ) -> String {
        let safeChange = (percent ?? 0).isInfinite ? 0 : (percent ?? 0)
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        let percentText = "\(direction) \(accessiblePercent) percent"
        
        if viewModel.hideData {
            return "\(title), \(percentText)"
        }
        
        let changeValue = value ?? 0
        let valueDirection = changeValue.directionAccessible.lowercased()
        let valueText = abs(changeValue).formatAccessibleCurrency()
        return "\(title), \(valueDirection) \(valueText), \(percentText)"
    }

    private var walletInfoView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Network")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDim)
                
                Text("\(viewModel.coin.symbol?.uppercased() ?? "") Mainnet")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 16)
            
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallet Address")
                        .font(.satoshiBold(12))
                        .foregroundStyle(Color.onSurfaceDim)
                    
                    Text("\(viewModel.wallet.address.uppercased().prefix(5))...\(viewModel.wallet.address.uppercased().suffix(5))")
                        .font(.satoshiBold(16))
                        .foregroundStyle(Color.onSurface)
                }
                
                Button(action: {
                    UIPasteboard.general.string = viewModel.wallet.address
                    showSnackBar(message: "Address copied to clipboard.", type: .success)
                }, label: {
                    (Image.copy)
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .padding(12)
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var coinsList: some View {
        let hasMainCoin = Double(viewModel.wallet.balance) != nil
        let tokens = viewModel.sortedTokens
        let totalCount = (hasMainCoin ? 1 : 0) + tokens.count
        
        LazyVStack(spacing: 16) {
            WalletHeaderView()

            if hasMainCoin {
                WalletCoinView(
                    toplist: viewModel.coin,
                    token: viewModel.wallet.toTokenInfo,
                    hideData: viewModel.hideData,
                    isDownloading: !viewModel.isDoneSorting,
                    index: 0,
                    totalCount: totalCount,
                    navigateToCoin: {
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .walletDetails,
                                toScreen: .cryptoDetail,
                                coinName: viewModel.coin.name ?? ""
                            )
                        )
                        navigationViewModel.navPath.append(
                            NavigationScreens.CryptoDetail(
                                currencyDataModel: viewModel.coin.toCryptoDetail
                            )
                        )
                    }
                )
            }
            
            ForEach(Array(tokens.enumerated()), id: \.element) { offset, token in
                let coin = viewModel.coins?.first(where: { $0.id == token.tokenId })
                let index = (hasMainCoin ? 1 : 0) + offset
                
                WalletCoinView(
                    toplist: coin,
                    token: token,
                    hideData: viewModel.hideData,
                    isDownloading: !viewModel.isDoneSorting || coin == nil,
                    index: index,
                    totalCount: totalCount,
                    navigateToCoin: {
                        guard let coin else {
                            return
                        }

                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .walletDetails,
                                toScreen: .cryptoDetail,
                                coinName: coin.name ?? ""
                            )
                        )

                        navigationViewModel.navPath.append(
                            NavigationScreens.CryptoDetail(
                                currencyDataModel: coin.toCryptoDetail
                            )
                        )
                    }
                )
            }
        }
    }
}
