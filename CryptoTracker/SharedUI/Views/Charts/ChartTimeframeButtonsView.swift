//
//  ChartTimeframeButtonsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/7/25.
//

import SwiftUI
import UIKit

struct ChartTimeframeButtonsView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

    let fromScreen: ScreenLabel
    let chartButtons: [ChartButton]
    let selectedNumber: Int
    let reader: GeometryProxy
    let action: (ChartButton) async -> Void
    
    private var isVoiceOverActive: Bool {
        accessibilityVoiceOverEnabled || isVoiceOverRunning
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollReader in
                HStack(alignment: .center, spacing: 4) {
                    ForEach(chartButtons, id: \.self) { currentTimeframe in
                        let isSelected = selectedNumber == currentTimeframe.timeChart.rawValue
                        
                        Button(action: {
                            selectTimeframe(currentTimeframe, scrollReader: scrollReader)
                        }) {
                            Text(currentTimeframe.time)
                                .lineLimit(1)
                                .padding(
                                    EdgeInsets(
                                        top: 12,
                                        leading: 16,
                                        bottom: 12,
                                        trailing: 16
                                    )
                                )
                                .if(isSelected) { view in
                                    view.optionalGlassEffect(
                                        color: Color.surfaceContainerHigh,
                                        radius: 1000,
                                        isInteractive: true
                                    )
                                }
                                .id(currentTimeframe)
                        }
                        .accessibilityHidden(isVoiceOverActive)
                        .accessibilityLabel("Switch to \(currentTimeframe.accessibilityText).")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                        
                        if currentTimeframe != chartButtons.last {
                            Spacer(minLength: 4)
                        }
                    }
                }
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 16 + safeAreaInsets.leading,
                        bottom: 16,
                        trailing: 16 + safeAreaInsets.trailing
                    )
                )
                .onAppear {
                    scrollToSelected(using: scrollReader)
                }
                .onChange(of: selectedNumber) {
                    scrollToSelected(using: scrollReader)
                }
            }
            .frame(minWidth: reader.size.width, maxWidth: .infinity)
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
        }
        .if(isVoiceOverActive) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Chart timeframe")
                .accessibilityValue(selectedAccessibilityValue)
                .accessibilityHint("Swipe up or down to change timeframe.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        selectAdjacentTimeframe(offset: 1)
                    case .decrement:
                        selectAdjacentTimeframe(offset: -1)
                    @unknown default:
                        break
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
    }
    
    private var selectedAccessibilityValue: String {
        guard let selectedButton,
              let index = chartButtons.firstIndex(of: selectedButton) else {
            return ""
        }
        
        return "Timeframe \(index + 1) of \(chartButtons.count), \(selectedButton.accessibilityText)."
    }
    
    private var selectedButton: ChartButton? {
        chartButtons.first { $0.timeChart.rawValue == selectedNumber }
    }
    
    private func selectAdjacentTimeframe(offset: Int) {
        guard let currentIndex = chartButtons.firstIndex(where: { $0.timeChart.rawValue == selectedNumber }) else {
            return
        }
        
        let newIndex = currentIndex + offset
        guard chartButtons.indices.contains(newIndex) else { return }
        
        selectTimeframe(chartButtons[newIndex])
    }
    
    private func selectTimeframe(_ timeframe: ChartButton, scrollReader: ScrollViewProxy? = nil) {
        guard selectedNumber != timeframe.timeChart.rawValue else { return }
        
        SettingsManager.shared.set(data: timeframe.timeChart, key: AppSettingKey.timeframe)
        AnalyticsManager.shared.log(
            TimeframeChanged(fromScreen: fromScreen, days: timeframe.days)
        )
        
        Task {
            await action(timeframe)
        }
        
        if let scrollReader {
            withAnimation {
                scrollReader.scrollTo(timeframe, anchor: .center)
            }
        }
    }
    
    private func scrollToSelected(using scrollReader: ScrollViewProxy) {
        guard let selectedButton else { return }
        
        withAnimation {
            scrollReader.scrollTo(selectedButton, anchor: .center)
        }
    }
}
