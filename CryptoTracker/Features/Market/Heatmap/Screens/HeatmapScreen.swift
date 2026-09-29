//
//  HeatmapScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-18.
//

import SwiftUI

enum HeatmapWeighting: String, CaseIterable {
    case marketCap = "Market Cap"
    case equal = "Equal Grid"
    
    var accessibilityTitle: String {
        switch self {
        case .marketCap:
            "Market cap weight"
        case .equal:
            "Equal grid"
        }
    }
}

enum HeatmapDataSource: String, CaseIterable {
    case favorites = "Favorites"
    case portfolio = "Portfolio"
    case toplist = "Toplist"
    
    var icon: Image {
        switch self {
        case .favorites:
            .starFill
        case .portfolio:
            .portfolio
        case .toplist:
            .list
        }
    }
    
    var accessibilityTitle: String {
        switch self {
        case .favorites:
            "Favorites"
        case .portfolio:
            "Portfolio"
        case .toplist:
            "Toplist"
        }
    }
    
    var emptyTitle: String {
        switch self {
        case .favorites:
            "No favorites yet"
        case .portfolio:
            "Portfolio is empty"
        case .toplist:
            "Toplist is empty"
        }
    }
    
    var emptySubtitle: String {
        switch self {
        case .favorites:
            "Add coins to your favorites to see them here."
        case .portfolio:
            "Add coins to your portfolio to see them here."
        case .toplist:
            "Pull to refresh and try again."
        }
    }
}

@MainActor
struct HeatmapScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel: HeatmapViewModelImp
    @State private var selectedTimeframe: PriceChange = .oneDay
    @State private var weighting: HeatmapWeighting = .marketCap
    @State private var selectedDataSource: HeatmapDataSource = .favorites
    @State private var hasLoaded = false
    @State private var showHeatmapGrid = false
    @State private var userHasCycledDataSource = false
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
    @State private var appLanguage = AppLanguagePreference.stored
    
    private let heatmapTimeframeCycle: [PriceChange] = [.sevenDays, .oneMonth, .oneDay]
    private let heatmapDataSourceCycle: [HeatmapDataSource] = [.favorites, .portfolio, .toplist]
    
    private let category: CryptoCategory?
    
    init(category: CryptoCategory? = nil) {
        self.category = category
        _viewModel = State(initialValue: HeatmapViewModelImp(category: category))
    }
    
    var body: some View {
        let _ = Self._printChanges()
        
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            heatmap
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: cycleWeighting) {
                    Text(Localization.string(weighting.rawValue))
                        .font(.satoshiBold(17))
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .optionalGlassEffect(
                            color: Color.surfaceContainerHigh,
                            radius: 1000,
                            isInteractive: true
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.format("Sizing, currently selected: %@", Localization.string(weighting.accessibilityTitle)))
                .accessibilityHint(Localization.string("Double tap to switch sizing"))
                .accessibilityAddTraits(.isHeader)
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .task {
            let isFirstLoad = !hasLoaded
            if isFirstLoad {
                showHeatmapGrid = false
            }
            
            await viewModel.loadHeatmapData()
            
            if isFirstLoad {
                selectedDataSource = preferredDataSource()
                hasLoaded = true
            }
            
            updateShowHeatmapGrid()
        }
        .onChange(of: selectedDataSource) { _, _ in
            updateShowHeatmapGrid()
        }
        .onChange(of: hasLoaded) { _, _ in
            updateShowHeatmapGrid()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await viewModel.loadHeatmapData()
                updateShowHeatmapGrid()
            }
        }
        .refreshable {
            await viewModel.loadHeatmapData()
            updateShowHeatmapGrid()
        }
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorBlindnessFilterChanged)) { _ in
            colorBlindnessFilterEnabled = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false
        }
    }
    
    private var heatmapCoins: [Toplist] {
        let sourceCoins: [Toplist]
        
        switch selectedDataSource {
        case .favorites:
            sourceCoins = viewModel.favoritesList
        case .portfolio:
            sourceCoins = viewModel.portfolioList
        case .toplist:
            sourceCoins = viewModel.toplist
        }
        
        return Array(
            sourceCoins
                .filter { $0.id != nil }
                .sorted { ($0.market_cap ?? 0) > ($1.market_cap ?? 0) }
                // 249 divides evenly by the phone equal-grid column count (3).
                .prefix(249)
        )
    }
    
    private func preferredDataSource() -> HeatmapDataSource {
        if !viewModel.favoritesList.isEmpty {
            return .favorites
        }
        
        if !viewModel.portfolioList.isEmpty {
            return .portfolio
        }
        
        return .toplist
    }
    
    private func updateShowHeatmapGrid() {
        showHeatmapGrid = hasLoaded && !heatmapCoins.isEmpty
    }
    
    private var heatmapOverlayButtons: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: Localization.string(selectedDataSource.rawValue),
                accessibilityLabel: Localization.format("Data source, currently selected: %@", Localization.string(selectedDataSource.accessibilityTitle)),
                icon: selectedDataSource.icon,
                action: cycleDataSource
            )
            
            SecondaryButton(
                text: Localization.string(selectedTimeframe.rawValue),
                accessibilityLabel: Localization.format("Timeframe, currently selected: %@", Localization.string(selectedTimeframe.accessibilityTimeframe)),
                icon: .percent,
                action: cycleTimeframe
            )
        }
        .optionalGlassEffectContainer(spacing: 8)
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16,
                bottom: 32,
                trailing: 16
            )
        )
        .ignoresSafeArea()
    }
    
    private func cycleWeighting() {
        guard let currentIndex = HeatmapWeighting.allCases.firstIndex(of: weighting) else {
            weighting = HeatmapWeighting.allCases[0]
            return
        }
        
        let nextIndex = (currentIndex + 1) % HeatmapWeighting.allCases.count
        weighting = HeatmapWeighting.allCases[nextIndex]
    }
    
    private func cycleDataSource() {
        userHasCycledDataSource = true
        
        guard let currentIndex = heatmapDataSourceCycle.firstIndex(of: selectedDataSource) else {
            selectedDataSource = heatmapDataSourceCycle[0]
            updateShowHeatmapGrid()
            return
        }
        
        let nextIndex = (currentIndex + 1) % heatmapDataSourceCycle.count
        selectedDataSource = heatmapDataSourceCycle[nextIndex]
        updateShowHeatmapGrid()
    }
    
    private func cycleTimeframe() {
        guard let currentIndex = heatmapTimeframeCycle.firstIndex(of: selectedTimeframe) else {
            selectedTimeframe = heatmapTimeframeCycle[0]
            return
        }
        
        let nextIndex = (currentIndex + 1) % heatmapTimeframeCycle.count
        let nextTimeframe = heatmapTimeframeCycle[nextIndex]
        
        AnalyticsManager.shared.log(
            PriceChangeOptionSelected(fromScreen: .heatmap, option: nextTimeframe)
        )
        
        selectedTimeframe = nextTimeframe
    }
    
    @ViewBuilder
    private var heatmap: some View {
        Group {
            if !hasLoaded {
                ActivityIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if heatmapCoins.isEmpty {
                EmptyContent(
                    title: emptyStateTitle,
                    subTitle: emptyStateSubtitle
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if showHeatmapGrid {
                HeatmapGridView(
                    coins: heatmapCoins,
                    selectedTimeframe: selectedTimeframe,
                    weighting: weighting,
                    coinSelected: { coin in
                        AnalyticsManager.shared.log(
                            Navigate(
                                fromScreen: .heatmap,
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
                .id("\(selectedDataSource.rawValue)-\(weighting.rawValue)-\(colorBlindnessFilterEnabled)")
            } else {
                ActivityIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(edges: weighting == .marketCap ? .all : [.horizontal, .top])
        .overlay(alignment: .bottomTrailing) {
            if hasLoaded {
                heatmapOverlayButtons
            }
        }
    }
    
    private var emptyStateTitle: String {
        if selectedDataSource == .toplist,
           !userHasCycledDataSource,
           viewModel.toplist.isEmpty {
            return Localization.string("Couldn't load heatmap")
        }
        
        return Localization.string(selectedDataSource.emptyTitle)
    }
    
    private var emptyStateSubtitle: String {
        if selectedDataSource == .toplist,
           !userHasCycledDataSource,
           viewModel.toplist.isEmpty {
            return Localization.string("Pull to refresh and try again.")
        }
        
        return Localization.string(selectedDataSource.emptySubtitle)
    }
}
