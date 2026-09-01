//
//  DerivativeDetailScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-26.
//

import SwiftUI

@MainActor
struct DerivativeDetailScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.sizeCategory) private var category
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @Environment(NavigationViewModel.self) private var navigationViewModel
    
    @State var viewModel: DerivativeDetailViewModelImp
    
    @State var selectedItem: DerivativeDetail?
    @State var currentPage: Int? = 0
    @State var isSortShowing = false
    
    @State private var showScrollToTopButton = false
    @State private var currenciesScrollToTop = false
    @State private var previousScrollOffset: CGFloat = 0
    @State private var id = UUID()
    
    @State private var scrollToTop = false
    @State private var tabId = UUID()
    
    @AccessibilityFocusState private var focusBackButton
    
    private var navigationTitle: String {
        viewModel.derativeDetail?.displayName ?? ""
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    init(
        derivative: Derivative
    ) {
        _viewModel = State(
            wrappedValue: DerivativeDetailViewModelImp(
                derivative: derivative
            )
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            ScrollView {
                ScrollViewReader { reader in
                    LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                        tradingVolumeView
                            .padding(.horizontal, 16)
                        
                        summaryView
                            .padding(
                                EdgeInsets(
                                    top: 8,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 16
                                )
                            )
                        
                        Section(header: pageSelector) {
                            SecondaryButton(
                                text: viewModel.selectedSortOption.title,
                                accessibilityLabel: "Sort, currently selected: \(viewModel.selectedSortOption.accessibilityTitle)",
                                icon: .sort,
                                action: {
                                    AnalyticsManager.shared.log(
                                        SheetOpened(fromScreen: .derivativeDetail, sheet: .sortBy)
                                    )
                                    isSortShowing = true
                                }
                            )
                            .padding(
                                EdgeInsets(
                                    top: 8,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 16
                                )
                            )
                            
                            sectionHeader
                            
                            if viewModel.perpetualList.isEmpty && viewModel.futuresList.isEmpty {
                                tempList
                            } else if currentPage == 0 {
                                perpetualsList
                            } else if currentPage == 1 {
                                futuresList
                            }
                        }
                    }
                    .accessibilitySortPriority(-1)
                    .padding(
                        EdgeInsets(
                            top: 16,
                            leading: 0,
                            bottom: 32,
                            trailing: 0
                        )
                    )
                    .id(id)
                    .onChange(of: currenciesScrollToTop) {
                        withAnimation {
                            reader.scrollTo(id, anchor: .top)
                        }
                    }
                    .onChange(of: scrollToTop) {
                        withAnimation {
                            reader.scrollTo(tabId, anchor: .top)
                        }
                    }
                }
            }
            .accessibilitySortPriority(-1)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldOffset, newOffset in
                let isScrollingUp = newOffset < previousScrollOffset
                
                if newOffset > 600 && !isScrollingUp {
                    showScrollToTopButton = true
                } else if newOffset < 400 || isScrollingUp {
                    showScrollToTopButton = false
                }
                
                previousScrollOffset = newOffset
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .bottomTrailing) {
                if !accessibilityVoiceOverEnabled {
                    ScrollUpButton(
                        action: {
                            AnalyticsManager.shared.log(
                                ScrollToTopPressed(
                                    fromScreen: .derivativeDetail,
                                    selectedTabName: currentPage.derivativeDetailPageTabName
                                )
                            )
                            currenciesScrollToTop.toggle()
                        },
                        isVisible: showScrollToTopButton
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if !navigationViewModel.navPath.isEmpty {
                        navigationViewModel.navPath.removeLast()
                    }
                } label: {
                    Image.chevronLeft
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurface)
                }
                .accessibilityLabel("Navigate back")
                .accessibilitySortPriority(2)
                .accessibilityFocused($focusBackButton)
            }
            
            ToolbarItem(placement: .principal) {
                NewShimmeringText(
                    text: navigationTitle.isEmpty ? "000000" : navigationTitle,
                    isDownloading: navigationTitle.isEmpty
                )
                .font(.satoshiBold(17))
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
                .accessibilitySortPriority(1)
            }
        }
        .onUIKitDidAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusBackButton = true
            }
        }
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getDerativeDetail() }
                group.addTask { await viewModel.getToplist() }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.getDerativeDetail() }
                        group.addTask { await viewModel.getToplist() }
                        group.addTask { await viewModel.getBitcoin() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getDerativeDetail() }
                group.addTask { await viewModel.getToplist() }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .onChange(of: currentPage) { _, page in
            AnalyticsManager.shared.log(
                TabChanged(fromScreen: .derivativeDetail, selectedTabName: page.derivativeDetailPageTabName)
            )
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.derivativeDetailOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .derivativeDetail, option: viewModel.selectedSortOption)
                    )
                    Task {
                        await viewModel.setNewSortOption(
                            newSortOption: option
                        )
                    }
                }
            )
        }
        .sheet(item: $selectedItem) { item in
            DerivativeDetailSheet(
                derivativeDetail: item,
                multiplier: viewModel.multiplier,
                imageUrl: viewModel.toplist?.first(where: { $0.symbol?.lowercased() == item.base?.lowercased() })?.image,
                hasToplist: viewModel.toplist != nil,
                exchangeName: viewModel.derativeDetail?.displayName ?? ""
            )
        }
    }
    
    @ViewBuilder
    private var tradingVolumeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("24h Volume")
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDimmer)
                .accessibilityLabel("24 hour volume")
            
            let volume = (Double(viewModel.derativeDetail?.trade_volume_24h_btc ?? "0") ?? 0)
            let bitcoinPrice = viewModel.bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
            let addedVolume = volume * bitcoinPrice
            
            NewShimmeringText(
                text: addedVolume.formatCurrency(
                    threshold: FormattingThreshold.none,
                    maxDecimals: addedVolume < 1_000_000 ? 2 : 0
                ),
                isDownloading: viewModel.derativeDetail == nil || viewModel.bitcoin == nil
            )
            .font(.satoshiBold(36))
            .foregroundStyle(Color.onSurface)
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var summaryView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("24h Open Interest")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityLabel("24 hour open interest")
                
                let interest = viewModel.derativeDetail?.open_interest_btc ?? 0
                let bitcoinPrice = viewModel.bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0
                
                NewShimmeringText(
                    text: (interest * bitcoinPrice).formatCurrency(),
                    isDownloading: viewModel.derativeDetail == nil || viewModel.bitcoin == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            VerticalSeparator(
                width: 2
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Pairs")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDim)
                
                let perpetuals = viewModel.derativeDetail?.number_of_perpetual_pairs ?? 0
                let futures = viewModel.derativeDetail?.number_of_futures_pairs ?? 0
                
                NewShimmeringText(
                    text: "\(perpetuals + futures)",
                    isDownloading: viewModel.derativeDetail == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .cardBackground()
    }
    
    @ViewBuilder
    private var pageSelector: some View {
        let categories = ["Perpetuals", "Futures"]
        
        VStack(spacing: 0) {
            PageSelectorView(currentPage: $currentPage, titles: categories, pageSelected: { page in
                scrollToTop.toggle()
                
                withAnimation {
                    currentPage = page
                }
            })
            
            Separator()
        }
        .background(Color.surface)
        .id(tabId)
    }
    
    @ViewBuilder
    private var sectionHeader: some View {
        HStack(spacing: 24) {
            Text(currentPage == 0 ? "Symbol" : "Contract")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                Text("Price")
                
                Text("Open Interest")
            } else {
                Text("Price / Open Interest")
                .multilineTextAlignment(.trailing)
            }
        }
        .lineLimit(isHorizontal ? 1 : nil)
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
        )
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var tempList: some View {
        let count = isPad ? 30 : 15
        
        ForEach(0..<count, id: \.self) { index in
            DerivativeDetailItem(
                derivativeDetail: nil,
                multiplier: nil,
                isFutures: currentPage != 0,
                index: index,
                listCount: count,
                imageUrl: nil,
                hasToplist: false,
                derivativeSelected: { }
            )
        }
    }
    
    @ViewBuilder
    private var perpetualsList: some View {
        ForEach(Array(viewModel.perpetualList.enumerated()), id: \.element) { index, derivative in
            DerivativeDetailItem(
                derivativeDetail: derivative,
                multiplier: viewModel.multiplier,
                isFutures: false,
                index: index,
                listCount: viewModel.perpetualList.count,
                imageUrl: viewModel.toplist?.first(where: { $0.symbol?.lowercased() == derivative.base?.lowercased() })?.image,
                hasToplist: viewModel.toplist != nil,
                derivativeSelected: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .derivativeDetail, sheet: .derivativeDetailSheet)
                    )
                    selectedItem = derivative
                }
            )
        }
    }
    
    @ViewBuilder
    private var futuresList: some View {
        ForEach(Array(viewModel.futuresList.enumerated()), id: \.element) { index, derivative in
            DerivativeDetailItem(
                derivativeDetail: derivative,
                multiplier: viewModel.multiplier,
                isFutures: true,
                index: index,
                listCount: viewModel.futuresList.count,
                imageUrl: viewModel.toplist?.first(where: { $0.symbol?.lowercased() == derivative.base?.lowercased() })?.image,
                hasToplist: viewModel.toplist != nil,
                derivativeSelected: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .derivativeDetail, sheet: .derivativeDetailSheet)
                    )
                    selectedItem = derivative
                }
            )
        }
    }
}
