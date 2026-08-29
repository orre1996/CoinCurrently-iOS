//
//  DerivativesListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-25.
//

import SwiftUI

struct DerivativesListView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let currentPage: Int?
    let derivativeSelected: (Derivative) -> Void
    
    @State private var viewModel = DerivativesViewModelImp()
    
    @State private var showScrollToTopButton = false
    @State private var derivativesScrollToTop = false
    @State private var isSortShowing = false
    @State private var isPriceChangeShowing = false
    @State private var id = UUID()
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                LazyVStack(alignment: .leading, spacing: 0) {
                    filterButtons
                    
                    DerivativesHeaderView()
                        .padding(
                            EdgeInsets(
                                top: 8,
                                leading: 0,
                                bottom: 6,
                                trailing: 0
                            )
                        )
                    
                    Group {
                        if viewModel.derivatives.isEmpty {
                            tempList
                        } else {
                            realList
                        }
                    }
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 16 + safeAreaInsets.leading,
                            bottom: 0,
                            trailing: 16 + safeAreaInsets.trailing
                        )
                    )
                }
                .padding(.bottom, 16)
                .id(id)
                .onChange(of: derivativesScrollToTop) {
                    withAnimation {
                        reader.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
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
        .overlay(alignment: .bottomTrailing) {
            if !accessibilityVoiceOverEnabled {
                ScrollUpButton(
                    action: {
                        AnalyticsManager.shared.log(
                            ScrollToTopPressed(fromScreen: .derivatives)
                        )
                        derivativesScrollToTop.toggle()
                    },
                    isVisible: showScrollToTopButton
                )
            }
        }
        .animation(.none, value: currentPage)
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getDerivatives(
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await viewModel.getDerivatives(
                                newSortOption: viewModel.selectedSortOption
                            )
                        }
                        group.addTask { await viewModel.getBitcoin() }
                    }
                }
            default:
                break
            }
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getDerivatives(
                        newSortOption: viewModel.selectedSortOption
                    )
                }
                group.addTask { await viewModel.getBitcoin() }
            }
        }
        .sheet(isPresented: $isSortShowing) {
            ToplistSortBySheet(
                options: SortOption.derivativesOptions,
                selectedSortOption: viewModel.selectedSortOption,
                newOptionSelected: { option in
                    AnalyticsManager.shared.log(
                        SortOptionSelected(fromScreen: .derivatives, option: option)
                    )

                    Task {
                        await viewModel.getDerivatives(
                            newSortOption: option
                        )
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 2, currentPage == 4 {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .derivatives)
                )

                derivativesScrollToTop.toggle()
            }
        }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SecondaryButton(
                    text: viewModel.selectedSortOption.title,
                    accessibilityLabel: "Sort, currently selected: \(viewModel.selectedSortOption.accessibilityTitle)",
                    icon: .sort,
                    action: {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .derivatives, sheet: .sortBy)
                        )
                        isSortShowing = true
                    }
                )
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: 32,
                    leading: 16 + safeAreaInsets.leading,
                    bottom: 0,
                    trailing: 16 + safeAreaInsets.trailing
                )
            )
        }
    }
    
    @ViewBuilder
    private var tempList: some View {
        ForEach(0..<(isPad ? 30 : 15), id: \.self) { _ in
            DerivativeItem(
                currentDerivative: nil,
                bitcoin: viewModel.bitcoin,
                derivativeSelected: { }
            )
        }
    }
    
    @ViewBuilder
    private var realList: some View {
        ForEach(viewModel.derivatives, id: \.self) { derivative in
            let index = viewModel.derivatives.firstIndex(of: derivative) ?? -1
            
            DerivativeItem(
                currentDerivative: derivative,
                bitcoin: viewModel.bitcoin,
                listIndex: index,
                listCount: viewModel.derivatives.count,
                derivativeSelected: {
                    derivativeSelected(derivative)
                }
            )
        }
    }
}
