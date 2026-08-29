//
//  ExploreScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-27.
//

import SwiftUI

@MainActor
struct ExploreScreen: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel: ExploreViewModelImp
    @State private var categoriesViewModel = CategoriesViewModelImp()
    
    init(category: CryptoCategory? = nil) {
        _viewModel = State(initialValue: ExploreViewModelImp(category: category))
    }
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            Group {
                if viewModel.category == nil {
                    categoryPicker
                } else {
                    deckContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(navigationTitle)
                    .font(.satoshiBold(17))
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .task {
            if viewModel.category != nil {
                await viewModel.loadCoins()
            } else {
                await categoriesViewModel.setStartData()
                await categoriesViewModel.getCategories(newSortOption: categoriesViewModel.selectedSortOption)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, viewModel.category != nil else { return }
            Task {
                await viewModel.loadCoins()
            }
        }
    }
    
    private var navigationTitle: String {
        viewModel.category?.name ?? "Explore"
    }
    
    @ViewBuilder
    private var categoryPicker: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Text("Pick a category to explore coins")
                    .font(.satoshiRegular(14))
                    .foregroundStyle(Color.onSurfaceDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(
                        EdgeInsets(
                            top: 8,
                            leading: 16 + safeAreaInsets.leading,
                            bottom: 12,
                            trailing: 16 + safeAreaInsets.trailing
                        )
                    )
                    .accessibilityAddTraits(.isHeader)
                
                Group {
                    if categoriesViewModel.categories.isEmpty {
                        ForEach(0..<12, id: \.self) { index in
                            CategoryItemView(
                                currentCategory: nil,
                                priceMultiplier: categoriesViewModel.multiplier,
                                listIndex: index,
                                listCount: 12,
                                categorySelected: {}
                            )
                        }
                    } else {
                        ForEach(Array(categoriesViewModel.categories.enumerated()), id: \.element.id) { index, category in
                            CategoryItemView(
                                currentCategory: category,
                                priceMultiplier: categoriesViewModel.multiplier,
                                listIndex: index,
                                listCount: categoriesViewModel.categories.count,
                                categorySelected: {
                                    Task {
                                        await viewModel.selectCategory(category)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: 16 + safeAreaInsets.leading,
                        bottom: 16,
                        trailing: 16 + safeAreaInsets.trailing
                    )
                )
            }
        }
        .refreshable {
            await categoriesViewModel.getCategories(newSortOption: categoriesViewModel.selectedSortOption)
            await categoriesViewModel.getBitcoin()
        }
    }
    
    @ViewBuilder
    private var deckContent: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoaded {
                ActivityIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasLoaded && viewModel.coins.isEmpty {
                EmptyContent(
                    title: "No coins found",
                    subTitle: "This category has no coins to explore right now.",
                    buttonTitle: viewModel.startedWithoutCategory ? "Choose another category" : nil,
                    buttonAction: viewModel.startedWithoutCategory ? {
                        viewModel.goBackToCategoryPicker()
                        Task {
                            await categoriesViewModel.setStartData()
                            await categoriesViewModel.getCategories(newSortOption: categoriesViewModel.selectedSortOption)
                        }
                    } : nil
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            } else if viewModel.isExhausted {
                exhaustedState
            } else {
                ExploreSwipeDeckView(viewModel: viewModel)
                    .refreshable {
                        await viewModel.loadCoins()
                    }
            }
        }
    }
    
    private var exhaustedState: some View {
        EmptyContent(
            title: "That's all for \(viewModel.category?.name ?? "this category")",
            subTitle: "You've seen every coin in this category.",
            buttonTitle: "Start over",
            buttonAction: {
                viewModel.restart()
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            if viewModel.startedWithoutCategory {
                SecondaryButton(
                    text: "Change category",
                    accessibilityLabel: "Change category",
                    action: {
                        viewModel.goBackToCategoryPicker()
                        Task {
                            await categoriesViewModel.setStartData()
                            await categoriesViewModel.getCategories(newSortOption: categoriesViewModel.selectedSortOption)
                        }
                    }
                )
                .padding(.bottom, 32)
            }
        }
    }
}
