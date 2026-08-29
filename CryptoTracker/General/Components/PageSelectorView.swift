//
//  PageSelectorView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-21.
//

import SwiftUI

struct PageSelectorView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @Binding var currentPage: Int?
    let titles: [String]
    var lockedButtons: [Int] = []
    let pageSelected: (Int) -> Void
    
    @Namespace private var namespace
    @State private var voiceOverPageIndex = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollReader in
                HStack(spacing: 24) {
                    ForEach(titles, id: \.self) { title in
                        let index = titles.firstIndex(of: title) ?? -1
                        
                        Button(action: {
                            asyncMain {
                                pageSelected(index)
                            }
                            
                            let title = titles[safely: index]
                            
                            guard !lockedButtons.contains(index) else { return }
                            
                            withAnimation {
                                scrollReader.scrollTo(title, anchor: .center)
                            }
                        }) {
                            Text(title)
                                .padding(.vertical, 16)
                                .background(Color.black.opacity(0.001))
                                .foregroundStyle(currentPage == index ? Color.onSurface : Color.onSurfaceDimmer)
                                .fixedSize(horizontal: false, vertical: true)
                                .background(alignment: .bottom) {
                                    if currentPage == index {
                                        Color.primary
                                            .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2)
                                            .matchedGeometryEffect(id: "position", in: namespace)
                                    }
                                }
                                .animation(.default, value: currentPage)
                        }
                        .id(title)
                        .accessibilityHidden(accessibilityVoiceOverEnabled)
                        .accessibilityLabel("Page \(index + 1) of \(titles.count), \(title).")
                        .accessibilityAddTraits(currentPage == index ? [.isSelected] : [])
                    }
                }
                .onAppear {
                    syncVoiceOverPageIndex()
                    scrollToPageIndex(voiceOverPageIndex, using: scrollReader)
                }
                .onChange(of: currentPage) { wasIndex, newIndex in
                    syncVoiceOverPageIndex()
                    
                    guard let newIndex, let wasIndex, wasIndex != newIndex else { return }
                    
                    scrollToPageIndex(newIndex, using: scrollReader)
                }
                .onChange(of: voiceOverPageIndex) { _, newIndex in
                    scrollToPageIndex(newIndex, using: scrollReader)
                }
            }
            .font(.satoshiBold(16))
            .foregroundColor(.onSurface)
            .padding(.horizontal, 16)
        }
        .if(accessibilityVoiceOverEnabled) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page selector. Swipe up or down to change page.")
                .accessibilityValue(selectedAccessibilityValue)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        selectAdjacentPage(offset: 1)
                    case .decrement:
                        selectAdjacentPage(offset: -1)
                    @unknown default:
                        break
                    }
                }
        }
    }
    
    private var selectedAccessibilityValue: String {
        let title = titles[safely: voiceOverPageIndex] ?? ""
        return "Page \(voiceOverPageIndex + 1) of \(titles.count), \(title)."
    }
    
    private func syncVoiceOverPageIndex() {
        voiceOverPageIndex = currentPage ?? 0
    }
    
    private func selectAdjacentPage(offset: Int) {
        let newIndex = voiceOverPageIndex + offset
        guard titles.indices.contains(newIndex) else { return }
        guard newIndex != currentPage else { return }
        
        voiceOverPageIndex = newIndex
        
        asyncMain {
            pageSelected(newIndex)
        }
    }
    
    private func scrollToPageIndex(_ index: Int, using scrollReader: ScrollViewProxy) {
        guard let title = titles[safely: index] else { return }
        
        withAnimation {
            scrollReader.scrollTo(title, anchor: .center)
        }
    }
}
