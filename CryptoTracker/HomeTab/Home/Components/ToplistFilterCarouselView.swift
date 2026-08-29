//
//  ToplistFilterCarouselView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct ToplistFilterCarouselView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    let filters: [CarouselFilter]
    let selectedFilter: CarouselFilter
    var hasPro: Bool = true
    let newFilterSelected: (CarouselFilter) -> Void
    
    @State private var voiceOverFilterIndex = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollReader in
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        let index = filters.firstIndex(of: filter) ?? 0
                        let isSelected = filter.matchesForSelection(selectedFilter)
                        let title = isSelected ? selectedFilter.rawValue : filter.rawValue
                        
                        carouselChip(
                            title: title,
                            isSelected: isSelected,
                            filterPressed: {
                                newFilterSelected(filter)
                            }
                        )
                        .id(index)
                        .accessibilityHidden(accessibilityVoiceOverEnabled)
                        .accessibilityLabel("Category \(index + 1) of \(filters.count), \(accessibilityTitle(for: title)).")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                .optionalGlassEffectContainer(spacing: 8)
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 16 + safeAreaInsets.leading,
                        bottom: 16,
                        trailing: 16 + safeAreaInsets.trailing
                    )
                )
                .onAppear {
                    syncVoiceOverFilterIndex()
                    scrollToFilterIndex(voiceOverFilterIndex, using: scrollReader)
                }
                .onChange(of: selectedFilter) {
                    syncVoiceOverFilterIndex()
                    scrollToFilterIndex(
                        filters.firstIndex { $0.matchesForSelection(selectedFilter) } ?? 0,
                        using: scrollReader
                    )
                }
                .onChange(of: voiceOverFilterIndex) { _, newIndex in
                    scrollToFilterIndex(newIndex, using: scrollReader)
                }
            }
        }
        .background(Color.surface)
        .if(accessibilityVoiceOverEnabled) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Category filter. Swipe up or down to change category.")
                .accessibilityValue(selectedAccessibilityValue)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        selectAdjacentFilter(offset: 1)
                    case .decrement:
                        selectAdjacentFilter(offset: -1)
                    @unknown default:
                        break
                    }
                }
                .if(!hasPro) { view in
                    view.accessibilityAction(.default) {
                        activateVoiceOverFilter()
                    }
                }
        }
    }
    
    private func requiresVoiceOverActivation(for filter: CarouselFilter) -> Bool {
        filter.requiresPro && !hasPro
    }
    
    private var selectedAccessibilityValue: String {
        let filter = filters[safely: voiceOverFilterIndex] ?? selectedFilter
        let title = filter.matchesForSelection(selectedFilter) ? selectedFilter.rawValue : filter.rawValue
        let category = "Category \(voiceOverFilterIndex + 1) of \(filters.count), \(accessibilityTitle(for: title))."
        
        if requiresVoiceOverActivation(for: filter) {
            return "\(category) Double tap to select this Pro feature."
        }
        
        return category
    }
    
    private func syncVoiceOverFilterIndex() {
        voiceOverFilterIndex = filters.firstIndex { $0.matchesForSelection(selectedFilter) } ?? 0
    }
    
    private func selectAdjacentFilter(offset: Int) {
        let newIndex = voiceOverFilterIndex + offset
        guard filters.indices.contains(newIndex) else { return }
        
        voiceOverFilterIndex = newIndex
        
        let filter = filters[newIndex]
        guard !requiresVoiceOverActivation(for: filter) else { return }
        
        newFilterSelected(filter)
    }
    
    private func activateVoiceOverFilter() {
        guard let filter = filters[safely: voiceOverFilterIndex] else { return }
        guard requiresVoiceOverActivation(for: filter) else { return }
        
        newFilterSelected(filter)
    }
    
    private func scrollToFilterIndex(_ index: Int, using scrollReader: ScrollViewProxy) {
        withAnimation {
            scrollReader.scrollTo(index, anchor: .center)
        }
    }
    
    private func accessibilityTitle(for title: String) -> String {
        if title.contains("(Pro)") {
            return title.replacingOccurrences(of: " (Pro)", with: ", Pro feature")
        }
        return title
    }
    
    private func carouselChip(
        title: String,
        isSelected: Bool,
        filterPressed: @escaping () -> Void
    ) -> some View {
        Button(action: {
            filterPressed()
        }, label: {
            Text(title)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceContainer)
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .optionalGlassEffect(
                    color: isSelected ? Color.primary : Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                .font(.satoshiMedium(16))
        })
        .animation(.default, value: isSelected)
        .animation(.default, value: title)
    }
}
